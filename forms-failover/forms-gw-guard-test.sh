#!/usr/bin/env bash
# forms-gw-guard-test: black-box contract tests for forms-gw-guard.sh using
# stub yc/curl on PATH. Spins up a throwaway state dir, never touches real YC.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GUARD="$SCRIPT_DIR/forms-gw-guard.sh"
REAL_DATE="$(command -v date)"
SWITCH="$SCRIPT_DIR/forms-fallback-switch.sh"
DNS_SWITCH="$SCRIPT_DIR/dns-switch.sh"

tmp=$(mktemp -d /tmp/forms-gw-guard-test.XXXXXX)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin" "$tmp/state"

cat > "$tmp/bin/date" <<'EOF'
#!/usr/bin/env bash
if [ "$#" = 1 ] && [ "$1" = '+%s' ]; then
  cat "$GUARD_TEST_TMP/clock"
elif [ "$#" = 2 ] && [ "$1" = '-u' ] && [ "$2" = '+%Y%m%dT%H%M%SZ' ] && [ -f "$GUARD_TEST_TMP/snapshot.timestamp" ]; then
  cat "$GUARD_TEST_TMP/snapshot.timestamp"
else
  exec "$GUARD_TEST_REAL_DATE" "$@"
fi
EOF

cat > "$tmp/bin/curl" <<'EOF'
#!/usr/bin/env bash
# Test stub for curl. Routes by URL and reads scenario fixtures from $GUARD_TEST_TMP.
url=""
out_file=""
use_k=""
text=""
header=""
input=""
use_resolve=""
prev=""
method=GET
body=""
for arg in "$@"; do
  if [ "$prev" = "-X" ]; then method="$arg"; prev=""; continue; fi
  if [ "$prev" = "--data-binary" ]; then body="${arg#@}"; prev=""; continue; fi
  if [ "$prev" = "-o" ]; then out_file="$arg"; prev=""; continue; fi
  if [ "$prev" = "--resolve" ]; then use_resolve=1; prev=""; continue; fi
  if [ "$prev" = "-w" ] || [ "$prev" = "-D" ] || [ "$prev" = "--max-time" ] || [ "$prev" = "-H" ]; then prev=""; continue; fi
  if [ "$prev" = "-K" ]; then [ "$arg" = "-" ] && use_k=1; prev=""; continue; fi
  case "$arg" in
    -s|-sS|-sI|-sk|-k|-I) ;;
    -o|-w|-D|--max-time|-H|-K|-X|--data-binary|--resolve) prev="$arg" ;;
    *) [ -z "$url" ] && url="$arg" ;;
  esac
done
printf '%s\n' "$@" >> "$GUARD_TEST_TMP/curl.argv.log"
if [ -n "$use_resolve" ] && [[ "$url" = https://* ]] && [ "$(cat "$GUARD_TEST_TMP/forms.code" 2>/dev/null)" = 000 ]; then
  exit 1
fi
if [ -n "$use_k" ]; then
  while IFS= read -r line; do
    case "$line" in
      url\ =\ *)
        [ -n "$url" ] || { url="${line#url = }"; url="${url#\"}"; url="${url%\"}"; };;
      header\ =\ *)
        header="${line#header = }"; header="${header#\"}"; header="${header%\"}";;
      data-urlencode\ =\ \"input_data=*)
        input="${line#data-urlencode = \"input_data=}"; input="${input%\"}"; input="${input//\\\"/\"}";;
      data-urlencode\ =\ *)
        text="${line#data-urlencode = \"text=}"; text="${text%\"}";;
    esac
  done
fi
case "$url" in
  https://api.telegram.org/*)
    printf '%s\n' "$url" >> "$GUARD_TEST_TMP/telegram.calls"
    ;;
esac
case "$url" in
  "$BEGET_API"/dns/getData)
    if [ -f "$GUARD_TEST_TMP/dns.auth" ]; then
      printf '%s\n' '{"status":"error","error_text":"auth","error_code":"AUTH_ERROR"}'
    else
      printf '%s' '{"status":"success","answer":{"status":"success","result":'
      cat "$GUARD_TEST_TMP/dns.records"
      printf '%s\n' '}}'
    fi
    ;;
  "$BEGET_API"/dns/changeRecords)
    printf '%s\n' "$input" >> "$GUARD_TEST_TMP/changeRecords.log"
    jq -c '{fqdn:.fqdn,records:.records}' <<< "$input" > "$GUARD_TEST_TMP/dns.records"
    printf '%s\n' '{"status":"success","answer":{"status":"success","result":true}}'
    ;;
  https://vibe.test/v1/*)
    printf '%s %s\n' "$method" "$url" >> "$GUARD_TEST_TMP/api.log"
    printf '%s\n' "$header" >> "$GUARD_TEST_TMP/api.header.log"
    status=200
    response='{"data":{}}'
    if [ "$(cat "$GUARD_TEST_TMP/api.denied")" = "$method" ]; then
      status=403; response='{"error":{"code":"SCOPE_DENIED"}}'
    elif [ "$method" = PATCH ]; then
      jq -erj '.content' "$body" > "$GUARD_TEST_TMP/draft.html" || exit 90
      cp "$GUARD_TEST_TMP/draft.html" "$GUARD_TEST_TMP/last-patch.html"
      if [ -f "$GUARD_TEST_TMP/mismatch" ]; then
        printf 'mismatch' > "$GUARD_TEST_TMP/draft.html"
        rm "$GUARD_TEST_TMP/mismatch"
      fi
    elif [ "$method" = GET ]; then
      response=$(jq -n --rawfile h "$GUARD_TEST_TMP/draft.html" '{data:{html:$h}}')
    elif [ "$method" = POST ]; then
      cp "$GUARD_TEST_TMP/draft.html" "$GUARD_TEST_TMP/published.html"
    else
      exit 91
    fi
    [ -n "$out_file" ] || exit 92
    printf '%s' "$response" > "$out_file"
    printf '%s' "$status"
    ;;
  *sendMessage*)
    printf '%s\n' "$text" >> "$GUARD_TEST_TMP/sent.log"
    printf '{"ok":true}\n'
    ;;
  *getMe*)
    if [ -f "$GUARD_TEST_TMP/getme.fail" ]; then
      printf '{"ok":false,"error_code":401,"description":"Unauthorized"}\n'
    else
      printf '{"ok":true,"result":{"username":"StatusTrackers_bot"}}\n'
    fi
    ;;
  *billingAccounts*)
    if [ -f "$GUARD_TEST_TMP/billing.fail" ]; then exit 1; fi
    printf '{"billingAccounts":[{"active":true,"balance":"%s"}]}\n' "$(cat "$GUARD_TEST_TMP/balance")"
    ;;
  https://storage.yandexcloud.net/*|https://ya.ru/*)
    printf '%s\n' "$(cat "$GUARD_TEST_TMP/net.code" 2>/dev/null || echo 200)"
    ;;
  http://*/|https://*/)
    if [ -n "$use_resolve" ]; then
      scheme=${url%%://*}
      if [ -e "$GUARD_TEST_TMP/precheck.$scheme.hdr" ]; then
        cat "$GUARD_TEST_TMP/precheck.$scheme.hdr"
      else
        cat "$GUARD_TEST_TMP/precheck.hdr"
      fi
    else
      [ -n "$out_file" ] && cat "$GUARD_TEST_TMP/forms.body" > "$out_file"
      printf '%s 0\n' "$(cat "$GUARD_TEST_TMP/forms.code" 2>/dev/null)"
    fi
    ;;
  *)
    [ -n "$out_file" ] && cat "$GUARD_TEST_TMP/forms.body" > "$out_file"
    printf '%s 0\n' "$(cat "$GUARD_TEST_TMP/forms.code" 2>/dev/null)"
    ;;
esac
EOF

cat > "$tmp/bin/yc" <<'EOF'
#!/usr/bin/env bash
# Test stub for yc. Scenarios are driven by files in $GUARD_TEST_TMP.
if [ -f "$GUARD_TEST_TMP/yc-hang" ]; then sleep 30; fi
case "$*" in
  "iam create-token"*)
    if [ -f "$GUARD_TEST_TMP/iam.fail" ]; then
      printf 'IAM error\n' >&2
      exit 1
    fi
    printf 'stub-token\n'
    ;;
  "serverless api-gateway get"*)
    printf '{"status":"%s"}\n' "$(cat "$GUARD_TEST_TMP/gw.status")"
    ;;
  "serverless api-gateway resume"*)
    printf '%s\n' "resume" > "$GUARD_TEST_TMP/resume.called"
    [ ! -f "$GUARD_TEST_TMP/resume.fail" ] || exit 1
    printf 'ACTIVE\n' > "$GUARD_TEST_TMP/gw.status"
    printf '302\n' > "$GUARD_TEST_TMP/forms.code"
    printf 'ok\n' > "$GUARD_TEST_TMP/forms.body"
    ;;
  "serverless function get"*)
    if [ -f "$GUARD_TEST_TMP/fn.fail" ]; then
      printf 'stub: function get failed\n' >&2
      exit 1
    fi
    printf '{"status":"%s"}\n' "$(cat "$GUARD_TEST_TMP/fn.status" 2>/dev/null || echo ACTIVE)"
    ;;
  *"storage s3api list-objects"*)
    printf '%s\n' "$*" >> "$GUARD_TEST_TMP/reserve.calls"
    if [ -f "$GUARD_TEST_TMP/reserve.fail" ]; then
      printf 'stub: list failed\n' >&2
      exit 1
    fi
    after=""
    prev=""
    for a in "$@"; do
      if [ "$prev" = "--start-after" ]; then after="$a"; fi
      prev="$a"
    done
    items=""
    while IFS= read -r k; do
      [ -n "$k" ] || continue
      if [ -z "$after" ] || [[ "$k" > "$after" ]]; then
        printf -v item '{"key":"%s","size":1}' "$k"
        items="${items:+$items,}$item"
      fi
    done < <(cat "$GUARD_TEST_TMP/reserve.keys" 2>/dev/null)
    if [ -n "$items" ]; then
      printf '{"contents":[%s],"key_count":1,"is_truncated":false}\n' "$items"
    else
      printf '{"key_count":0,"is_truncated":false}\n'
    fi
    ;;
  *"logging read"*)
    printf 'logging-read\n' >> "$GUARD_TEST_TMP/yc-logging.calls"
    if [ -f "$GUARD_TEST_TMP/yc-logging-unavailable" ]; then
      printf 'ERROR: getting log group by ID: rpc error: code = Unavailable desc = Unavailable\n' >&2
      exit 1
    fi
    if [ -f "$GUARD_TEST_TMP/yc-logging-fail" ]; then
      printf 'stub: logging read failed\n' >&2
      exit 1
    fi
    n=$(cat "$GUARD_TEST_TMP/yc-logging-count" 2>/dev/null || echo 0)
    case "$n" in ''|*[!0-9]*) n=0 ;; esac
    i=0
    while [ "$i" -lt "$n" ]; do
      printf '{"message_version":"1","entry":{"message":"2026-10-16T11:21:44: captcha=unavailable"}}\n'
      i=$((i + 1))
    done
    ;;
esac
EOF
cat > "$tmp/bin/dig" <<'EOF'
#!/usr/bin/env bash
case "$*" in
  *@ns*.beget.*) printf '203.0.113.10\n' ;;
  *) [ -e "$GUARD_TEST_TMP/dig.empty" ] || printf '203.0.113.9\n' ;;
esac
EOF
chmod +x "$tmp/bin/curl" "$tmp/bin/yc" "$tmp/bin/dig"
chmod +x "$tmp/bin/date"

export PATH="$tmp/bin:$PATH"
export GUARD_STATE_DIR="$tmp/state"
export GUARD_TEST_TMP="$tmp"
export GUARD_TEST_REAL_DATE="$REAL_DATE"
export TG_BOT_TOKEN=test
export TG_CHAT_ID=1
export GUARD_REMINDER_SEC=3600
export GUARD_FALL_N=2 GUARD_RISE_N=2
unset GUARD_GW_ID GUARD_FORMS_URL GUARD_BALANCE_MIN GUARD_DEBOUNCE_SEC
unset FALLBACK_PAGE_ID FALLBACK_BLOCK_ID FALLBACK_API_URL VIBE_API_URL VIBECODE_API_KEY

PASS=0
FAIL=0

case1() { # ACTIVE: forms 302, balance enough
  printf '100000\n' > "$tmp/clock"
  printf '302\n' > "$tmp/forms.code"
  printf 'ok\n' > "$tmp/forms.body"
  printf 'ACTIVE\n' > "$tmp/gw.status"
  printf '100\n' > "$tmp/balance"
  rm -f "$tmp/sent.log" "$tmp/resume.called" "$tmp/state/state.json"
  out=$(bash "$GUARD" 2>&1); rc=$?
  [ "$rc" = 0 ] && [ ! -f "$tmp/resume.called" ] && \
    { [ ! -e "$tmp/sent.log" ] || [ ! -s "$tmp/sent.log" ]; }
}

case2() { # STOPPED: resume succeeds, gw_resumed sent once
  printf '100000\n' > "$tmp/clock"
  printf '403\n' > "$tmp/forms.code"
  printf 'form is stopped and cannot be used\n' > "$tmp/forms.body"
  printf 'STOPPED\n' > "$tmp/gw.status"
  printf '100\n' > "$tmp/balance"
  rm -f "$tmp/sent.log" "$tmp/resume.called" "$tmp/state/state.json"
  out=$(bash "$GUARD" 2>&1); rc=$?
  n=$(grep -c 'шлюз форм был остановлен' "$tmp/sent.log" 2>/dev/null || true)
  printf '%s' "$out" | grep -q 'resume issued' && [ "$rc" = 0 ] && [ "$n" = 1 ]
}

case3() { # low balance: sends once, second run debounced
  printf '100000\n' > "$tmp/clock"
  printf '302\n' > "$tmp/forms.code"
  printf 'ok\n' > "$tmp/forms.body"
  printf 'ACTIVE\n' > "$tmp/gw.status"
  printf '5.1\n' > "$tmp/balance"
  rm -f "$tmp/sent.log" "$tmp/resume.called" "$tmp/state/state.json"
  bash "$GUARD" >/dev/null 2>&1
  out2=$(bash "$GUARD" 2>&1)
  n=$(grep -c 'Баланс Yandex Cloud' "$tmp/sent.log" 2>/dev/null || true)
  printf '%s' "$out2" | grep -q 'debounced low_balance' && [ "$n" = 1 ]
}

case4() { # outage reminders, one recovery, then a fresh immediate alert
  printf '000\n' > "$tmp/forms.code"
  printf 'unavailable\n' > "$tmp/forms.body"
  printf 'ACTIVE\n' > "$tmp/gw.status"
  printf '100\n' > "$tmp/balance"
  rm -f "$tmp/sent.log" "$tmp/resume.called" "$tmp/state/state.json"

  printf '100000\n' > "$tmp/clock"; bash "$GUARD" >/dev/null 2>&1
  printf '103599\n' > "$tmp/clock"; bash "$GUARD" >/dev/null 2>&1
  before=$(grep -c 'forms.arwox.ru отвечает <000>' "$tmp/sent.log" 2>/dev/null || true)
  printf '103600\n' > "$tmp/clock"; bash "$GUARD" >/dev/null 2>&1
  printf '107200\n' > "$tmp/clock"; bash "$GUARD" >/dev/null 2>&1
  printf '110800\n' > "$tmp/clock"; bash "$GUARD" >/dev/null 2>&1
  reminders=$(grep -c 'forms.arwox.ru отвечает <000>' "$tmp/sent.log" 2>/dev/null || true)
  grep -q 'Сбой длится 0м' "$tmp/sent.log" && \
    grep -q 'Сбой длится 1ч 0м' "$tmp/sent.log" && \
    grep -q 'Сбой длится 2ч 0м' "$tmp/sent.log" && \
    grep -q 'Сбой длится 3ч 0м' "$tmp/sent.log" || return 1

  printf '302\n' > "$tmp/forms.code"
  printf 'ok\n' > "$tmp/forms.body"
  printf '110801\n' > "$tmp/clock"; bash "$GUARD" >/dev/null 2>&1
  printf '110802\n' > "$tmp/clock"; bash "$GUARD" >/dev/null 2>&1
  recoveries=$(grep -c 'восстановлено' "$tmp/sent.log" 2>/dev/null || true)

  printf '000\n' > "$tmp/forms.code"
  printf 'unavailable\n' > "$tmp/forms.body"
  printf '110803\n' > "$tmp/clock"; bash "$GUARD" >/dev/null 2>&1
  fresh=$(grep -c 'forms.arwox.ru отвечает <000>' "$tmp/sent.log" 2>/dev/null || true)
  [ "$before" = 1 ] && [ "$reminders" = 4 ] && [ "$recoveries" = 1 ] && \
    [ "$fresh" = 5 ] && grep -q 'восстановлено.*Сбой длился 3ч 0м' "$tmp/sent.log"
}

fallback_setup() {
  export GUARD_FALL_N=2 GUARD_RISE_N=2
  printf '100000\n' > "$tmp/clock"
  printf '000\n' > "$tmp/forms.code"
  printf 'unavailable\n' > "$tmp/forms.body"
  printf 'ACTIVE\n' > "$tmp/gw.status"
  printf '100\n' > "$tmp/balance"
  printf '\n' > "$tmp/api.denied"
  rm -f "$tmp/sent.log" "$tmp/api.log" "$tmp/api.header.log" "$tmp/curl.argv.log" "$tmp/state/state.json" "$tmp/published.html" "$tmp/mismatch" "$tmp/resume.fail" "$tmp/net.code" "$tmp/iam.fail"
  export FALLBACK_PAGE_ID=362 FALLBACK_BLOCK_ID=9116 FALLBACK_API_URL=https://vibe.test
  export VIBECODE_API_KEY=synthetic-test-key
  export FALLBACK_SNAPSHOT="$tmp/snapshot.json"
  printf '<form action="https://forms.arwox.ru/"><button type="submit" style="color:red">Send</button></form>\n%.0s' {1..3} > "$tmp/normal.html"
  printf '<form action="https://forms.arwox.ru/"><p>Форма работает через резервный канал</p>\n<a href="https://b24-pne9rr.bitrix24.site/crm_form_yoolu/" target="_blank" rel="noopener" style="color:red">Оставить заявку</a></form>\n%.0s' {1..3} > "$tmp/outage.html"
  jq -n --rawfile h "$tmp/normal.html" '{data:{html:("<div id=\"block9116\" class=\"block-wrapper\">"+$h+"</div>")}}' > "$FALLBACK_SNAPSHOT"
  cp "$tmp/normal.html" "$tmp/draft.html"
}

run_guard() { bash "$GUARD" > "$tmp/guard.log" 2>&1; }
api_count() { if [ -f "$tmp/api.log" ]; then grep -c "^$1 " "$tmp/api.log" || true; else printf 0; fi; }

case5() { # deterministic variants, wrapper stripped, style retained
  fallback_setup
  bash "$SWITCH" build "$FALLBACK_SNAPSHOT" > "$tmp/build.log" 2>&1 || return 1
  cmp "$tmp/normal.html" "$tmp/state/fallback-normal.html" && \
    cmp "$tmp/outage.html" "$tmp/state/fallback-outage.html"
}
case6() { # two failures publish outage once, further failures do not rewrite
  fallback_setup
  run_guard; run_guard; run_guard
  [ "$(api_count PATCH)" = 1 ] && [ "$(api_count POST)" = 1 ] && \
    cmp "$tmp/outage.html" "$tmp/published.html" && \
    jq -e '.fallback_mode == "outage" and .fallback_failures >= 2' "$tmp/state/state.json" >/dev/null && \
    grep -q 'заявки принимает резерв' "$tmp/sent.log"
}
case7() { # one failed check never touches the API
  fallback_setup
  run_guard
  [ "$(api_count PATCH)" = 0 ] && [ ! -s "$tmp/api.log" ]
}
case8() { # two successes restore normal, first success cannot switch
  fallback_setup
  run_guard; run_guard
  printf '302\n' > "$tmp/forms.code"
  run_guard
  [ "$(api_count PATCH)" = 1 ] || return 1
  run_guard; run_guard
  [ "$(api_count PATCH)" = 2 ] && [ "$(api_count POST)" = 2 ] && \
    cmp "$tmp/normal.html" "$tmp/published.html" && \
    jq -e '.fallback_mode == "normal"' "$tmp/state/state.json" >/dev/null && \
    grep -q 'вернулись на основной' "$tmp/sent.log"
}
case9() { # read-back mismatch restores the exact previous draft, no publication
  fallback_setup
  touch "$tmp/mismatch"
  run_guard; run_guard
  [ "$(api_count PATCH)" = 2 ] && [ "$(api_count POST)" = 0 ] && \
    cmp "$tmp/normal.html" "$tmp/draft.html" && \
    jq -e '(.fallback_mode // "normal") == "normal"' "$tmp/state/state.json" >/dev/null && \
    grep -q 'fallback_rollback' "$tmp/sent.log"
}
case10() { # foreign draft is preserved, wrapped recognized draft is accepted
  fallback_setup
  printf 'editor changes' > "$tmp/draft.html"
  run_guard; run_guard
  [ "$(api_count PATCH)" = 0 ] && [ "$(api_count POST)" = 0 ] && \
    grep -q 'fallback_foreign_draft' "$tmp/sent.log" || return 1
  [ "$(cat "$tmp/draft.html")" = 'editor changes' ] || return 1
  fallback_setup
  jq -rj '.data.html' "$FALLBACK_SNAPSHOT" > "$tmp/draft.html"
  run_guard; run_guard
  [ "$(api_count PATCH)" = 1 ] && cmp "$tmp/outage.html" "$tmp/published.html"
}
case11() { # 403 at read, write or publication alerts, mode remains normal
  local method
  for method in GET PATCH POST; do
    fallback_setup
    printf '%s\n' "$method" > "$tmp/api.denied"
    run_guard; run_guard
    [ ! -f "$tmp/published.html" ] && \
      jq -e '(.fallback_mode // "normal") == "normal"' "$tmp/state/state.json" >/dev/null && \
      grep -q '403' "$tmp/sent.log" || return 1
  done
}
case12() { # either unset id disables guard and direct apply before any API use
  local id
  for id in FALLBACK_PAGE_ID FALLBACK_BLOCK_ID; do
    fallback_setup
    export "$id="
    run_guard; run_guard
    bash "$SWITCH" apply outage > "$tmp/apply.log" 2>&1 || return 1
    [ ! -s "$tmp/api.log" ] || return 1
  done
}
case13() { # gw_failed participates in the same consecutive failure counter
  fallback_setup
  printf '403\n' > "$tmp/forms.code"
  printf 'form is stopped and cannot be used\n' > "$tmp/forms.body"
  printf 'STOPPED\n' > "$tmp/gw.status"
  touch "$tmp/resume.fail"
  run_guard; run_guard
  [ "$(api_count PATCH)" = 1 ] && cmp "$tmp/outage.html" "$tmp/published.html"
}

case14() { # transitions and API-key header bypass the six-hour default debounce
  fallback_setup
  run_guard; run_guard
  printf '302\n' > "$tmp/forms.code"
  run_guard; run_guard
  printf '000\n' > "$tmp/forms.code"
  run_guard; run_guard
  printf '302\n' > "$tmp/forms.code"
  run_guard; run_guard
  [ "$(grep -c 'заявки принимает резерв' "$tmp/sent.log")" = 2 ] && \
    [ "$(grep -c 'вернулись на основной' "$tmp/sent.log")" = 2 ] && \
    ! grep -q 'synthetic-test-key' "$tmp/curl.argv.log" && \
    grep -qx 'X-API-Key: synthetic-test-key' "$tmp/api.header.log"
}

case15() { # apply errors notify each time under six hours with their own state key
  fallback_setup
  printf 'editor changes' > "$tmp/draft.html"
  run_guard; run_guard; run_guard
  [ "$(grep -c 'fallback_foreign_draft' "$tmp/sent.log")" = 2 ] && \
    jq -e 'has("fallback_foreign_draft") and (has("fallback_switch") | not)' "$tmp/state/state.json" >/dev/null || return 1
  fallback_setup
  touch "$tmp/mismatch"
  run_guard; run_guard
  grep -q 'fallback_rollback' "$tmp/sent.log" && \
    jq -e 'has("fallback_rollback") and (has("fallback_switch") | not)' "$tmp/state/state.json" >/dev/null || return 1
  fallback_setup
  printf 'GET\n' > "$tmp/api.denied"
  run_guard; run_guard; run_guard
  [ "$(grep -c 'fallback_api_http_403' "$tmp/sent.log")" = 2 ] && \
    jq -e 'has("fallback_api_http_403") and (has("fallback_switch") | not)' "$tmp/state/state.json" >/dev/null
}

case16() { # default snapshot comes from the script's repository directory
  mkdir -p "$tmp/default/forms-fallback"
  cp "$SWITCH" "$tmp/default/forms-fallback-switch.sh"
  jq '.data.html |= sub(">"; ">repository snapshot")' \
    "$SCRIPT_DIR/forms-fallback/9116-before.json" > "$tmp/default/forms-fallback/9116-before.json"
  env -u FALLBACK_SNAPSHOT GUARD_STATE_DIR="$tmp/default/state" \
    bash "$tmp/default/forms-fallback-switch.sh" build > "$tmp/build.log" 2>&1 || return 1
  grep -q '^repository snapshot' "$tmp/default/state/fallback-normal.html"
}

dns_setup() {
  export GUARD_FALL_N=2 GUARD_RISE_N=2
  local name=$1
  local dns_tmp="$tmp/$name"
  rm -rf "$dns_tmp"
  mkdir -p "$dns_tmp/state"
  export GUARD_TEST_TMP="$dns_tmp"
  export GUARD_STATE_DIR="$dns_tmp/state"
  export BEGET_API=http://beget.test/api
  export BEGET_IP=203.0.113.10
  export BEGET_ENV_FILE="$dns_tmp/beget.env"
  export TG_BOT_TOKEN=x TG_CHAT_ID=1
  printf '100000\n' > "$dns_tmp/clock"
  printf 'BEGET_LOGIN=test\nBEGET_API_PASSWORD=test\n' > "$BEGET_ENV_FILE"
  printf '{"fqdn":"forms.arwox.ru","records":{"CNAME":[{"ttl":600,"cname":"d5dn462s09a9dpofvl2d.6brbn2wz.apigw.yandexcloud.net."}]}}\n' > "$dns_tmp/dns.records"
}

dns_run() { bash "$SCRIPT_DIR/dns-switch.sh" "$@"; }

case17() { # status classifies normal, outage and foreign without writes
  dns_setup case17
  out=$(dns_run status); rc=$?
  [ "$out" = normal ] && [ "$rc" = 0 ] || return 1
  printf '{"fqdn":"forms.arwox.ru","records":{"A":[{"priority":10,"value":"203.0.113.10"}]}}\n' > "$GUARD_TEST_TMP/dns.records"
  out=$(dns_run status); rc=$?
  [ "$out" = outage ] && [ "$rc" = 0 ] || return 1
  printf '{"fqdn":"forms.arwox.ru","records":{"A":[{"priority":10,"value":"198.51.100.7"}]}}\n' > "$GUARD_TEST_TMP/dns.records"
  out=$(dns_run status); rc=$?
  [ "$out" = foreign ] && [ "$rc" = 4 ] || return 1
  dns_run apply outage >/dev/null; rc=$?
  [ "$rc" = 4 ] && [ ! -e "$GUARD_TEST_TMP/changeRecords.log" ] || return 1
  dns_run status --fqdn forms-test.arwox.ru >/dev/null
  [ -f "$GUARD_STATE_DIR/forms-dns.forms-test.arwox.ru.json" ]
}

case18() { # refusal keeps DNS intact; switch and restore use one snapshot
  dns_setup case18
  cp -f "$GUARD_TEST_TMP/dns.records" "$GUARD_TEST_TMP/original.records"
  printf 'HTTP/2 200\n' > "$GUARD_TEST_TMP/precheck.hdr"
  out=$(dns_run apply outage); rc=$?
  printf '%s' "$out" | grep -q '^refused precheck' && [ "$rc" = 3 ] && \
    [ ! -e "$GUARD_TEST_TMP/changeRecords.log" ] && [ "$(wc -l < "$GUARD_TEST_TMP/sent.log")" = 1 ] || return 1
  cmp "$GUARD_TEST_TMP/original.records" "$GUARD_STATE_DIR/forms-dns.snapshot.forms.arwox.ru.json" || return 1
  printf 'HTTP/2 302\nlocation: https://arwox.ru/#contact\n' > "$GUARD_TEST_TMP/precheck.hdr"
  out=$(dns_run apply outage); rc=$?
  [ "$out" = 'switched normal→outage' ] && [ "$rc" = 0 ] && \
    [ "$(wc -l < "$GUARD_TEST_TMP/changeRecords.log")" = 1 ] && grep -q '"A".*203.0.113.10' "$GUARD_TEST_TMP/changeRecords.log" && \
    grep -Fxq -- '-D' "$GUARD_TEST_TMP/curl.argv.log" && grep -Fxq -- 'forms.arwox.ru:80:203.0.113.10' "$GUARD_TEST_TMP/curl.argv.log" && \
    grep -Fxq -- 'http://forms.arwox.ru/' "$GUARD_TEST_TMP/curl.argv.log" || return 1
  out=$(dns_run apply outage); [ "$out" = 'noop outage' ] || return 1
  [ "$(wc -l < "$GUARD_TEST_TMP/changeRecords.log")" = 1 ] || return 1
  out=$(dns_run apply normal); rc=$?
  [ "$out" = 'switched outage→normal' ] && [ "$rc" = 0 ] && \
    [ "$(wc -l < "$GUARD_TEST_TMP/changeRecords.log")" = 2 ] && grep -q '"CNAME"' "$GUARD_TEST_TMP/changeRecords.log" || return 1
  cmp "$GUARD_TEST_TMP/original.records" "$GUARD_STATE_DIR/forms-dns.snapshot.forms.arwox.ru.json"
}

case19() { # third consecutive API failure sends exactly one alert and success resets it
  dns_setup case19
  touch "$GUARD_TEST_TMP/dns.auth"
  for i in {1..3}; do
    out=$(dns_run status); rc=$?
    [ "$out" = 'api_error AUTH_ERROR' ] && [ "$rc" = 2 ] || return 1
  done
  [ "$(wc -l < "$GUARD_TEST_TMP/sent.log")" = 1 ] && \
    jq -e '.api_fail == 3' "$GUARD_STATE_DIR/forms-dns.forms.arwox.ru.json" >/dev/null && \
    [ ! -e "$GUARD_TEST_TMP/changeRecords.log" ] || return 1
  rm -f "$GUARD_TEST_TMP/dns.auth"
  out=$(dns_run status); rc=$?
  [ "$out" = normal ] && [ "$rc" = 0 ] && jq -e '.api_fail == 0' "$GUARD_STATE_DIR/forms-dns.forms.arwox.ru.json" >/dev/null
}

snapshot_setup() {
  export GUARD_TEST_TMP="$tmp" GUARD_STATE_DIR="$tmp/state"
  unset GUARD_GW_HOST
  fallback_setup
  rm -rf "$GUARD_STATE_DIR/incidents"
  printf '20261009T000001Z\n' > "$GUARD_TEST_TMP/snapshot.timestamp"
}

case20() { # outage stores one complete snapshot and reports its path
  snapshot_setup
  run_guard; run_guard
  snapshot=$(find "$GUARD_STATE_DIR/incidents" -mindepth 1 -maxdepth 1 -type d 2>/dev/null)
  [ "$(printf '%s\n' "$snapshot" | wc -l)" = 1 ] && \
    [ -f "$snapshot/curl.txt" ] && [ -f "$snapshot/dns.txt" ] && \
    [ "$(cat "$snapshot/guard.txt")" = 'no log' ] && \
    grep -Fq "Снимок: $snapshot" "$tmp/sent.log"
}

case21() { # normal transition leaves the outage snapshot count unchanged
  before=$(find "$GUARD_STATE_DIR/incidents" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l)
  printf '302\n' > "$tmp/forms.code"
  run_guard; run_guard
  after=$(find "$GUARD_STATE_DIR/incidents" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l)
  [ "$before" = 1 ] && [ "$after" = "$before" ]
}

case22() { # twelve outages retain only the ten newest snapshots
  local i
  snapshot_setup
  for i in {1..12}; do
    printf '20261009T0000%02dZ\n' "$i" > "$GUARD_TEST_TMP/snapshot.timestamp"
    run_guard; run_guard
    printf '302\n' > "$tmp/forms.code"
    run_guard; run_guard
    printf '000\n' > "$tmp/forms.code"
  done
  [ "$(find "$GUARD_STATE_DIR/incidents" -mindepth 1 -maxdepth 1 -type d | wc -l)" = 10 ]
}

case23() { # DNS failure stays in dns-switch notification channel
  snapshot_setup
  export FALLBACK_PAGE_ID= FALLBACK_BLOCK_ID= DNS_SWITCH="$tmp/dns-fail.sh"
  printf '#!/usr/bin/env bash\nprintf "dns failure\\n"\nexit 4\n' > "$DNS_SWITCH"
  chmod +x "$DNS_SWITCH"
  run_guard; run_guard
  ! grep -q 'dns failure\|fallback_outage' "$tmp/sent.log" 2>/dev/null && \
    grep -q 'dns switch failed: dns failure' "$tmp/guard.log" && \
    jq -e '(.fallback_mode // "normal") != "outage"' "$tmp/state/state.json" >/dev/null
}

case24() { # DNS-only fallback enters outage without an unbound result
  snapshot_setup
  export FALLBACK_PAGE_ID= FALLBACK_BLOCK_ID= DNS_SWITCH="$tmp/dns-ok.sh"
  printf '#!/usr/bin/env bash\nprintf "switched normal→outage\\n"\nexit 0\n' > "$DNS_SWITCH"
  chmod +x "$DNS_SWITCH"
  run_guard; run_guard
  jq -e '.fallback_mode == "outage"' "$tmp/state/state.json" >/dev/null && \
    grep -q 'заявки принимает резерв' "$tmp/sent.log" && \
    grep -q 'sent fallback_outage' "$tmp/guard.log" && \
    ! grep -q 'unbound variable' "$tmp/guard.log"
}

case25() { # failed DNS outage captures once without fallback notification
  snapshot_setup
  export FALLBACK_PAGE_ID= FALLBACK_BLOCK_ID= DNS_SWITCH="$tmp/dns-fail.sh"
  printf '#!/usr/bin/env bash\nprintf "refused: precheck NET\\n"\nexit 1\n' > "$DNS_SWITCH"
  chmod +x "$DNS_SWITCH"
  : > "$tmp/guard.log"
  for i in {1..3}; do bash "$GUARD" >> "$tmp/guard.log" 2>&1; done
  [ "$(find "$GUARD_STATE_DIR/incidents" -mindepth 1 -maxdepth 1 -type d | wc -l)" = 1 ] && \
    [ "$(grep -c 'snapshot:' "$tmp/guard.log")" = 1 ] && \
    ! grep -q 'sent fallback_outage' "$tmp/guard.log"
}

case26() { # successful transition clears the failed-DNS snapshot gate
  snapshot_setup
  export FALLBACK_PAGE_ID= FALLBACK_BLOCK_ID= DNS_SWITCH="$tmp/dns-switch.sh"
  printf '#!/usr/bin/env bash\nprintf "refused: precheck NET\\n"\nexit 1\n' > "$DNS_SWITCH"
  chmod +x "$DNS_SWITCH"
  run_guard; run_guard
  printf '#!/usr/bin/env bash\nprintf "switched normal→outage\\n"\n' > "$DNS_SWITCH"
  printf '20261009T000002Z\n' > "$GUARD_TEST_TMP/snapshot.timestamp"
  run_guard
  jq -e '(.fallback_mode == "outage") and (has("dns_fail_snapshot") | not)' "$GUARD_STATE_DIR/state.json" >/dev/null || return 1
  printf '302\n' > "$tmp/forms.code"
  run_guard; run_guard
  printf '#!/usr/bin/env bash\nprintf "refused: precheck NET\\n"\nexit 1\n' > "$DNS_SWITCH"
  printf '20261009T000003Z\n' > "$GUARD_TEST_TMP/snapshot.timestamp"
  printf '000\n' > "$tmp/forms.code"
  run_guard; run_guard
  [ "$(find "$GUARD_STATE_DIR/incidents" -mindepth 1 -maxdepth 1 -type d | wc -l)" = 3 ]
}

case27() { # certificate logging has one rc line
  snapshot_setup
  printf '{"fallback_mode":"outage"}\n' > "$GUARD_STATE_DIR/state.json"
  export NPM_HOST_ID=40 BEGET_IP=203.0.113.10 NPM_SSL_REQUEST="$tmp/npm_ssl_request.sh"
  printf '#!/usr/bin/env bash\nexit 0\n' > "$tmp/npm_ssl_request.sh"
  chmod +x "$tmp/npm_ssl_request.sh"
  run_guard
  [ "$(grep -c 'ssl request rc=' "$tmp/guard.log")" = 1 ] && \
    [ "$(grep -c ' le rc=' "$tmp/guard.log")" = 0 ]
}

case28() { # HTTPS redirect precheck permits the DNS switch
  dns_setup case28
  printf 'HTTP/2 301\nlocation: https://forms.arwox.ru/\n' > "$GUARD_TEST_TMP/precheck.http.hdr"
  printf 'HTTP/2 302\nlocation: https://arwox.ru/#contact\n' > "$GUARD_TEST_TMP/precheck.https.hdr"
  out=$(dns_run apply outage); rc=$?
  [ "$out" = 'switched normal→outage' ] && [ "$rc" = 0 ] && \
    grep -Fxq -- 'forms.arwox.ru:443:203.0.113.10' "$GUARD_TEST_TMP/curl.argv.log" && \
    grep -Fxq -- 'https://forms.arwox.ru/' "$GUARD_TEST_TMP/curl.argv.log"
}

case29() { # bad HTTPS result still refuses the DNS switch
  dns_setup case29
  printf 'HTTP/2 301\nlocation: https://forms.arwox.ru/\n' > "$GUARD_TEST_TMP/precheck.http.hdr"
  printf 'HTTP/2 200\n' > "$GUARD_TEST_TMP/precheck.https.hdr"
  out=$(dns_run apply outage); rc=$?
  printf '%s' "$out" | grep -q '^refused precheck' && [ "$rc" = 3 ] && \
    [ ! -e "$GUARD_TEST_TMP/changeRecords.log" ]
}

case30() { # foreign redirect does not request HTTPS
  dns_setup case30
  printf 'HTTP/2 301\nlocation: https://evil.example/\n' > "$GUARD_TEST_TMP/precheck.http.hdr"
  out=$(dns_run apply outage); rc=$?
  printf '%s' "$out" | grep -q '^refused precheck' && [ "$rc" = 3 ] && \
    ! grep -Fxq -- 'https://forms.arwox.ru/' "$GUARD_TEST_TMP/curl.argv.log"
}

case31() { # two empty gateway DNS results switch to outage with legacy threshold
  local first_pending
  export GUARD_TEST_TMP="$tmp"
  fallback_setup
  export GUARD_GW_HOST=gw.test
  export DNS_SWITCH="$tmp/dns-switch-stub.sh"
  printf '#!/usr/bin/env bash\nprintf "called\\n" >> "$GUARD_TEST_TMP/dns-switch.called"\n' > "$DNS_SWITCH"
  chmod +x "$DNS_SWITCH"
  touch "$tmp/dig.empty"
  printf '{"fallback_mode":"normal","fallback_failures":0,"fallback_successes":0}\n' > "$GUARD_STATE_DIR/state.json"
  rm -f "$tmp/dns-switch.called"
  out=$(bash "$GUARD" 2>&1); rc1=$?
  first_pending=0
  if [ ! -e "$tmp/dns-switch.called" ] &&
     jq -e '.fallback_mode == "normal" and .fallback_failures == 1' "$GUARD_STATE_DIR/state.json" >/dev/null; then
    first_pending=1
  fi
  out2=$(bash "$GUARD" 2>&1); rc2=$?
  if [ "$first_pending" = 1 ] && [ "$rc1" = 0 ] && [ "$rc2" = 0 ] && \
    [ "$(wc -l < "$tmp/dns-switch.called")" = 1 ] && \
    printf '%s\n%s' "$out" "$out2" | grep -c 'check skip dns-empty' | grep -qx 2 && \
    jq -e '.fallback_mode == "outage" and .fallback_failures == 2 and .fallback_successes == 0' "$GUARD_STATE_DIR/state.json" >/dev/null; then
    rm -f "$tmp/dig.empty"
    unset GUARD_GW_HOST DNS_SWITCH
    return 0
  fi
  rm -f "$tmp/dig.empty"
  unset GUARD_GW_HOST DNS_SWITCH
  return 1
}

case32() { # state writes leave valid JSON and no temporary file
  fallback_setup
  printf '5.1\n' > "$tmp/balance"
  run_guard
  ! [ -e "$GUARD_STATE_DIR/state.json.tmp" ] && jq -e . "$GUARD_STATE_DIR/state.json" >/dev/null
}

case33() { # TLS certificate request is rate-limited for outage
  export GUARD_TEST_TMP="$tmp"
  snapshot_setup
  printf '{"fallback_mode":"outage"}\n' > "$GUARD_STATE_DIR/state.json"
  export NPM_HOST_ID=40 BEGET_IP=203.0.113.10 NPM_SSL_REQUEST="$tmp/npm_ssl_request.sh"
  printf '#!/usr/bin/env bash\nprintf "called\\n" >> "$GUARD_TEST_TMP/npm.calls"\nexit 1\n' > "$NPM_SSL_REQUEST"
  chmod +x "$NPM_SSL_REQUEST"
  rm -f "$tmp/npm.calls"
  run_guard; run_guard
  [ "$(wc -l < "$tmp/npm.calls")" = 1 ]
}

case34() { # flapping 000/302 for 60 runs: no DNS switch, no telegram
  local i
  snapshot_setup
  export GUARD_FALL_N=3 GUARD_RISE_N=15
  export FALLBACK_PAGE_ID= FALLBACK_BLOCK_ID= DNS_SWITCH="$tmp/dns-flap.sh"
  printf '#!/usr/bin/env bash\nprintf called >> "$GUARD_TEST_TMP/dns-flap.calls"\n' > "$DNS_SWITCH"
  chmod +x "$DNS_SWITCH"
  rm -f "$tmp/dns-flap.calls"
  for i in $(seq 60); do
    if [ $((i % 2)) = 0 ]; then printf '000\n' > "$tmp/forms.code"; else printf '302\n' > "$tmp/forms.code"; fi
    run_guard
  done
  [ ! -e "$tmp/dns-flap.calls" ] && [ ! -s "$tmp/sent.log" ]
}

dns_success_setup() {
  export FALLBACK_PAGE_ID= FALLBACK_BLOCK_ID= DNS_SWITCH="$tmp/dns-ok.sh"
  printf '#!/usr/bin/env bash\nprintf "%%s %%s\\n" "$1" "$2" >> "$GUARD_TEST_TMP/dns-switch.calls"\n' > "$DNS_SWITCH"
  chmod +x "$DNS_SWITCH"
  : > "$tmp/dns-switch.calls"
}

case35() { # three hard failures: one DNS switch to outage, one message
  snapshot_setup
  export GUARD_FALL_N=3 GUARD_RISE_N=15
  dns_success_setup
  run_guard; run_guard; run_guard
  [ "$(grep -c '^apply outage$' "$tmp/dns-switch.calls")" = 1 ] && \
    [ "$(grep -c 'сбой основного канала' "$tmp/sent.log")" = 1 ] && \
    [ "$(wc -l < "$tmp/sent.log")" = 1 ] && \
    jq -e '.fallback_mode == "outage"' "$tmp/state/state.json" >/dev/null
}

case36() { # return after 15 consecutive successes; failure at 10th resets the count
  local i
  snapshot_setup
  export GUARD_FALL_N=3 GUARD_RISE_N=15
  dns_success_setup
  run_guard; run_guard; run_guard
  [ "$(grep -c '^apply outage$' "$tmp/dns-switch.calls")" = 1 ] && \
    jq -e '.fallback_mode == "outage"' "$tmp/state/state.json" >/dev/null || return 1
  jq '.form_outage_started_at=100000 | .form_outage_notified_at=100000' \
    "$tmp/state/state.json" > "$tmp/state/state.json.tmp" || return 1
  mv -f "$tmp/state/state.json.tmp" "$tmp/state/state.json" || return 1
  printf '302\n' > "$tmp/forms.code"
  run_guard
  jq -e '.fallback_successes == 1 and (has("form_outage_started_at") | not) and (has("form_outage_notified_at") | not)' \
    "$tmp/state/state.json" >/dev/null || return 1
  for i in $(seq 13); do run_guard; done
  [ "$(grep -c '^apply normal$' "$tmp/dns-switch.calls" || true)" = 0 ] && \
    jq -e '.fallback_mode == "outage" and .fallback_successes == 14' "$tmp/state/state.json" >/dev/null || return 1
  run_guard
  [ "$(grep -c '^apply normal$' "$tmp/dns-switch.calls")" = 1 ] && \
    [ "$(grep -c 'стабилен 15 мин' "$tmp/sent.log")" = 1 ] && \
    [ "$(wc -l < "$tmp/sent.log")" = 2 ] && \
    jq -e '.fallback_mode == "normal"' "$tmp/state/state.json" >/dev/null || return 1
  printf '000\n' > "$tmp/forms.code"
  run_guard; run_guard; run_guard
  [ "$(grep -c '^apply outage$' "$tmp/dns-switch.calls")" = 2 ] && \
    jq -e '.fallback_mode == "outage"' "$tmp/state/state.json" >/dev/null || return 1
  printf '302\n' > "$tmp/forms.code"
  for i in $(seq 9); do run_guard; done
  jq -e '.fallback_mode == "outage" and .fallback_successes == 9' "$tmp/state/state.json" >/dev/null || return 1
  printf '000\n' > "$tmp/forms.code"
  run_guard
  [ "$(grep -c '^apply normal$' "$tmp/dns-switch.calls")" = 1 ] && \
    jq -e '.fallback_successes == 0 and .fallback_failures == 1' "$tmp/state/state.json" >/dev/null
}

case37() { # 404 counts as failure
  snapshot_setup
  export GUARD_FALL_N=3 GUARD_RISE_N=15
  dns_success_setup
  printf '404\n' > "$tmp/forms.code"
  run_guard; run_guard; run_guard
  [ "$(grep -c '^apply outage$' "$tmp/dns-switch.calls")" = 1 ] && \
    [ "$(wc -l < "$tmp/sent.log")" = 1 ] && \
    ! grep -q 'отвечает <404>' "$tmp/sent.log" && \
    jq -e '.fallback_mode == "outage"' "$tmp/state/state.json" >/dev/null
}

case38() { # GUARD_NOTIFY=0: switch happens, telegram not called
  snapshot_setup
  export GUARD_FALL_N=3 GUARD_RISE_N=15
  export GUARD_NOTIFY=0
  export TG_BOT_TOKEN=t TG_CHAT_ID=c
  : > "$tmp/telegram.calls"
  dns_success_setup
  run_guard; run_guard; run_guard
  [ "$(grep -c '^apply outage$' "$tmp/dns-switch.calls")" = 1 ] && \
    [ ! -s "$tmp/sent.log" ] && \
    [ ! -s "$tmp/telegram.calls" ] && \
    jq -e '.fallback_mode == "outage"' "$tmp/state/state.json" >/dev/null
}

case39() { # three empty gateway DNS results switch to outage once
  local i rc=0
  snapshot_setup
  export GUARD_FALL_N=3 GUARD_RISE_N=15
  export GUARD_GW_HOST=gw.test FALLBACK_PAGE_ID= FALLBACK_BLOCK_ID= DNS_SWITCH="$tmp/dns-empty.sh"
  printf '#!/usr/bin/env bash\nprintf "%%s\\n" "$1 $2" >> "$GUARD_TEST_TMP/dns-empty.calls"\n' > "$DNS_SWITCH"
  chmod +x "$DNS_SWITCH"
  : > "$tmp/dns-empty.calls"
  touch "$tmp/dig.empty"
  for i in 1 2 3; do run_guard || rc=1; done
  rm -f "$tmp/dig.empty"
  unset GUARD_GW_HOST DNS_SWITCH
  [ "$rc" = 0 ] && [ "$(grep -c '^apply outage$' "$tmp/dns-empty.calls")" = 1 ] && \
    jq -e '.fallback_mode == "outage" and .fallback_failures == 3' "$tmp/state/state.json" >/dev/null
}

case40() { # hung yc call: guard kills it via timeout and counts one fallback failure
  snapshot_setup
  export GUARD_FALL_N=3 GUARD_RISE_N=15
  dns_success_setup
  touch "$tmp/yc-hang"
  printf '403\n' > "$tmp/forms.code"
  printf 'form is stopped and cannot be used\n' > "$tmp/forms.body"
  printf 'STOPPED\n' > "$tmp/gw.status"
  export GUARD_YC_TIMEOUT=1
  timeout 20 bash "$GUARD" > "$tmp/guard.log" 2>&1
  local rc=$?
  rm -f "$tmp/yc-hang"
  unset GUARD_YC_TIMEOUT
  [ "$rc" != 124 ] && \
    grep -q 'resume failed' "$tmp/guard.log" && \
    jq -e '.fallback_failures == 1' "$tmp/state/state.json" >/dev/null
}

cls_setup() { snapshot_setup; export GUARD_FALL_N=3 GUARD_RISE_N=15; unset GUARD_NOTIFY; dns_success_setup; }

case41() { # rule 1: no network to Yandex at all classifies network
  cls_setup
  printf '000\n' > "$tmp/net.code"
  run_guard; run_guard; run_guard
  [ "$(jq -r '.incident_class' "$tmp/state/state.json")" = network ] && \
    grep -q 'class=network' "$tmp/guard.log" && \
    grep -q 'у сервера нет сети до Yandex Cloud' "$tmp/sent.log" && \
    [ "$(grep -c '^apply outage$' "$tmp/dns-switch.calls")" = 1 ]
}

case42() { # outage then recovery: exactly two messages with class details
  cls_setup
  run_guard; run_guard; run_guard
  [ "$(wc -l < "$tmp/sent.log")" = 1 ] || return 1
  grep -q 'yandex_service' "$tmp/sent.log" && grep -q 'ждём восстановления' "$tmp/sent.log" || return 1
  printf '302\n' > "$tmp/forms.code"
  printf 'ok\n' > "$tmp/forms.body"
  for i in $(seq 15); do run_guard; done
  [ "$(wc -l < "$tmp/sent.log")" = 2 ] && \
    grep -q 'восстановлено.*Yandex API Gateway' "$tmp/sent.log" && \
    grep -q 'recovered class=yandex_service' "$tmp/guard.log" && \
    jq -e '(has("incident_class") or has("outage_class")) | not' "$tmp/state/state.json" >/dev/null
}

case43() { # rule 2: stopped gateway beats service classification
  cls_setup
  printf '403\n' > "$tmp/forms.code"
  printf 'form is stopped and cannot be used\n' > "$tmp/forms.body"
  printf 'STOPPED\n' > "$tmp/gw.status"
  touch "$tmp/resume.fail"
  run_guard; run_guard; run_guard
  [ "$(jq -r '.incident_class' "$tmp/state/state.json")" = gw_stopped ] && \
    grep -q 'class=gw_stopped' "$tmp/guard.log" && \
    grep -q 'шлюз форм остановлен в Yandex Cloud' "$tmp/sent.log"
}

case44() { # rule 3: billing state from the previous run classifies billing
  cls_setup
  printf '5.1\n' > "$tmp/balance"
  run_guard; run_guard; run_guard
  [ "$(jq -r '.incident_class' "$tmp/state/state.json")" = billing ] && \
    grep -q 'class=billing' "$tmp/guard.log" && \
    grep -q 'баланс Yandex Cloud 5.1 ₽ или аккаунт не активен' "$tmp/sent.log"
}

case45() { # rule 4: gateway dead while the rest of Yandex Cloud answers
  cls_setup
  run_guard; run_guard; run_guard
  [ "$(jq -r '.incident_class' "$tmp/state/state.json")" = yandex_service ] && \
    grep -q 'class=yandex_service' "$tmp/guard.log" && \
    grep -q 'Yandex API Gateway недоступен, остальной Yandex Cloud отвечает' "$tmp/sent.log"
}

case46() { # rule 5: guard lost IAM access classifies access on non-anomaly failures
  cls_setup
  touch "$tmp/iam.fail"
  printf '404\n' > "$tmp/forms.code"
  printf 'not found\n' > "$tmp/forms.body"
  run_guard; run_guard; run_guard
  [ "$(jq -r '.incident_class' "$tmp/state/state.json")" = access ] && \
    grep -q 'class=access' "$tmp/guard.log" && \
    grep -q 'нет доступа сторожа к Yandex Cloud (IAM/биллинг)' "$tmp/sent.log"
}

case47() { # rule 6: nothing matched → unknown with the HTTP code
  cls_setup
  printf '404\n' > "$tmp/forms.code"
  printf 'not found\n' > "$tmp/forms.body"
  run_guard; run_guard; run_guard
  [ "$(jq -r '.incident_class' "$tmp/state/state.json")" = unknown ] && \
    grep -q 'class=unknown' "$tmp/guard.log" && \
    grep -q 'причина не определена (код 404)' "$tmp/sent.log"
}

case48() { # starting in outage without outage_class still recovers once
  cls_setup
  printf '{"fallback_mode":"outage","fallback_failures":3}\n' > "$tmp/state/state.json"
  run_guard; run_guard; run_guard
  [ ! -s "$tmp/sent.log" ] || return 1
  printf '302\n' > "$tmp/forms.code"
  printf 'ok\n' > "$tmp/forms.body"
  for i in $(seq 15); do run_guard; done
  [ "$(wc -l < "$tmp/sent.log")" = 1 ] && \
    grep -q 'восстановлено' "$tmp/sent.log" && \
    grep -q 'Yandex API Gateway заработал' "$tmp/sent.log" && \
    grep -q 'recovered class=' "$tmp/guard.log"
}

case49() { # drill state file present: fallback_outage text is prefixed with УЧЕНИЯ:
  snapshot_setup
  export GUARD_FALL_N=3 GUARD_RISE_N=15
  dns_success_setup
  export GUARD_DRILL_STATE="$tmp/drill/demo.json"
  mkdir -p "$tmp/drill"
  printf '{"started":true,"at":100000}\n' > "$GUARD_DRILL_STATE"
  run_guard; run_guard; run_guard
  [ "$(grep -c '^УЧЕНИЯ: ' "$tmp/sent.log")" = 1 ] && \
    [ "$(wc -l < "$tmp/sent.log")" = 1 ] && \
    grep -q '^УЧЕНИЯ: .*сбой основного канала' "$tmp/sent.log" && \
    ! grep -q '^УЧЕНИЯ: УЧЕНИЯ: ' "$tmp/sent.log"
}

case50() { # drill state file absent: fallback_outage text unchanged
  snapshot_setup
  export GUARD_FALL_N=3 GUARD_RISE_N=15
  dns_success_setup
  export GUARD_DRILL_STATE="$tmp/drill/absent.json"
  rm -f "$GUARD_DRILL_STATE"
  run_guard; run_guard; run_guard
  [ "$(grep -c 'сбой основного канала' "$tmp/sent.log")" = 1 ] && \
    [ "$(wc -l < "$tmp/sent.log")" = 1 ] && \
    ! grep -q '^УЧЕНИЯ: ' "$tmp/sent.log"
}

captcha_setup() {
  export GUARD_TEST_TMP="$tmp" GUARD_STATE_DIR="$tmp/state"
  unset GUARD_GW_HOST
  export GUARD_FALL_N=3 GUARD_RISE_N=15
  export GUARD_DRILL_STATE="$tmp/drill/absent.json"
  mkdir -p "$tmp/drill"
  rm -f "$tmp/drill/absent.json"
  printf '100000\n' > "$tmp/clock"
  printf '302\n' > "$tmp/forms.code"
  printf 'ok\n' > "$tmp/forms.body"
  printf '100\n' > "$tmp/balance"
  rm -f "$tmp/sent.log" "$tmp/state/state.json" "$tmp/state/captcha-check.stamp" \
    "$tmp/yc-logging-fail" "$tmp/yc-logging-unavailable" "$tmp/yc-logging.calls" "$tmp/yc-logging-count" "$tmp/reserve.log"
  export GUARD_RESERVE_LOG="$tmp/reserve.log"
}

captcha_reserve_log() { # recent_count old_count; epochs are derived from the fake clock,
  local now recent old i recent_n old_n # written as +0300 wall time to match the pm2 reserve log
  now=$(cat "$tmp/clock" 2>/dev/null)
  case "$now" in ''|*[!0-9]*) return 1 ;; esac
  recent=$(date -u -d "@$((now + 1 + 10800))" '+%Y-%m-%dT%H:%M:%S')
  old=$(date -u -d "@$((now - 7200 + 10800))" '+%Y-%m-%dT%H:%M:%S')
  recent_n="${1:-0}"; old_n="${2:-0}"
  case "$recent_n" in ''|*[!0-9]*) recent_n=0 ;; esac
  case "$old_n" in ''|*[!0-9]*) old_n=0 ;; esac
  : > "$tmp/reserve.log"
  for i in $(seq "$recent_n"); do printf '%s: captcha=unavailable\n' "$recent" >> "$tmp/reserve.log"; done
  for i in $(seq "$old_n"); do printf '%s: captcha=unavailable\n' "$old" >> "$tmp/reserve.log"; done
}

case51() { # sum 6 (2 recent reserve + 4 cloud): exactly one captcha_unverified alert, counts only
  captcha_setup
  captcha_reserve_log 2 1
  printf '4\n' > "$tmp/yc-logging-count"
  run_guard
  [ "$(grep -c 'без проверки капчи' "$tmp/sent.log")" = 1 ] && \
    grep -q 'Заявок без проверки капчи за час: 6 (> 5)' "$tmp/sent.log" && \
    grep -q 'captcha_unverified count=6' "$tmp/guard.log"
}

case52() { # sum 5 (2 recent reserve + 3 cloud, one 2h-old line excluded): no alert; counting the old line would fire
  captcha_setup
  captcha_reserve_log 2 1
  printf '3\n' > "$tmp/yc-logging-count"
  run_guard
  [ ! -s "$tmp/sent.log" ] && [ "$(wc -l < "$tmp/reserve.log")" = 3 ]
}

case53() { # second tick within the hour does not read the cloud log again
  captcha_setup
  captcha_reserve_log 2 0
  printf '4\n' > "$tmp/yc-logging-count"
  run_guard
  printf '103599\n' > "$tmp/clock"
  printf '9\n' > "$tmp/yc-logging-count"
  run_guard
  [ "$(wc -l < "$tmp/yc-logging.calls")" = 1 ] && \
    [ "$(grep -c 'без проверки капчи' "$tmp/sent.log")" = 1 ]
}

case54() { # yc logging read fails: tick still exits 0; 3 recent reserve lines (3 old excluded) stay under threshold
  captcha_setup
  captcha_reserve_log 3 3
  touch "$tmp/yc-logging-fail"
  : > "$tmp/yc-logging.calls"
  run_guard
  local rc=$?
  [ "$rc" = 0 ] && ! [ -s "$tmp/sent.log" ] && \
    grep -q 'captcha cloud log read failed' "$tmp/guard.log"
}

sent_has() { grep -Fq -- "$1" "$tmp/sent.log" 2>/dev/null; }
state_is() { jq -e "$1" "$tmp/state/state.json" >/dev/null 2>&1; }

ext_setup() { # U1 cases: shared setup, healthy forms, fixtures of earlier cases removed
  snapshot_setup
  export GUARD_FALL_N=3 GUARD_RISE_N=15
  unset GUARD_NOTIFY
  export TG_BOT_TOKEN=test TG_CHAT_ID=1
  dns_success_setup
  export GUARD_RESERVE_LOG="$tmp/reserve.log" GUARD_DRILL_STATE="$tmp/drill/absent.json"
  rm -f "$tmp/fn.status" "$tmp/fn.fail" "$tmp/getme.fail" "$tmp/billing.fail" \
    "$tmp/reserve.keys" "$tmp/reserve.fail" "$tmp/reserve.calls" "$tmp/reserve.log" \
    "$tmp/yc-logging-fail" "$tmp/yc-logging-unavailable" "$tmp/yc-logging-count" "$tmp/yc-logging.calls" \
    "$tmp/state/captcha-check.stamp" "$tmp/yc-hang"
  printf '100000\n' > "$tmp/clock"
  printf '302\n' > "$tmp/forms.code"
  printf 'ok\n' > "$tmp/forms.body"
  printf 'ACTIVE\n' > "$tmp/gw.status"
  printf '100\n' > "$tmp/balance"
}

gw_stopped_setup() { # stopped gateway whose resume fails on every run
  ext_setup
  printf '403\n' > "$tmp/forms.code"
  printf 'form is stopped and cannot be used\n' > "$tmp/forms.body"
  printf 'STOPPED\n' > "$tmp/gw.status"
  touch "$tmp/resume.fail"
}

case55() { # stopped gateway with stopped function is a cascade: tier, state and text
  gw_stopped_setup
  printf 'STOPPED\n' > "$tmp/fn.status"
  run_guard; run_guard; run_guard
  state_is '.incident_tier == "архитектура" and .incident_cascade == 1 and .incident_class == "gw_stopped"' && \
    grep -q 'class=gw_stopped tier=архитектура cascade=1' "$tmp/guard.log" && \
    sent_has 'класс: архитектура, каскад: шлюз+функция'
}

case56() { # stopped gateway with healthy function is not a cascade
  gw_stopped_setup
  printf 'ACTIVE\n' > "$tmp/fn.status"
  run_guard; run_guard; run_guard
  state_is '.incident_cascade == 0' && \
    grep -q 'cascade=0' "$tmp/guard.log" && \
    sent_has 'класс: архитектура, заявки' && \
    ! sent_has 'каскад'
}

case57() { # unreadable function status counts as cascade and is logged
  gw_stopped_setup
  touch "$tmp/fn.fail"
  run_guard; run_guard; run_guard
  state_is '.incident_cascade == 1' && \
    grep -q 'function status read failed' "$tmp/guard.log" && \
    sent_has 'каскад: шлюз+функция'
}

case58() { # outage start recorded before the first recovered tick still gives the duration in the recovery text
  ext_setup
  printf '000\n' > "$tmp/forms.code"
  printf 'unavailable\n' > "$tmp/forms.body"
  run_guard; run_guard; run_guard
  printf '103600\n' > "$tmp/clock"
  printf '302\n' > "$tmp/forms.code"
  printf 'ok\n' > "$tmp/forms.body"
  for i in $(seq 15); do run_guard; done
  sent_has 'вернулись на основной (сбой: yandex_service, длительность 1ч 0м)'
}

case59() { # first run records the newest reserve key and sends nothing
  ext_setup
  printf 'reserve/req-0001\nreserve/req-0002\n' > "$tmp/reserve.keys"
  run_guard
  state_is '.last_reserve_key == "reserve/req-0002"' && \
    ! sent_has 'Заявок в резерве' && \
    ! grep -Fq -- '--start-after' "$tmp/reserve.calls" 2>/dev/null
}

case60() { # second run lists after the recorded cursor and alerts once with the count
  ext_setup
  printf 'reserve/req-0001\nreserve/req-0002\n' > "$tmp/reserve.keys"
  run_guard
  printf 'reserve/req-0001\nreserve/req-0002\nreserve/req-0003\nreserve/req-0004\n' > "$tmp/reserve.keys"
  run_guard
  state_is '.last_reserve_key == "reserve/req-0004"' && \
    grep -Fq -- '--start-after reserve/req-0002' "$tmp/reserve.calls" && \
    sent_has 'Заявок в резерве (Bitrix24 не принял): 2. Ключи в бакете arwox-forms-reserve-b1g7fof71b9b632o3a4r/reserve/.' && \
    [ "$(grep -c 'Заявок в резерве' "$tmp/sent.log" 2>/dev/null)" = 1 ]
}

case61() { # failing list: tick exits 0, cursor kept, no alert
  ext_setup
  printf 'reserve/req-0001\n' > "$tmp/reserve.keys"
  run_guard
  printf 'reserve/req-0001\nreserve/req-0002\n' > "$tmp/reserve.keys"
  touch "$tmp/reserve.fail"
  run_guard; rc=$?
  [ "$rc" = 0 ] && state_is '.last_reserve_key == "reserve/req-0001"' && \
    ! sent_has 'Заявок в резерве' && \
    grep -q 'reserve list failed' "$tmp/guard.log"
}

case62() { # three hourly cloud read failures alert once; a success resets the streak
  ext_setup
  touch "$tmp/yc-logging-fail"
  run_guard
  printf '103600\n' > "$tmp/clock"; run_guard
  printf '107200\n' > "$tmp/clock"; run_guard
  printf '110800\n' > "$tmp/clock"; run_guard
  state_is '.cloud_read_fail == 4' && \
    [ "$(grep -c 'не читается' "$tmp/sent.log" 2>/dev/null)" = 1 ] && \
    sent_has 'Яндекс-журнал функции не читается 3 раз подряд' || return 1
  rm -f "$tmp/yc-logging-fail"
  printf '114400\n' > "$tmp/clock"; run_guard
  state_is '.cloud_read_fail == 0'
}

case63() { # non-ok getMe logs bot unknown, never the literal null
  ext_setup
  touch "$tmp/getme.fail"
  run_guard
  grep -q 'bot unknown' "$tmp/guard.log" && ! grep -q 'bot null' "$tmp/guard.log"
}

case64() { # billing that does not answer leaves last_iam_ok false
  ext_setup
  run_guard
  state_is '.last_iam_ok == true' || return 1
  touch "$tmp/billing.fail"
  run_guard
  state_is '.last_iam_ok == false'
}

case65() { # reserve alerts are not debounced: second and third batches inside the window each alert
  ext_setup
  printf 'reserve/req-0001\nreserve/req-0002\n' > "$tmp/reserve.keys"
  run_guard
  printf 'reserve/req-0001\nreserve/req-0002\nreserve/req-0003\nreserve/req-0004\n' > "$tmp/reserve.keys"
  run_guard
  printf 'reserve/req-0001\nreserve/req-0002\nreserve/req-0003\nreserve/req-0004\nreserve/req-0005\nreserve/req-0006\n' > "$tmp/reserve.keys"
  run_guard
  state_is '.last_reserve_key == "reserve/req-0006"' && \
    [ "$(grep -c 'Заявок в резерве' "$tmp/sent.log" 2>/dev/null)" = 2 ]
}

case66() { # provider outage: ten hourly runs with Unavailable read errors send one outage message, no failed-read messages
  local i
  ext_setup
  touch "$tmp/yc-logging-unavailable"
  for i in $(seq 0 9); do
    printf '%s\n' $((100000 + i * 3600)) > "$tmp/clock"
    run_guard
  done
  [ "$(grep -c 'Yandex Cloud Logging недоступен' "$tmp/sent.log" 2>/dev/null)" = 1 ] && \
    ! sent_has 'не читается'
}

case67() { # outage then stub removed: one recovered message, both flags cleared
  local i
  ext_setup
  touch "$tmp/yc-logging-unavailable"
  for i in $(seq 0 9); do
    printf '%s\n' $((100000 + i * 3600)) > "$tmp/clock"
    run_guard
  done
  rm -f "$tmp/yc-logging-unavailable"
  printf '%s\n' $((100000 + 10 * 3600)) > "$tmp/clock"
  run_guard
  [ "$(grep -c 'снова читается' "$tmp/sent.log" 2>/dev/null)" = 1 ] && \
    state_is '.cloud_read_fail == 0 and .cloud_outage_notified == 0'
}

case68() { # no outage before: successful cloud read sends no recovered message
  ext_setup
  run_guard
  run_guard
  [ -s "$tmp/yc-logging.calls" ] && ! sent_has 'снова читается'
}

for i in {1..68}; do
  if "case$i"; then PASS=$((PASS+1)); else FAIL=$((FAIL+1)); printf 'FAIL case %s\n' "$i"; fi
done
if [ "$FAIL" = 0 ]; then
  printf 'PASS %d/68\n' "$PASS"
  exit 0
else
  printf 'FAIL %d/68 (PASS %d/68)\n' "$FAIL" "$PASS"
  exit 1
fi
