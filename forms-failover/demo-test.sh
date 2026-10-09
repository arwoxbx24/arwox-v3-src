#!/usr/bin/env bash
# Black-box contract tests for demo.sh. All network-facing commands are stubs.
set -uo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
DEMO="$ROOT/demo.sh"
TMP=$(mktemp -d /tmp/forms-demo-test.XXXXXX)
trap 'rm -rf "$TMP"' EXIT

setup() {
  rm -rf "$TMP/run"
  rm -f "$TMP/guard-written" "$TMP/error-written"
  mkdir -p "$TMP/run/bin" "$TMP/run/state"
  cp "$DEMO" "$TMP/run/demo.sh"
  : > "$TMP/guard.out"
  : > "$TMP/guard.err"
  printf '100000\n' > "$TMP/clock"
  printf '%s\n' "${1:-A}" > "$TMP/dns-mode"
  printf '0\n' > "$TMP/cert-failures"

  cat > "$TMP/run/bin/date" <<'EOF'
#!/usr/bin/env bash
if [ "${1:-}" = '+%s' ]; then cat "$DEMO_TMP/clock"; else exec /bin/date "$@"; fi
EOF
  cat > "$TMP/run/bin/dig" <<'EOF'
#!/usr/bin/env bash
case "$*" in
  *d5dn462s09a9dpofvl2d*) printf '203.0.113.77\n' ;;
  *) case "$(cat "$DEMO_TMP/dns-mode")" in CNAME) printf '%s\n' "$DNS_GW_CNAME" ;; *) printf '%s\n' "$BEGET_IP" ;; esac ;;
esac
EOF
  cat > "$TMP/run/bin/flock" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
  cat > "$TMP/run/bin/sleep" <<'EOF'
#!/usr/bin/env bash
if [ ! -e "$DEMO_TMP/guard-written" ]; then
  printf 'check code=000\n' >> "$GUARD_LOG"
  : > "$DEMO_TMP/guard-written"
fi
if [ -n "${DEMO_WRITE_ERROR:-}" ] && [ ! -e "$DEMO_TMP/error-written" ]; then
  printf '%s\n' "$DEMO_WRITE_ERROR" >> "$GUARD_ERR"
  : > "$DEMO_TMP/error-written"
fi
if [ "${DEMO_SELF_INTERRUPT:-}" = 1 ]; then kill -INT "$PPID"; exit 0; fi
printf '%s\n' "$(( $(cat "$DEMO_TMP/clock") + ${1:-0} ))" > "$DEMO_TMP/clock"
EOF
  cat > "$TMP/run/bin/yc" <<'EOF'
#!/usr/bin/env bash
case "$*" in
  *'api-gateway get'*) printf '%s\n' '{"attached_domains":[{"domain":"forms-test.arwox.ru","domain_id":"domain-1"}]}' ;;
  *'api-gateway remove-domain'*) : ;;
  *) exit 1 ;;
esac
EOF
  cat > "$TMP/run/bin/curl" <<'EOF'
#!/usr/bin/env bash
out= headers= method=GET resolve= url= prev= data=
for arg in "$@"; do
  if [ -n "$prev" ]; then
    case "$prev" in -o) out=$arg ;; -D) headers=$arg ;; -X) method=$arg ;; --resolve) resolve=$arg ;; data) data=$arg ;; esac
    prev=; continue
  fi
  case "$arg" in -o|-D|-X|--resolve|-w|--max-time) prev=$arg ;; -d) prev=data ;; -s|-sS) ;; http://*|https://*) url=$arg ;; esac
done
if [ "$method" = POST ]; then
  [ -z "$data" ] || printf '%s\n' "$data" > "$DEMO_TMP/post-body"
  [ -z "$out" ] || printf '%s\n' "${CURL_POST_BODY:-<script src=\"smartcaptcha.yandexcloud.net/captcha.js\"></script>}" > "$out"
  if [ -n "$headers" ]; then
    : > "$headers"
    [ -z "${CURL_POST_LOCATION:-}" ] || printf 'Location: %s\r\n' "$CURL_POST_LOCATION" >> "$headers"
  fi
  printf '%s 0 203.0.113.10\n' "${CURL_POST_CODE:-200}"
  exit 0
fi
case "$resolve" in *":443:$BEGET_IP")
  left=$(cat "$DEMO_TMP/cert-failures")
  if [ "$left" -gt 0 ]; then printf '%s\n' "$((left - 1))" > "$DEMO_TMP/cert-failures"; exit 1; fi
  ;;
esac
printf '200\n'
EOF
  cat > "$TMP/run/dns-switch.sh" <<'EOF'
#!/usr/bin/env bash
case "${1:-}" in
  status) [ "${BEGET_IP:-}" = 203.0.113.10 ] || exit 4; printf 'outage\n' ;;
  apply) printf 'CNAME\n' > "$DEMO_TMP/dns-mode"; printf 'switched outage→normal\n' ;;
  *) exit 1 ;;
esac
EOF
  chmod +x "$TMP/run/bin/"* "$TMP/run/dns-switch.sh"
}

run_demo() {
  env PATH="$TMP/run/bin:$PATH" DEMO_TMP="$TMP" \
    GUARD_LOG="$TMP/guard.out" GUARD_ERR="$TMP/guard.err" \
    BEGET_IP=203.0.113.10 DNS_GW_CNAME=d5dn462s09a9dpofvl2d.6brbn2wz.apigw.yandexcloud.net \
    bash "$TMP/run/demo.sh" "$@"
}

case1() { # repeated stage-4 polls print one unchanged progress line
  setup A; printf '2\n' > "$TMP/cert-failures"
  out=$(run_demo simulate 2>"$TMP/err"); rc=$?
  [ "$rc" = 0 ] && [ "$(grep -c 'Этап 4/5: Сертификат на резерве готов ⏳' <<< "$out")" = 1 ]
}
case2() { # a ready certificate announces the manual testing point
  setup A
  out=$(run_demo simulate 2>"$TMP/err"); rc=$?
  [ "$rc" = 0 ] && grep -Fq '🟢 МОЖНО ТЕСТИРОВАТЬ: откройте форму https://forms-test.arwox.ru/' <<< "$out"
}
case3() { # a fresh guard crash stops immediately
  setup A
  out=$(DEMO_WRITE_ERROR='worker: line 205: result: unbound variable' run_demo simulate 2>"$TMP/err"); rc=$?
  [ "$rc" -ne 0 ] && grep -Fq 'worker: line 205: result: unbound variable' "$TMP/err"
}
case4() { # unrelated stderr does not stop the test
  setup A
  out=$(DEMO_WRITE_ERROR='ordinary stderr line' run_demo simulate 2>"$TMP/err"); rc=$?
  [ "$rc" = 0 ] && grep -Fq '🏁 Тест пройден: 5/5' <<< "$out"
}
case5() { # SIGINT reaches the EXIT logger as rc=130
  setup A
  DEMO_SELF_INTERRUPT=1 run_demo simulate >"$TMP/out" 2>"$TMP/err"; rc=$?
  [ "$rc" = 130 ] && grep -Fq 'result rc=130' "$TMP/run/state/demo.log"
}
case6() { # attached domain with stale A record actively restores DNS
  setup A
  out=$(run_demo restore 2>"$TMP/err"); rc=$?
  [ "$rc" = 0 ] && grep -Fq '⚠️ сторож не вернул DNS — возвращено тестом' <<< "$out" && [ "$(cat "$TMP/dns-mode")" = CNAME ]
}
case7() { # attached domain and six CNAME answers is already restored
  setup CNAME
  out=$(run_demo restore 2>"$TMP/err"); rc=$?
  [ "$rc" = 0 ] && grep -Fq '✅ Уже восстановлено' <<< "$out"
}
case8() { # child dns-switch receives BEGET_IP and recognizes outage
  setup A
  out=$(run_demo status 2>"$TMP/err"); rc=$?
  [ "$rc" = 0 ] && grep -Fq 'dns=outage' <<< "$out"
}
case9() { # accepted lead redirects to ok
  setup A
  out=$(CURL_POST_CODE=302 CURL_POST_LOCATION='https://arwox.ru/?ok=1#sent' run_demo simulate 2>"$TMP/err"); rc=$?
  [ "$rc" = 0 ] && grep -Fq '5/5' <<< "$out" && grep -Fq 'лид принят резервом' <<< "$out"
}
case10() { # captcha response remains an accepted reserve check
  setup A
  out=$(run_demo simulate 2>"$TMP/err"); rc=$?
  [ "$rc" = 0 ] && grep -Fq '5/5' <<< "$out" && grep -Fq 'капча включена' <<< "$out"
}
case11() { # consent rejection is not an accepted lead
  setup A
  CURL_POST_CODE=302 CURL_POST_LOCATION='https://arwox.ru/?err=consent#contact' run_demo simulate >"$TMP/out" 2>"$TMP/err"; rc=$?
  [ "$rc" -ne 0 ] && grep -Fq '❌ Этап 5/5' "$TMP/err" || return 1
  setup A
  CURL_POST_CODE=302 CURL_POST_LOCATION='https://arwox.ru/?ok=10#sent' run_demo simulate >"$TMP/out" 2>"$TMP/err"; rc=$?
  [ "$rc" -ne 0 ] && grep -Fq '❌ Этап 5/5' "$TMP/err"
}
case12() { # probe explicitly carries consent
  setup A
  run_demo simulate >"$TMP/out" 2>"$TMP/err" && grep -Fq 'CONSENT=Y' "$TMP/post-body"
}

PASS=0
FAIL=0
for i in {1..12}; do
  if "case$i"; then PASS=$((PASS + 1)); else FAIL=$((FAIL + 1)); printf 'FAIL case %s\n' "$i"; fi
done
if [ "$FAIL" = 0 ]; then printf 'PASS %d/12\n' "$PASS"; else printf 'FAIL %d/12 (PASS %d/12)\n' "$FAIL" "$PASS"; exit 1; fi
