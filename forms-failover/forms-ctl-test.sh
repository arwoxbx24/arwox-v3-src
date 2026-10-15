#!/usr/bin/env bash
# Black-box contract tests for forms-ctl.sh. All network-facing commands are stubs.
set -uo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
DEMO="$ROOT/forms-ctl.sh"
TMP=$(mktemp -d /tmp/forms-demo-test.XXXXXX)
trap 'rm -rf "$TMP"' EXIT

setup() {
  rm -rf "$TMP/run"
  rm -f "$TMP/guard-written" "$TMP/error-written" "$TMP/feed-written" "$TMP/timer-sleep" "$TMP/timer-release" "$TMP/dns-switch.args" "$TMP/post-normal-a-digs" "$TMP/curl-post" "$TMP/telegram-call" "$TMP/npm-args" "$TMP/yc-get-attached" "$TMP/yc-mutated"
  mkdir -p "$TMP/run/bin" "$TMP/run/state"
  cp "$DEMO" "$TMP/run/forms-ctl.sh"
  : > "$TMP/guard.out"
  : > "$TMP/guard.err"
  : > "$TMP/dns-switch.args"
  printf '100000\n' > "$TMP/clock"
  : > "$TMP/telegram-call"
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
  *) post_normal_a_digs=${DEMO_POST_NORMAL_A_DIGS:-0}
     [ -r "$DEMO_TMP/post-normal-a-digs" ] && post_normal_a_digs=$(cat "$DEMO_TMP/post-normal-a-digs")
     if [ "$post_normal_a_digs" -gt 0 ] && grep -Fqx 'apply normal --fqdn forms-test.arwox.ru' "$DEMO_TMP/dns-switch.args"; then
       printf '%s\n' "$((post_normal_a_digs - 1))" > "$DEMO_TMP/post-normal-a-digs"
       printf '%s\n' "$BEGET_IP"
     else
       case "$(cat "$DEMO_TMP/dns-mode")" in CNAME) printf '%s\n' "$DNS_GW_CNAME" ;; E) printf '198.51.100.9\n' ;; *) printf '%s\n' "$BEGET_IP" ;; esac
     fi ;;
esac
EOF
  cat > "$TMP/run/bin/openssl" <<'EOF'
#!/usr/bin/env bash
case "$*" in
  *s_client*) : ;;
  *x509*) [ "${CERT_MISSING:-0}" = 1 ] && exit 1; clock=$(cat "$DEMO_TMP/clock"); printf 'notAfter=%s\n' "$(/bin/date -u -d "@$(( clock + ${CERT_DAYS:-20} * 86400 ))" '+%b %d %H:%M:%S %Y GMT')" ;;
esac
exit 0
EOF
  cat > "$TMP/run/bin/flock" <<'EOF'
#!/usr/bin/env bash
[ "${LOCK_TEST:-}" = 1 ] || exit 0
case "${1:-}" in
  -n) [ ! -e "$DEMO_TMP/lock-held" ] || exit 75; : > "$DEMO_TMP/lock-held" ;;
  -u) rm -f "$DEMO_TMP/lock-held" ;;
esac
exit 0
EOF
  cat > "$TMP/run/bin/sleep" <<'EOF'
#!/usr/bin/env bash
if [ "${DEMO_AUTO_RESTORE:-}" = 1 ] && [ "${AUTO_TIMER_HOLD:-}" = 1 ]; then
  : > "$DEMO_TMP/timer-sleep"
  while [ ! -e "$DEMO_TMP/timer-release" ]; do /bin/sleep 0.1; done
fi
if [ ! -e "$DEMO_TMP/guard-written" ]; then
  printf 'check code=000\n' >> "$GUARD_LOG"
  : > "$DEMO_TMP/guard-written"
fi
if [ -n "${DEMO_WRITE_ERROR:-}" ] && [ ! -e "$DEMO_TMP/error-written" ]; then
  printf '%s\n' "$DEMO_WRITE_ERROR" >> "$GUARD_ERR"
  : > "$DEMO_TMP/error-written"
fi
if [ "${DEMO_SELF_INTERRUPT:-}" = 1 ]; then kill -INT "$PPID"; exit 0; fi
if [ "${DEMO_FEED:-}" = 1 ] && [ "${1:-}" = 2 ] && [ -n "${FEED_LOG_LINES:-}" ] && [ ! -e "$DEMO_TMP/feed-written" ]; then
  printf '%b' "$FEED_LOG_LINES" >> "$BACKUP_LOG"
  : > "$DEMO_TMP/feed-written"
  if [ "${DEMO_RELEASE_TIMER_ON_FEED:-}" = 1 ]; then
    : > "$DEMO_TMP/timer-release"
    for _ in {1..30}; do grep -Fqx 'apply normal --fqdn forms-test.arwox.ru' "$DEMO_TMP/dns-switch.args" && break; /bin/sleep 0.1; done
  fi
fi
if [ "${DEMO_FEED_CLOCK:-}" != 1 ] || { [ "${DEMO_AUTO_RESTORE:-}" != 1 ] && [ "${1:-}" = 2 ]; } || { [ "${DEMO_AUTO_RESTORE:-}" = 1 ] && [ "${1:-}" != 2 ]; }; then
  printf '%s\n' "$(( $(cat "$DEMO_TMP/clock") + ${1:-0} ))" > "$DEMO_TMP/clock"
fi
EOF
  cat > "$TMP/run/bin/yc" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$DEMO_TMP/yc-args"
fqdn=${FORMS_FQDN:-forms-test.arwox.ru}
case "$*" in
  *'api-gateway get'*)
    [ "${DEMO_YC_FAIL:-0}" = 1 ] && exit 124
    if [ "${DEMO_YC_GET_FAIL_AFTER_MUTATION:-0}" = 1 ] && [ -e "$DEMO_TMP/yc-mutated" ]; then exit 1; fi
    attached=${DEMO_YC_GET_ATTACHED:-1}
    [ -r "$DEMO_TMP/yc-get-attached" ] && attached=$(cat "$DEMO_TMP/yc-get-attached")
    if [ "$attached" = 1 ]; then
      printf '{"attached_domains":[{"domain":"%s","domain_id":"%s-id"}]}\n' "$fqdn" "$fqdn"
    else
      printf '{"attached_domains":[]}\n'
    fi ;;
  *'api-gateway remove-domain'*)
    : > "$DEMO_TMP/yc-mutated"
    printf '%s\n' "${DEMO_YC_GET_ATTACHED_AFTER:-1}" > "$DEMO_TMP/yc-get-attached"
    [ "${DEMO_YC_REMOVE_124:-0}" = 1 ] && exit 124
    : ;;
  *'certificate-manager certificate list'*) printf '[{"status":"ISSUED","domains":["%s"],"id":"certificate-1"}]\n' "$fqdn" ;;
  *'api-gateway add-domain'*)
    : > "$DEMO_TMP/yc-mutated"
    printf '%s\n' "${DEMO_YC_GET_ATTACHED_AFTER:-1}" > "$DEMO_TMP/yc-get-attached"
    [ "${DEMO_YC_ADD_124:-0}" = 1 ] && exit 124
    : ;;
  *) exit 1 ;;
esac
EOF
  cat > "$TMP/run/bin/curl" <<'EOF'
#!/usr/bin/env bash
case "$*" in *'-K -'*) printf 'telegram call\n' >> "$DEMO_TMP/telegram-call" ;; esac
out= headers= method=GET resolve= url= prev= data=
for arg in "$@"; do
  if [ -n "$prev" ]; then
    case "$prev" in -o) out=$arg ;; -D) headers=$arg ;; -X) method=$arg ;; --resolve) resolve=$arg ;; data) data=$arg ;; esac
    prev=; continue
  fi
  case "$arg" in -o|-D|-X|--resolve|-w|--max-time) prev=$arg ;; -d) prev=data ;; -s|-sS) ;; http://*|https://*) url=$arg ;; esac
done
if [ "$method" = POST ]; then
  printf 'post resolve=%s url=%s\n' "${resolve:-none}" "$url" >> "$DEMO_TMP/curl-post"
  case "$url" in *smartcaptcha.yandexcloud.net/validate*) printf '%s\n' "${CURL_VALIDATOR_CODE:-200}"; exit 0 ;; esac
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
printf '%s\n' "$*" >> "$DEMO_TMP/dns-switch.args"
case "${1:-}" in
  status) [ "${BEGET_IP:-}" = 203.0.113.10 ] || exit 4; printf 'outage\n' ;;
  apply) printf 'CNAME\n' > "$DEMO_TMP/dns-mode"; printf 'switched outage→normal\n' ;;
  *) exit 1 ;;
esac
EOF
  cat > "$TMP/run/bin/setsid" <<'EOF'
#!/usr/bin/env bash
[ "${RUN_TIMER:-}" = 1 ] || exit 0
printf '%s\n' "$*" > "$DEMO_TMP/timer-command"
exec "$@"
EOF
  cat > "$TMP/npm-ssl-stub.sh" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$DEMO_TMP/npm-args"
exit 0
EOF
  chmod +x "$TMP/run/bin/"* "$TMP/run/dns-switch.sh" "$TMP/npm-ssl-stub.sh"
}

run_demo() {
  if [ "${1:-}" = test ] && [ "${DEMO_FEED:-}" != 1 ]; then set -- "$@" --no-feed; fi
  env PATH="$TMP/run/bin:$PATH" DEMO_TMP="$TMP" \
    GUARD_LOG="$TMP/guard.out" GUARD_ERR="$TMP/guard.err" \
    BACKUP_LOG="${BACKUP_LOG:-}" FEED_LOG_LINES="${FEED_LOG_LINES:-}" AUTO_RESTORE_SEC="${AUTO_RESTORE_SEC:-}" \
    NPM_SSL_SCRIPT="$TMP/npm-ssl-stub.sh" TG_BOT_TOKEN="${TG_BOT_TOKEN:-}" TG_CHAT_ID="${TG_CHAT_ID:-}" \
    BEGET_IP=203.0.113.10 DNS_GW_CNAME=d5dn462s09a9dpofvl2d.6brbn2wz.apigw.yandexcloud.net \
    bash "$TMP/run/forms-ctl.sh" "$@"
}
run_trace() {
  env -u GUARD_LOG -u GUARD_ERR PATH="$TMP/run/bin:$PATH" DEMO_TMP="$TMP" \
    BEGET_IP=203.0.113.10 DNS_GW_CNAME=d5dn462s09a9dpofvl2d.6brbn2wz.apigw.yandexcloud.net \
    bash -x "$TMP/run/forms-ctl.sh" "$@"
}

case1() { # repeated stage-4 polls print one unchanged progress line
  setup A; printf '2\n' > "$TMP/cert-failures"
  out=$(run_demo test 2>"$TMP/err"); rc=$?
  [ "$rc" = 0 ] && [ "$(grep -c 'Этап 4/5: Сертификат на резерве готов ⏳' <<< "$out")" = 1 ]
}
case2() { # a ready certificate announces the manual testing point
  setup A
  out=$(run_demo test 2>"$TMP/err"); rc=$?
  [ "$rc" = 0 ] && grep -Fq '🟢 МОЖНО ТЕСТИРОВАТЬ: откройте форму https://forms-test.arwox.ru/' <<< "$out"
}
case3() { # a fresh guard crash stops immediately
  setup A
  out=$(DEMO_WRITE_ERROR='worker: line 205: result: unbound variable' run_demo test 2>"$TMP/err"); rc=$?
  [ "$rc" -ne 0 ] && grep -Fq 'worker: line 205: result: unbound variable' "$TMP/err"
}
case4() { # unrelated stderr does not stop the test
  setup A
  out=$(DEMO_WRITE_ERROR='ordinary stderr line' run_demo test 2>"$TMP/err"); rc=$?
  [ "$rc" = 0 ] && grep -Fq '🏁 Тест пройден: 5/5' <<< "$out"
}
case5() { # SIGINT reaches the EXIT logger as rc=130
  setup A
  DEMO_SELF_INTERRUPT=1 run_demo test >"$TMP/out" 2>"$TMP/err"; rc=$?
  [ "$rc" = 130 ] && grep -Fq 'result rc=130' "$TMP/run/state/demo.log"
}
case6() { # second restore wait starts after DNS is switched back
  setup A
  printf '{"started":98800}\n' > "$TMP/run/state/demo-forms-test.arwox.ru.json"
  out=$(DEMO_POST_NORMAL_A_DIGS=6 run_demo restore 2>"$TMP/err"); rc=$?
  [ "$rc" = 0 ] && grep -Fq '⚠️ сторож не вернул DNS — возвращено тестом' <<< "$out" && [ "$(cat "$TMP/dns-mode")" = CNAME ]
}
case7() { # attached domain and six CNAME answers is already restored
  setup CNAME
  printf '{"started":98800}\n' > "$TMP/run/state/demo-forms-test.arwox.ru.json"
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
  out=$(CURL_POST_CODE=302 CURL_POST_LOCATION='https://arwox.ru/?ok=1#sent' run_demo test 2>"$TMP/err"); rc=$?
  [ "$rc" = 0 ] && grep -Fq '5/5' <<< "$out" && grep -Fq 'лид принят резервом' <<< "$out"
}
case10() { # captcha response remains an accepted reserve check
  setup A
  out=$(run_demo test 2>"$TMP/err"); rc=$?
  [ "$rc" = 0 ] && grep -Fq '5/5' <<< "$out" && grep -Fq 'капча включена' <<< "$out"
}
case11() { # consent rejection is not an accepted lead
  setup A
  CURL_POST_CODE=302 CURL_POST_LOCATION='https://arwox.ru/?err=consent#contact' run_demo test >"$TMP/out" 2>"$TMP/err"; rc=$?
  [ "$rc" -ne 0 ] && grep -Fq '❌ Этап 5/5' "$TMP/err" || return 1
  setup A
  CURL_POST_CODE=302 CURL_POST_LOCATION='https://arwox.ru/?ok=10#sent' run_demo test >"$TMP/out" 2>"$TMP/err"; rc=$?
  [ "$rc" -ne 0 ] && grep -Fq '❌ Этап 5/5' "$TMP/err"
}
case12() { # probe explicitly carries consent
  setup A
  run_demo test >"$TMP/out" 2>"$TMP/err" && grep -Fq 'CONSENT=Y' "$TMP/post-body"
}
case13() { # owner-facing --prod selects production in either flag position
  setup A
  out=$(run_demo --help 2>&1); rc=$?
  [ "$rc" = 0 ] && grep -Fq 'test' <<< "$out" && grep -Fq 'restore' <<< "$out" && grep -Fq 'status' <<< "$out" || return 1
  run_demo simulate >"$TMP/out" 2>"$TMP/err"; rc=$?
  [ "$rc" = 64 ] || return 1
  run_demo status --prod >"$TMP/out" 2>"$TMP/err" || return 1
  grep -Fqx 'status --fqdn forms.arwox.ru' "$TMP/dns-switch.args" || return 1
  out=$(run_demo test --no-feed --prod 2>"$TMP/err"); rc=$?
  [ "$rc" = 0 ] && grep -Fq -- '--domain-id forms.arwox.ru-id' "$TMP/yc-args" || return 1
  run_demo status >"$TMP/out" 2>"$TMP/err" || return 1
  grep -Fqx 'status --fqdn forms-test.arwox.ru' "$TMP/dns-switch.args" || return 1
  FORMS_FQDN=evil.example run_demo status >"$TMP/out" 2>"$TMP/err"; rc=$?
  [ "$rc" = 2 ] && grep -Fq 'refused' "$TMP/err"
}
case14() { # production test selects production logs and its attached domain
  setup A
  run_trace status --prod >"$TMP/trace-out" 2>"$TMP/trace" || return 1
  grep -Fq 'forms-gw-guard-out.log' "$TMP/trace" && grep -Fq 'forms-gw-guard-error.log' "$TMP/trace" || return 1
  out=$(run_demo test --prod 2>"$TMP/err"); rc=$?
  [ "$rc" = 0 ] && grep -Fq -- '--domain-id forms.arwox.ru-id' "$TMP/yc-args" && grep -Fq 'https://arwox.ru/#contact' <<< "$out"
}
case15() { # detached one-second timer restores DNS
  setup A
  RUN_TIMER=1 AUTO_RESTORE_SEC=1 run_demo test >"$TMP/out" 2>"$TMP/err" || return 1
  grep -Fq 'forms-ctl.sh" restore' "$TMP/timer-command" || return 1
  for _ in {1..30}; do grep -Fqx 'apply normal --fqdn forms-test.arwox.ru' "$TMP/dns-switch.args" && return 0; /bin/sleep 0.1; done
  return 1
}
case16() { # default restore does not touch the production timer
  setup A
  RUN_TIMER=1 AUTO_TIMER_HOLD=1 AUTO_RESTORE_SEC=1 run_demo test --prod >"$TMP/out" 2>"$TMP/err" || return 1
  for _ in {1..30}; do [ -f "$TMP/timer-sleep" ] && break; /bin/sleep 0.1; done
  [ -f "$TMP/run/state/demo-forms.arwox.ru.timer.pid" ] || return 1
  pid=$(cat "$TMP/run/state/demo-forms.arwox.ru.timer.pid")
  run_demo restore >"$TMP/out" 2>"$TMP/err" || return 1
  [ -e "$TMP/run/state/demo-forms.arwox.ru.timer.pid" ] && kill -0 "$pid" 2>/dev/null || return 1
  : > "$TMP/timer-release"
}
case17() { # stage-5 failure still leaves and runs the early auto-restore timer
  setup A
  CURL_POST_CODE=500 RUN_TIMER=1 AUTO_TIMER_HOLD=1 AUTO_RESTORE_SEC=1 run_demo test >"$TMP/out" 2>"$TMP/err"; rc=$?
  [ "$rc" -ne 0 ] || return 1
  for _ in {1..30}; do [ -f "$TMP/run/state/demo-forms-test.arwox.ru.timer.pid" ] && break; /bin/sleep 0.1; done
  [ -s "$TMP/run/state/demo-forms-test.arwox.ru.timer.pid" ] || return 1
  : > "$TMP/timer-release"
  for _ in {1..30}; do grep -Fqx 'apply normal --fqdn forms-test.arwox.ru' "$TMP/dns-switch.args" && return 0; /bin/sleep 0.1; done
  return 1
}
case18() { # feed reports Bitrix24 outcome without request data
  setup A
  : > "$TMP/backup.out"
  lines=$'2026-10-09T15:00:00: forms-backup lead 2026-10-09T12:00:00Z host=forms-test.arwox.ru code=302 result=sent b24=lead:55\n2026-10-09T15:00:01: forms-backup lead 2026-10-09T12:00:01Z host=forms-test.arwox.ru code=302 result=err:consent b24=queue:x.json\n2026-10-09T15:00:02: forms-backup spool-sent spool=x.json b24=lead:56\n2026-10-09T15:00:03: forms-backup lead 2026-10-09T12:00:03Z host=forms-test.arwox.ru code=302 result=sent b24=-\n'
  out=$(DEMO_FEED=1 DEMO_FEED_CLOCK=1 AUTO_RESTORE_SEC=2 BACKUP_LOG="$TMP/backup.out" FEED_LOG_LINES="$lines" run_demo test 2>"$TMP/err"); rc=$?
  [ "$rc" = 0 ] && grep -Fq 'Bitrix24 лид #55' <<< "$out" && grep -Fq 'очередь резерва, дошлётся сам' <<< "$out" && grep -Fq '📬 из очереди: Bitrix24 лид #56' <<< "$out" && grep -Fq 'в Bitrix24 не передана' <<< "$out" && grep -Fq 'В Bitrix24: 2, в очереди: 0' <<< "$out"
}
case19() { # feed accepts the old log format without a pm2 prefix
  setup A
  : > "$TMP/backup.out"
  lines=$'forms-backup lead 2026-10-09T12:00:00Z host=forms-test.arwox.ru code=302 result=sent\nforms-backup lead 2026-10-09T12:00:01Z host=forms-test.arwox.ru code=302 result=err:consent\n'
  out=$(DEMO_FEED=1 DEMO_FEED_CLOCK=1 AUTO_RESTORE_SEC=2 BACKUP_LOG="$TMP/backup.out" FEED_LOG_LINES="$lines" run_demo test 2>"$TMP/err"); rc=$?
  [ "$rc" = 0 ] && grep -Fq 'Заявка №1' <<< "$out" && grep -Fq 'Заявка №2' <<< "$out" && grep -Fq '🏆 Резерв принял 2' <<< "$out"
}
case20() { # timer restores during the feed after the test lock is released
  setup A
  : > "$TMP/backup.out"
  lines=$'2026-10-09T15:00:00: forms-backup lead 2026-10-09T12:00:00Z host=forms-test.arwox.ru code=302 result=sent\n2026-10-09T15:00:01: forms-backup lead 2026-10-09T12:00:01Z host=forms-test.arwox.ru code=302 result=sent\n'
  out=$(DEMO_FEED=1 DEMO_FEED_CLOCK=1 DEMO_RELEASE_TIMER_ON_FEED=1 LOCK_TEST=1 RUN_TIMER=1 AUTO_TIMER_HOLD=1 AUTO_RESTORE_SEC=2 BACKUP_LOG="$TMP/backup.out" FEED_LOG_LINES="$lines" run_demo test 2>"$TMP/err"); rc=$?
  [ "$rc" = 0 ] && grep -Fq '🏆 Резерв принял 2' <<< "$out" || return 1
  for _ in {1..30}; do
    grep -Fqx 'apply normal --fqdn forms-test.arwox.ru' "$TMP/dns-switch.args" && ! grep -Fq 'restore result rc=75' "$TMP/run/state/demo.log" && return 0
    /bin/sleep 0.1
  done
  return 1
}
case21() { # unrelated spool completion is not a queued lead
  setup A
  : > "$TMP/backup.out"
  lines=$'2026-10-09T15:00:00: forms-backup spool-sent spool=other.json b24=lead:77\n'
  out=$(DEMO_FEED=1 DEMO_FEED_CLOCK=1 AUTO_RESTORE_SEC=2 BACKUP_LOG="$TMP/backup.out" FEED_LOG_LINES="$lines" run_demo test 2>"$TMP/err"); rc=$?
  [ "$rc" = 0 ] && ! grep -Fq 'Bitrix24 лид #77' <<< "$out"
}
case22() { # probe healthy validator + captcha page on both routes is green
  setup A
  out=$(run_demo probe 2>"$TMP/err"); rc=$?
  [ "$rc" = 0 ] || return 1
  grep -Eq '^probe rc=0 gate=on gate_main=on cert_days=-?[0-9]+$' <<< "$out" || return 1
  grep -Fq 'resolve=forms-test.arwox.ru:443:203.0.113.10 url=https://forms-test.arwox.ru/' "$TMP/curl-post" || return 1
  grep -Fq 'resolve=none url=https://forms-test.arwox.ru/' "$TMP/curl-post" || return 1
}
case23() { # validator down: gate is skipped and no POST reaches the reserve
  setup A
  out=$(CURL_VALIDATOR_CODE=503 run_demo probe 2>"$TMP/err"); rc=$?
  [ "$rc" = 0 ] || return 1
  grep -Eq '^probe rc=0 gate=skip gate_main=skip cert_days=-?[0-9]+$' <<< "$out" || return 1
  grep -Fq 'url=https://smartcaptcha.yandexcloud.net/validate' "$TMP/curl-post" || return 1
  if grep -Fq 'resolve=forms-test.arwox.ru' "$TMP/curl-post"; then return 1; fi
  return 0
}
case24() { # reserve answers 302: probe fails and Telegram is notified
  setup A
  out=$(CURL_POST_CODE=302 TG_BOT_TOKEN=stub-bot TG_CHAT_ID=stub-chat run_demo probe 2>"$TMP/err"); rc=$?
  [ "$rc" = 1 ] || return 1
  grep -Eq '^probe rc=1 gate=off gate_main=off cert_days=-?[0-9]+$' <<< "$out" || return 1
  grep -Fq 'telegram call' "$TMP/telegram-call" || return 1
}
case25() { # cert-sync renews when the cert is near expiry and DNS points to the reserve
  setup A
  out=$(run_demo cert-sync 2>"$TMP/err"); rc=$?
  [ "$rc" = 0 ] || return 1
  grep -Eq '^cert_sync rc=0 days=-?[0-9]+ action=renewed$' <<< "$out" || return 1
  grep -Fq '{"proxy_host_id":"39"}' "$TMP/npm-args" || return 1
}
case26() { # cert-sync leaves renewal to the guard when DNS is not on the reserve
  setup E
  out=$(run_demo cert-sync 2>"$TMP/err"); rc=$?
  [ "$rc" = 0 ] || return 1
  grep -Eq '^cert_sync rc=0 days=-?[0-9]+ action=none$' <<< "$out" || return 1
  if [ -f "$TMP/npm-args" ]; then return 1; fi
  return 0
}
case27() { # missing certificate fails cert-sync and notifies Telegram
  setup A
  out=$(CERT_MISSING=1 TG_BOT_TOKEN=stub-bot TG_CHAT_ID=stub-chat run_demo cert-sync 2>"$TMP/err"); rc=$?
  [ "$rc" = 1 ] || return 1
  grep -Fq 'cert_sync rc=1 days=-9999 action=none' <<< "$out" || return 1
  grep -Fq 'telegram call' "$TMP/telegram-call" || return 1
}
case28() { # yc hanging past timeout 60 stops the failure test with a probe hint
  setup A
  out=$(DEMO_YC_FAIL=1 run_demo test 2>"$TMP/err"); rc=$?
  [ "$rc" = 1 ] || return 1
  grep -Fq 'Yandex Cloud API не ответил за 60 с — тест сбоя невозможен; состояние резерва: ./forms-ctl.sh probe --prod' "$TMP/err" || return 1
}

case29() { # restore: add-domain hitting the timeout is fine when the domain is already attached
  setup CNAME
  out=$(DEMO_YC_GET_ATTACHED=0 DEMO_YC_GET_ATTACHED_AFTER=1 DEMO_YC_ADD_124=1 run_demo restore 2>"$TMP/err"); rc=$?
  [ "$rc" = 0 ] || return 1
  grep -Fq 'yc-add verified=attached after rc=124' "$TMP/run/state/demo.log"
}
case30() { # restore: add-domain timeout without server-side attach keeps failing
  setup CNAME
  out=$(DEMO_YC_GET_ATTACHED=0 DEMO_YC_GET_ATTACHED_AFTER=0 DEMO_YC_ADD_124=1 run_demo restore 2>"$TMP/err"); rc=$?
  [ "$rc" = 1 ] || return 1
  grep -Fq 'Yandex Cloud API не ответил за 60 с' "$TMP/err"
}
case31() { # test: remove-domain timeout is fine when the domain is already detached
  setup A
  out=$(DEMO_YC_GET_ATTACHED_AFTER=0 DEMO_YC_REMOVE_124=1 run_demo test 2>"$TMP/err"); rc=$?
  [ "$rc" = 0 ] || return 1
  grep -Fq '🏁 Тест пройден: 5/5' <<< "$out"
}
case32() { # probe: cert expiring but DNS not on the reserve is not actionable
  setup E
  out=$(CERT_DAYS=5 run_demo probe 2>"$TMP/err"); rc=$?
  [ "$rc" = 0 ] || return 1
  grep -Fq 'probe rc=0 gate=on gate_main=on cert_days=5 cert=expiring' <<< "$out" || return 1
  [ -f "$TMP/telegram-call" ] && ! [ -s "$TMP/telegram-call" ]
}
case33() { # probe: cert expiring while DNS is on the reserve fails and notifies Telegram
  setup A
  out=$(CERT_DAYS=5 TG_BOT_TOKEN=stub-bot TG_CHAT_ID=stub-chat run_demo probe 2>"$TMP/err"); rc=$?
  [ "$rc" = 1 ] || return 1
  grep -Fq 'probe rc=1 gate=on gate_main=on cert_days=5' <<< "$out" && grep -Fq 'telegram call' "$TMP/telegram-call"
}

case34() { # test: remove-domain timeout plus unreadable state fails instead of verified=detached
  setup A
  out=$(DEMO_YC_GET_ATTACHED_AFTER=0 DEMO_YC_REMOVE_124=1 DEMO_YC_GET_FAIL_AFTER_MUTATION=1 run_demo test 2>"$TMP/err"); rc=$?
  [ "$rc" -ne 0 ] || return 1
  ! grep -Fq 'verified=detached' "$TMP/run/state/demo.log"
}

case35() { # restore success removes the drill state file; restore failure keeps it
  setup CNAME
  printf '{"started":98800}\n' > "$TMP/run/state/demo-forms-test.arwox.ru.json"
  out=$(run_demo restore 2>"$TMP/err"); rc=$?
  [ "$rc" = 0 ] && grep -Fq '✅ Уже восстановлено' <<< "$out" && [ ! -e "$TMP/run/state/demo-forms-test.arwox.ru.json" ] || return 1
  setup CNAME
  printf '{"started":98800}\n' > "$TMP/run/state/demo-forms-test.arwox.ru.json"
  out=$(DEMO_YC_FAIL=1 run_demo restore 2>"$TMP/err"); rc=$?
  [ "$rc" = 1 ] && [ -e "$TMP/run/state/demo-forms-test.arwox.ru.json" ]
}

PASS=0
FAIL=0
for i in {1..35}; do
  if "case$i"; then PASS=$((PASS + 1)); else FAIL=$((FAIL + 1)); printf 'FAIL case %s\n' "$i"; fi
done
if [ "$FAIL" = 0 ]; then printf 'PASS %d/35\n' "$PASS"; else printf 'FAIL %d/35 (PASS %d/35)\n' "$FAIL" "$PASS"; exit 1; fi
