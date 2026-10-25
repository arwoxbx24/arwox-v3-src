#!/usr/bin/env bash
# Black-box tests for b24-landing.sh. Bitrix24 REST (`b24`) and `curl` are stubs in PATH; git runs on
# throwaway repos under $TMP with a bare origin; no network.
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
# Reads come from $STUB files; writes change them the way Bitrix24 does (measured 21.10):
# updatecontent -> draft only; publication -> draft copied to the public block, unless $STUB/stale-public.
method=$1; shift
lid=''; mode=''; file=''
while [ $# -gt 0 ]; do
  case "$1" in
    lid=*) lid=${1#lid=} ;;
    'params[edit_mode]='*) mode=${1#*=} ;;
    --json-file) file=$2; lid=$(jq -r '.lid' "$file"); shift ;;
  esac
  shift
done
printf '%s lid=%s\n' "$method" "$lid" >> "$STUB/calls"
[ -e "$STUB/fail-$method-$lid" ] && { printf 'API error\n' >&2; exit 1; }
[ -z "$file" ] || cp "$file" "$STUB/sent-$method.json"
edit() { jq "$@" > "$STUB/t" && mv "$STUB/t" "${@: -1}"; }
case "$method" in
  landing.landing.getList) cat "$STUB/pages.json" ;;
  landing.block.getlist) cat "$STUB/blocks-$lid-$mode.json" ;;
  landing.landing.getadditionalfields) cat "$STUB/af-$lid.json" ;;
  landing.block.updatecontent)
    edit --slurpfile p "$file" '.[0].content = "<div id=\"b\(.[0].id)\" class=\"block-wrapper\">" + $p[0].content + "</div>"' "$STUB/blocks-$lid-1.json"; echo true ;;
  landing.landing.update)
    edit --slurpfile p "$file" '.CSSBLOCK_CODE = $p[0].fields.ADDITIONAL_FIELDS.CSSBLOCK_CODE' "$STUB/af-$lid.json"; echo true ;;
  landing.landing.publication)
    [ -e "$STUB/stale-public" ] || edit --slurpfile d "$STUB/blocks-$lid-1.json" '.[0].content = $d[0][0].content' "$STUB/blocks-$lid-0.json"; echo true ;;
  *) printf 'unexpected method %s\n' "$method" >&2; exit 1 ;;
esac
EOF
  chmod +x "$TMP/run/bin/b24"
  printf '#!/usr/bin/env bash\ncat "$STUB/page.html"\n' > "$TMP/run/bin/curl"
  chmod +x "$TMP/run/bin/curl"
  : > "$TMP/stub/calls"
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

# --- deploy / rollback / check: throwaway repo in $TMP with a bare origin; git identity from env ---
export GIT_AUTHOR_NAME=test GIT_AUTHOR_EMAIL=test@example.invalid GIT_COMMITTER_NAME=test GIT_COMMITTER_EMAIL=test@example.invalid
PROD_INNER=$'<section id="hero">Тарифы "q"\n<form action="https://forms.arwox.ru/">a</form><form action="https://forms.arwox.ru/">b</form><form action="https://forms.arwox.ru/">c</form></section>'
NEW_INNER=${PROD_INNER//Тарифы/Цены}
PROD_CSS=$'.p{color:red}\n/* Ж */'
DEV_BLOCK='<div id="b9220" class="block-wrapper">old dev</div>'
BASE_TAG=landing-prod-20260101-000000-abc1234

git_() { git -C "$TMP/repo" "$@"; }
in_repo() { (cd "$TMP/repo" && run "$@" 2>&1); }
writes() { grep -c -E '^landing\.(block\.updatecontent|landing\.update|landing\.publication) ' "$TMP/stub/calls" || true; }
block_at() { jq -j '.[0].content' "$TMP/stub/blocks-$1.json"; }
wrapped() { printf '<div id="b%s" class="block-wrapper">%s</div>' "$1" "$2"; }
main_page() { printf '<div id="b9116" class="block-wrapper block-0-one">%s</div>' "$1" > "$TMP/repo/landing/site78/362/block-9116.draft.html"; }

# repo_setup [notag]: the stub serves dev page 368 and prod page 362; a repo commit holds the prod main
# page (= live) and a snapshot of site 80; origin has that commit and, unless notag, the base tag.
repo_setup() {
  setup
  jq -n '[{ID:"368"}]' > "$TMP/stub/pages.json"
  jq -n --arg c "$DEV_BLOCK" '[{id:9220,content:$c}]' > "$TMP/stub/blocks-368-1.json"
  jq -n --arg c "$DEV_BLOCK" '[{id:9222,content:$c}]' > "$TMP/stub/blocks-368-0.json"
  jq -n '{CSSBLOCK_CODE:".d{}",METAROBOTS_INDEX:"N"}' > "$TMP/stub/af-368.json"
  rm -rf "$TMP/repo" "$TMP/origin.git"
  mkdir -p "$TMP/repo/landing/site78/362"
  git init -q -b main "$TMP/repo"
  main_page "$PROD_INNER"
  printf '%s' "$PROD_CSS" > "$TMP/repo/landing/site78/362/cssblock.css"
  jq -n --rawfile c "$TMP/repo/landing/site78/362/block-9116.draft.html" '[{id:9116,content:$c}]' > "$TMP/stub/blocks-362-1.json"
  jq -n --rawfile c "$TMP/repo/landing/site78/362/block-9116.draft.html" '[{id:9120,content:$c}]' > "$TMP/stub/blocks-362-0.json"
  jq -n --arg c "$PROD_CSS" '{CSSBLOCK_CODE:$c}' > "$TMP/stub/af-362.json"
  in_repo snapshot 80 landing/site80 > /dev/null
  git_ add -A
  git_ commit -q -m base
  [ "${1:-}" = notag ] || git_ tag "$BASE_TAG"
  git clone -q --bare "$TMP/repo" "$TMP/origin.git"
  git_ remote add origin "$TMP/origin.git"
  git_ fetch -q origin
  : > "$TMP/stub/calls"
}

# new_release: commit NEW_INNER as the prod main page and make that commit origin/main
new_release() {
  main_page "$NEW_INNER"
  git_ commit -q -a -m new
  git -C "$TMP/origin.git" fetch -q "$TMP/repo" main:main
}

# 5. deploy dev: the prod main page goes to dev page 368, every form on forms-test, prod untouched (AE2)
repo_setup
out=$(in_repo deploy dev); rc=$?
sent=$(jq -j '.content' "$TMP/stub/sent-landing.block.updatecontent.json" 2>/dev/null)
if [ "$rc" -eq 0 ] && [ "$sent" = "${PROD_INNER//forms.arwox.ru/forms-test.arwox.ru}" ] \
  && [ "$(grep -o -F 'action="https://forms-test.arwox.ru/"' <<<"$sent" | wc -l)" -eq 3 ] \
  && ! grep -q -F 'forms.arwox.ru' <<<"$sent" \
  && jq -e '.lid == 368 and .block == 9220' "$TMP/stub/sent-landing.block.updatecontent.json" > /dev/null \
  && jq -e --arg c "$PROD_CSS" '.lid == 368 and .fields.ADDITIONAL_FIELDS.CSSBLOCK_CODE == $c' "$TMP/stub/sent-landing.landing.update.json" > /dev/null \
  && [ "$(block_at 368-0)" = "$(wrapped 9220 "$sent")" ] && ! grep -q 'lid=362' "$TMP/stub/calls"; then
  ok 'deploy dev -> page 368 = prod files, 3/3 forms on forms-test, prod untouched (AE2)'
else
  bad "deploy dev -> page 368 = prod files, 3/3 forms on forms-test, prod untouched (AE2) (rc=$rc) $out"
fi

# 6. deploy dev when live page 368 was changed outside the repo -> refused, nothing written
repo_setup
jq -n '{CSSBLOCK_CODE:".d{color:blue}",METAROBOTS_INDEX:"N"}' > "$TMP/stub/af-368.json"
out=$(in_repo deploy dev); rc=$?
if [ "$rc" -ne 0 ] && [ "$(writes)" -eq 0 ] && grep -q 'FAIL 368/cssblock.css' <<<"$out"; then
  ok 'deploy dev, live dev changed -> refused, 0 writes'
else
  bad "deploy dev, live dev changed -> refused, 0 writes (rc=$rc) $out"
fi

# 7. the change snapshotted but not committed -> refused, nothing written (repo first)
repo_setup
jq -n '{CSSBLOCK_CODE:".d{color:blue}",METAROBOTS_INDEX:"N"}' > "$TMP/stub/af-368.json"
in_repo snapshot 80 landing/site80 > /dev/null
out=$(in_repo deploy dev); rc=$?
if [ "$rc" -ne 0 ] && [ "$(writes)" -eq 0 ] && grep -q 'uncommitted' <<<"$out"; then
  ok 'deploy dev, snapshot not committed -> refused, 0 writes'
else
  bad "deploy dev, snapshot not committed -> refused, 0 writes (rc=$rc) $out"
fi

# 8. a form in the files posts to a third address -> refused before any write
repo_setup
main_page "$PROD_INNER<form action=\"https://other.example/\">x</form>"
git_ commit -q -a -m other-form
out=$(in_repo deploy dev); rc=$?
if [ "$rc" -ne 0 ] && [ "$(writes)" -eq 0 ] && grep -q '3 of 4 form actions' <<<"$out"; then
  ok 'deploy dev, form to a third address -> refused, 0 writes'
else
  bad "deploy dev, form to a third address -> refused, 0 writes (rc=$rc) $out"
fi

# 9. CSS of 65536 bytes (the field keeps 65535) -> refused before any write
repo_setup
head -c 65536 /dev/zero | tr '\0' a > "$TMP/repo/landing/site78/362/cssblock.css"
git_ commit -q -a -m big-css
out=$(in_repo deploy dev); rc=$?
if [ "$rc" -ne 0 ] && [ "$(writes)" -eq 0 ] && grep -q '65536 bytes' <<<"$out"; then
  ok 'deploy dev, CSS 65536 bytes -> refused, 0 writes'
else
  bad "deploy dev, CSS 65536 bytes -> refused, 0 writes (rc=$rc) $out"
fi

# 10. deploy prod from a commit that is not origin/main -> refused, nothing written
repo_setup
main_page "$NEW_INNER"
git_ commit -q -a -m local-only
out=$(in_repo deploy prod); rc=$?
if [ "$rc" -ne 0 ] && [ "$(writes)" -eq 0 ] && grep -q 'origin/main' <<<"$out"; then
  ok 'deploy prod, HEAD not origin/main -> refused, 0 writes'
else
  bad "deploy prod, HEAD not origin/main -> refused, 0 writes (rc=$rc) $out"
fi

# 11. deploy prod with no landing-prod-* tag -> refused, nothing written
repo_setup notag
new_release
out=$(in_repo deploy prod); rc=$?
if [ "$rc" -ne 0 ] && [ "$(writes)" -eq 0 ] && grep -q 'no landing-prod-\* tag' <<<"$out"; then
  ok 'deploy prod, no tag -> refused, 0 writes'
else
  bad "deploy prod, no tag -> refused, 0 writes (rc=$rc) $out"
fi

# 12. live page 362 differs from the latest tag (edited in Bitrix24) -> refused, nothing written
repo_setup
new_release
jq -n '[{id:9120,content:"<div id=\"b9116\" class=\"x\">edited in Bitrix24</div>"}]' > "$TMP/stub/blocks-362-0.json"
out=$(in_repo deploy prod); rc=$?
if [ "$rc" -ne 0 ] && [ "$(writes)" -eq 0 ] && grep -q "differs from $BASE_TAG" <<<"$out"; then
  ok 'deploy prod, live != latest tag -> refused, 0 writes'
else
  bad "deploy prod, live != latest tag -> refused, 0 writes (rc=$rc) $out"
fi

# 13. the published block does not change after the write -> the tag's files go back (AE3)
repo_setup
new_release
: > "$TMP/stub/stale-public"
out=$(in_repo deploy prod); rc=$?
if [ "$rc" -ne 0 ] && grep -q 'write failed, restored' <<<"$out" \
  && [ "$(block_at 362-1)" = "$(wrapped 9116 "$PROD_INNER")" ] \
  && [ "$(git -C "$TMP/origin.git" tag -l 'landing-prod-*' | wc -l)" -eq 1 ]; then
  ok 'deploy prod, page not updated -> auto rollback to the tag, rc!=0, no new tag (AE3)'
else
  bad "deploy prod, page not updated -> auto rollback to the tag, rc!=0, no new tag (AE3) (rc=$rc) $out"
fi

# 14. deploy prod: page 362 = HEAD files, new landing-prod-* tag on HEAD in origin (R8)
repo_setup
new_release
out=$(in_repo deploy prod); rc=$?
tag=$(git -C "$TMP/origin.git" tag -l 'landing-prod-*' --sort=-refname | head -n 1)
if [ "$rc" -eq 0 ] && [ "$(block_at 362-0)" = "$(wrapped 9116 "$NEW_INNER")" ] && [ "$tag" != "$BASE_TAG" ] \
  && [ "$(git -C "$TMP/origin.git" rev-parse "$tag^{commit}")" = "$(git_ rev-parse HEAD)" ]; then
  ok 'deploy prod -> page 362 = HEAD, new tag on HEAD in origin (R8)'
else
  bad "deploy prod -> page 362 = HEAD, new tag on HEAD in origin (R8) (rc=$rc tag=$tag) $out"
fi

# 15. (after 14) rollback to the base tag -> page 362 = base files, new tag on the base commit (R11)
out=$(in_repo rollback "$BASE_TAG"); rc=$?
if [ "$rc" -eq 0 ] && [ "$(block_at 362-0)" = "$(wrapped 9116 "$PROD_INNER")" ] \
  && [ "$(git -C "$TMP/origin.git" tag -l 'landing-prod-*' --points-at "$BASE_TAG" | wc -l)" -eq 2 ]; then
  ok 'rollback <tag> -> page 362 = tag files, new tag on its commit (R11)'
else
  bad "rollback <tag> -> page 362 = tag files, new tag on its commit (R11) (rc=$rc) $out"
fi

SECTIONS='hero results demo case why-us process packages integrations partners certificates bitrixgpt tariffs faq websites contact'
page() { # page <forms url> <section>...: a minimal landing page for the curl stub
  local url=$1 s; shift
  printf '<html><head><meta name="robots" content="noindex" /><style type="text/css">.a{}</style><style type="text/css">%s</style></head><body>' "$PROD_CSS"
  for s in "$@"; do printf '<section id="%s"></section>' "$s"; done
  printf '<form action="%s"></form>' "$url" "$url" "$url"
  printf '</body></html>'
}

# 16. check of the dev page: 15 sections in order, 3/3 forms on forms-test, CSS size
setup
page https://forms-test.arwox.ru/ $SECTIONS > "$TMP/stub/page.html"
out=$(run check https://b24-w7skc9.bitrix24site.ru/ 2>&1); rc=$?
if [ "$rc" -eq 0 ] && grep -q "^ok sections=15 forms=3/3 css=$(printf '%s' "$PROD_CSS" | wc -c) robots=noindex$" <<<"$out"; then
  ok 'check dev page -> ok sections=15 forms=3/3 css=N'
else
  bad "check dev page -> ok sections=15 forms=3/3 css=N (rc=$rc) $out"
fi

# 17. sections out of order -> rc!=0, the order found is shown
page https://forms-test.arwox.ru/ results hero ${SECTIONS#hero results } > "$TMP/stub/page.html"
out=$(run check https://b24-w7skc9.bitrix24site.ru/ 2>&1); rc=$?
if [ "$rc" -ne 0 ] && grep -q 'results hero demo' <<<"$out"; then
  ok 'check, sections out of order -> rc!=0'
else
  bad "check, sections out of order -> rc!=0 (rc=$rc) $out"
fi

# 18. one of the 3 forms posts to the prod address -> rc!=0
page https://forms-test.arwox.ru/ $SECTIONS | sed 's|forms-test|forms|' > "$TMP/stub/page.html"
out=$(run check https://b24-w7skc9.bitrix24site.ru/ 2>&1); rc=$?
if [ "$rc" -ne 0 ] && grep -q 'forms=2/3' <<<"$out"; then
  ok 'check, 2 of 3 forms on forms-test -> rc!=0'
else
  bad "check, 2 of 3 forms on forms-test -> rc!=0 (rc=$rc) $out"
fi

# 19. page 362 half-written by an earlier failed run (draft = target, the rest = tag) -> the same command completes it
repo_setup
new_release
jq --arg c "$(wrapped 9116 "$NEW_INNER")" '.[0].content = $c' "$TMP/stub/blocks-362-1.json" > "$TMP/stub/t"
mv "$TMP/stub/t" "$TMP/stub/blocks-362-1.json"
out=$(in_repo deploy prod); rc=$?
if [ "$rc" -eq 0 ] && [ "$(block_at 362-0)" = "$(wrapped 9116 "$NEW_INNER")" ]; then
  ok 'deploy prod on a half-written page (each part = tag or target) -> completes'
else
  bad "deploy prod on a half-written page (each part = tag or target) -> completes (rc=$rc) $out"
fi

# 20. rollback with a revision suffix on an existing tag -> refused, nothing written
repo_setup
out=$(in_repo rollback "$BASE_TAG~1"); rc=$?
if [ "$rc" -ne 0 ] && [ "$(writes)" -eq 0 ] && grep -q 'refused' <<<"$out"; then
  ok 'rollback <tag>~1 -> refused, 0 writes'
else
  bad "rollback <tag>~1 -> refused, 0 writes (rc=$rc) $out"
fi

# 21. deploy dev with an uncommitted change in landing/site78/362 -> refused, nothing written
repo_setup
printf '.changed{}' > "$TMP/repo/landing/site78/362/cssblock.css"
out=$(in_repo deploy dev); rc=$?
if [ "$rc" -ne 0 ] && [ "$(writes)" -eq 0 ] && grep -q 'uncommitted' <<<"$out"; then
  ok 'deploy dev, uncommitted change in site78/362 -> refused, 0 writes'
else
  bad "deploy dev, uncommitted change in site78/362 -> refused, 0 writes (rc=$rc) $out"
fi

# 22. verify of an empty dir against a site with no pages -> rc!=0
setup
echo '[]' > "$TMP/stub/pages.json"
mkdir -p "$TMP/emptydir"
out=$(run verify 80 "$TMP/emptydir" 2>&1); rc=$?
if [ "$rc" -ne 0 ]; then
  ok 'verify, empty dir and site without pages -> rc!=0'
else
  bad "verify, empty dir and site without pages -> rc!=0 (rc=$rc) $out"
fi

# 24. deploy dev with METAROBOTS_INDEX=Y -> refused, nothing written
repo_setup
jq -n '{CSSBLOCK_CODE:".d{}",METAROBOTS_INDEX:"Y"}' > "$TMP/stub/af-368.json"
in_repo snapshot 80 landing/site80 > /dev/null
git_ add -A
git_ commit -q -m robots-y
out=$(in_repo deploy dev); rc=$?
if [ "$rc" -ne 0 ] && [ "$(writes)" -eq 0 ] && grep -q 'METAROBOTS_INDEX=Y' <<<"$out" && grep -q 'must be N' <<<"$out"; then
  ok 'deploy dev, METAROBOTS_INDEX=Y -> refused, 0 writes'
else
  bad "deploy dev, METAROBOTS_INDEX=Y -> refused, 0 writes (rc=$rc) $out"
fi

# 25. check dev page without noindex -> FAIL; with noindex -> ok
setup
page https://forms-test.arwox.ru/ $SECTIONS | sed 's|<meta name="robots" content="noindex" />||' > "$TMP/stub/page.html"
out=$(run check https://b24-w7skc9.bitrix24site.ru/ 2>&1); rc=$?
page https://forms-test.arwox.ru/ $SECTIONS > "$TMP/stub/page.html"
out2=$(run check https://b24-w7skc9.bitrix24site.ru/ 2>&1); rc2=$?
if [ "$rc" -ne 0 ] && grep -q 'FAIL robots' <<<"$out" && [ "$rc2" -eq 0 ] && grep -q 'robots=noindex$' <<<"$out2"; then
  ok 'check dev page: no noindex -> FAIL, noindex -> ok'
else
  bad "check dev page: no noindex -> FAIL, noindex -> ok (rc=$rc rc2=$rc2) $out $out2"
fi

# 26. check prod page with noindex -> FAIL; clean -> ok
setup
page https://forms.arwox.ru/ $SECTIONS > "$TMP/stub/page.html"
out=$(run check https://arwox.ru/ 2>&1); rc=$?
page https://forms.arwox.ru/ $SECTIONS | sed 's|<meta name="robots" content="noindex" />||' > "$TMP/stub/page.html"
out2=$(run check https://arwox.ru/ 2>&1); rc2=$?
if [ "$rc" -ne 0 ] && grep -q 'FAIL robots' <<<"$out" && [ "$rc2" -eq 0 ] && grep -q 'robots=index$' <<<"$out2"; then
  ok 'check prod page: noindex -> FAIL, clean -> ok'
else
  bad "check prod page: noindex -> FAIL, clean -> ok (rc=$rc rc2=$rc2) $out $out2"
fi

# 27. deploy dev with >=100 KB of Cyrillic: jq raw input must not corrupt it (no U+FFFD, byte-exact).
# jq 1.7 `-R -s` reads raw input in chunks and mangles a multibyte char split at a chunk boundary;
# `-n --rawfile` is byte-exact. A phrase long enough to cross many boundaries makes the old code corrupt.
BIG_CYR=$(printf 'Стоимость услуг по тарифам звоните нам %.0s' {1..3000})
PROD_INNER=$'<section id="hero">'"$BIG_CYR"$'<form action="https://forms.arwox.ru/">a</form><form action="https://forms.arwox.ru/">b</form><form action="https://forms.arwox.ru/">c</form></section>'
repo_setup
out=$(in_repo deploy dev); rc=$?
sent=$(jq -j '.content' "$TMP/stub/sent-landing.block.updatecontent.json" 2>/dev/null)
if [ "$rc" -eq 0 ] && [ "$(printf '%s' "$PROD_INNER" | wc -c)" -ge 102400 ] \
  && [ "$sent" = "${PROD_INNER//forms.arwox.ru/forms-test.arwox.ru}" ] \
  && ! grep -q -F '�' <<<"$sent"; then
  ok 'deploy dev with >=100 KB Cyrillic -> content byte-exact, no U+FFFD'
else
  bad "deploy dev with >=100 KB Cyrillic -> content byte-exact, no U+FFFD (rc=$rc bytes=$(printf '%s' "$sent" | wc -c)) $out"
fi

printf 'pass=%d fail=%d\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
