#!/usr/bin/env bash
# Black-box tests for b24-landing.sh. Bitrix24 REST is a stub `b24` in PATH; no network.
set -uo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
SCRIPT="$ROOT/b24-landing.sh"
TMP=$(mktemp -d /tmp/b24-landing-test.XXXXXX)
trap 'rm -rf "$TMP"' EXIT
PASS=0
FAIL=0

ok() { PASS=$((PASS + 1)); printf 'PASS %s\n' "$1"; }
bad() { FAIL=$((FAIL + 1)); printf 'FAIL %s\n' "$1"; }

# Page content with quotes, a newline and Cyrillic: byte-exact copies must survive jq.
CONTENT_D1=$'<div id="b11" class="block-wrapper block-26-2-separator"><form action="https://forms.arwox.ru/">Тарифы\n"q"</form></div>'
CONTENT_P1=$'<div id="b12" class="block-wrapper block-26-2-separator"><form action="https://forms.arwox.ru/">Тарифы\n"q"</form></div>'
CONTENT_D2='<div id="b21" class="block-wrapper">page2 draft</div>'
CONTENT_P2='<div id="b22" class="block-wrapper">page2 public</div>'
CSS1=$'.a{color:red}\n/* Ж */'
CSS2='.b{margin:0}'

setup() {
  rm -rf "$TMP/run" "$TMP/stub"
  mkdir -p "$TMP/run/bin" "$TMP/stub"
  jq -n '[{ID:"1",CODE:"index"},{ID:"2",CODE:"other"}]' > "$TMP/stub/pages.json"
  jq -n --arg c "$CONTENT_D1" '[{id:11,lid:1,code:"26.2.separator",meta:{DATE_MODIFY:"x"},content:$c}]' > "$TMP/stub/blocks-1-1.json"
  jq -n --arg c "$CONTENT_P1" '[{id:12,lid:1,code:"26.2.separator",content:$c}]' > "$TMP/stub/blocks-1-0.json"
  jq -n --arg c "$CONTENT_D2" '[{id:21,lid:2,content:$c}]' > "$TMP/stub/blocks-2-1.json"
  jq -n --arg c "$CONTENT_P2" '[{id:22,lid:2,content:$c}]' > "$TMP/stub/blocks-2-0.json"
  jq -n --arg c "$CSS1" '{CSSBLOCK_USE:"Y",CSSBLOCK_CODE:$c,METAROBOTS_INDEX:"N"}' > "$TMP/stub/af-1.json"
  jq -n --arg c "$CSS2" '{CSSBLOCK_USE:"Y",CSSBLOCK_CODE:$c}' > "$TMP/stub/af-2.json"
  cat > "$TMP/run/bin/b24" <<'EOF'
#!/usr/bin/env bash
method=$1; shift
lid=''; mode=''
for a in "$@"; do
  case "$a" in
    lid=*) lid=${a#lid=} ;;
    'params[edit_mode]='*) mode=${a#*=} ;;
  esac
done
printf '%s %s\n' "$method" "$*" >> "$STUB/calls"
[ -e "$STUB/fail-$method-$lid" ] && { printf 'API error\n' >&2; exit 1; }
case "$method" in
  landing.landing.getList) cat "$STUB/pages.json" ;;
  landing.block.getlist) cat "$STUB/blocks-$lid-$mode.json" ;;
  landing.landing.getadditionalfields) cat "$STUB/af-$lid.json" ;;
  *) printf 'unexpected method %s\n' "$method" >&2; exit 1 ;;
esac
EOF
  chmod +x "$TMP/run/bin/b24"
}

run() { PATH="$TMP/run/bin:$PATH" STUB="$TMP/stub" bash "$SCRIPT" "$@"; }

same() { cmp -s "$1" <(printf '%s' "$2"); }

# 1. snapshot: 4 files per page, byte-exact with the stub's answer
setup
out=$(run snapshot 80 "$TMP/out/site80" 2>&1); rc=$?
n1=$(find "$TMP/out/site80/1" -type f 2>/dev/null | wc -l)
n2=$(find "$TMP/out/site80/2" -type f 2>/dev/null | wc -l)
if [ "$rc" -eq 0 ] && [ "$n1" -eq 4 ] && [ "$n2" -eq 4 ] \
  && same "$TMP/out/site80/1/block-11.draft.html" "$CONTENT_D1" \
  && same "$TMP/out/site80/1/block-12.public.html" "$CONTENT_P1" \
  && same "$TMP/out/site80/2/block-21.draft.html" "$CONTENT_D2" \
  && same "$TMP/out/site80/2/block-22.public.html" "$CONTENT_P2" \
  && same "$TMP/out/site80/1/cssblock.css" "$CSS1" \
  && same "$TMP/out/site80/2/cssblock.css" "$CSS2" \
  && cmp -s "$TMP/out/site80/1/additional-fields.json" "$TMP/stub/af-1.json"; then
  ok 'snapshot writes 4 byte-exact files per page'
else
  bad "snapshot writes 4 byte-exact files per page (rc=$rc n1=$n1 n2=$n2) $out"
fi

# 2. verify without changes: rc 0, ok=8 failed=0
out=$(run verify 80 "$TMP/out/site80" 2>&1); rc=$?
if [ "$rc" -eq 0 ] && grep -q '^ok=8 failed=0$' <<<"$out"; then
  ok 'verify unchanged -> ok=8 failed=0'
else
  bad "verify unchanged -> ok=8 failed=0 (rc=$rc) $out"
fi

# 3. CSS length changed live: verify fails and names the file (AE1)
jq -n --arg c "$CSS2 .x{}" '{CSSBLOCK_USE:"Y",CSSBLOCK_CODE:$c}' > "$TMP/stub/af-2.json"
out=$(run verify 80 "$TMP/out/site80" 2>&1); rc=$?
if [ "$rc" -ne 0 ] && grep -q '2/cssblock.css' <<<"$out" && grep -q 'failed=2$' <<<"$out"; then
  ok 'verify after CSS change -> rc!=0 names 2/cssblock.css'
else
  bad "verify after CSS change -> rc!=0 names 2/cssblock.css (rc=$rc) $out"
fi

# 4. b24 fails midway: rc!=0, no partial snapshot left
setup
: > "$TMP/stub/fail-landing.landing.getadditionalfields-2"
out=$(run snapshot 80 "$TMP/out2/site80" 2>&1); rc=$?
left=$(find "$TMP/out2" -mindepth 1 2>/dev/null | wc -l)
if [ "$rc" -ne 0 ] && [ "$left" -eq 0 ]; then
  ok 'snapshot with b24 failure -> rc!=0, no partial files'
else
  bad "snapshot with b24 failure -> rc!=0, no partial files (rc=$rc left=$left) $out"
fi

printf 'pass=%d fail=%d\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
