#!/usr/bin/env bash
set -euo pipefail

DIR=$(cd -- "$(dirname -- "$0")" && pwd)
GW=${DNS_GW_CNAME:-d5dn462s09a9dpofvl2d.6brbn2wz.apigw.yandexcloud.net}
BEGET_IP=${BEGET_IP:-45.139.76.176}
export BEGET_IP
usage() { printf 'usage: %s test [--prod] [--no-feed]\n       %s restore [--prod]\n       %s status [--prod]\n       %s probe [--prod]\n       %s cert-sync [--prod]\n' "$0" "$0" "$0" "$0" "$0" >&2; }

COMMAND=${1:-}
case "$COMMAND" in
  -h|--help) usage; exit 0 ;;
  test|restore|status|probe|cert-sync) shift ;;
  *) usage; exit 64 ;;
esac
NO_FEED=0
for arg in "$@"; do
  case "$arg" in
    --prod) export FORMS_FQDN=forms.arwox.ru ;;
    --no-feed) [ "$COMMAND" = test ] || { usage; exit 64; }; NO_FEED=1 ;;
    *) usage; exit 64 ;;
  esac
done
case "${FORMS_FQDN:-forms-test.arwox.ru}" in
  forms-test.arwox.ru|forms.arwox.ru) FQDN=${FORMS_FQDN:-forms-test.arwox.ru} ;;
  *) printf 'refused: only forms-test.arwox.ru\n' >&2; exit 2 ;;
esac
mkdir -p "$DIR/state"
STATE="$DIR/state/demo-$FQDN.json"
LOG="$DIR/state/demo.log"
LOCK="$DIR/state/demo.lock"
TIMER_PID="$DIR/state/demo-$FQDN.timer.pid"
if [ "$FQDN" = forms.arwox.ru ]; then
  GUARD_LOG=${GUARD_LOG:-/root/.pm2/logs/forms-gw-guard-out.log}
  GUARD_ERR=${GUARD_ERR:-/root/.pm2/logs/forms-gw-guard-error.log}
else
  GUARD_LOG=${GUARD_LOG:-/root/.pm2/logs/forms-gw-guard-test-out.log}
  GUARD_ERR=${GUARD_ERR:-/root/.pm2/logs/forms-gw-guard-test-error.log}
fi
BACKUP_LOG=${BACKUP_LOG:-/root/.pm2/logs/forms-backup-out.log}
NPM_SSL_SCRIPT=${NPM_SSL_SCRIPT:-/root/workspaces/tools/acc1-scripts/actions/npm_ssl_request.sh}

STEP_1='Сбой Яндекса имитирован'
STEP_2='Сторож заметил сбой'
STEP_3='DNS переключён на резерв'
STEP_4='Сертификат на резерве готов'
STEP_5='Заявка принята резервом'

record() { printf '%s %s %s %s\n' "$(date -u +%FT%TZ)" "$COMMAND" "$1" "$2" >> "$LOG"; }
finish() {
  local rc=$?
  [ -z "${response:-}" ] || rm -f "$response"
  [ -z "${headers:-}" ] || rm -f "$headers"
  record result "rc=$rc"
}
trap finish EXIT
trap 'exit 130' INT TERM
record start "fqdn=$FQDN"

yandex_code() {
  local ip code=000 rc=0
  ip=$(dig +short "$GW" | tail -1)
  record yandex-dig "gateway=$GW ip=${ip:-empty}"
  if [ -n "$ip" ]; then
    if code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 15 --resolve "$FQDN:443:$ip" "https://$FQDN/"); then rc=0; else rc=$?; fi
  fi
  record yandex-http "code=${code:-000} rc=$rc"
  printf '%s\n' "${code:-000}"
}
backup_code() {
  local code=000 rc=0
  if code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 15 --resolve "$FQDN:80:$BEGET_IP" "http://$FQDN/"); then rc=0; else rc=$?; fi
  record backup-http "code=${code:-000} remote_ip=$BEGET_IP rc=$rc"
  printf '%s\n' "${code:-000}"
}
lock_demo() {
  local at
  exec 9>>"$LOCK"
  if ! flock -n 9; then
    at=$(jq -r '.at // empty' "$STATE" 2>/dev/null || true)
    [ -n "$at" ] || at=$(tail -n 1 "$LOCK" 2>/dev/null || true)
    printf '⛔ Тест уже идёт (запущен %s) — дождитесь окончания\n' "${at:-неизвестно}" >&2
    exit 75
  fi
  printf '%s\n' "$(date -u +%FT%TZ)" > "$LOCK"
}
cancel_auto_restore() {
  local pid=
  [ -r "$TIMER_PID" ] && read -r pid < "$TIMER_PID"
  if [[ "$pid" =~ ^[0-9]+$ ]] && kill -0 "$pid" 2>/dev/null; then kill "$pid" 2>/dev/null || true; fi
  rm -f "$TIMER_PID"
}
start_auto_restore() {
  auto_restore_started=$(date +%s)
  setsid nohup bash -c 'export DEMO_AUTO_RESTORE=1; sleep "$1"; FORMS_FQDN="$2" "$3/forms-ctl.sh" restore' _ "${AUTO_RESTORE_SEC:-900}" "$FQDN" "$DIR" </dev/null >/dev/null 2>&1 &
  printf '%s\n' "$!" > "$TIMER_PID"
  printf '⏱ Автовозврат на Яндекс через 15 мин\n'
}
lead_feed() {
  local started=$1 line_count=0 seen=0 accepted=0 errors=0 b24_leads=0 b24_queue=0 now remaining at host code result b24 b24_text clock queued_spools= spool
  seen=${backup_log_start:-0}
  trap 'printf "🏆 Резерв принял %s заявок (✅ %s, ❌ %s). В Bitrix24: %s, в очереди: %s\n" "$((accepted + errors))" "$accepted" "$errors" "$b24_leads" "$b24_queue"; printf "⏱ Автовозврат на Яндекс сработает сам\n"; exit 130' INT TERM
  while :; do
    if [ -r "$BACKUP_LOG" ]; then
      line_count=$(wc -l < "$BACKUP_LOG")
      if [ "$line_count" -lt "$seen" ]; then seen=0; fi
      while IFS= read -r line; do
        case "$line" in
          *"forms-backup spool-sent "*)
            read -r spool b24 <<< "${line#*forms-backup spool-sent }"
            spool=${spool#spool=}
            if [[ "$b24" =~ ^b24=lead:([0-9]+)$ ]]; then
              if [[ " $queued_spools " == *" $spool "* ]]; then
                b24_queue=$((b24_queue - 1))
                b24_leads=$((b24_leads + 1))
                printf '📬 из очереди: Bitrix24 лид #%s\n' "${BASH_REMATCH[1]}"
              fi
            fi
            continue
            ;;
          *"forms-backup lead "*) read -r at host code result b24 <<< "${line#*forms-backup lead }" ;;
          *) continue ;;
        esac
        [ "$host" = "host=$FQDN" ] || continue
        clock=${at#*T}; clock=${clock%Z}
        case "$b24" in
          b24=lead:*) b24_leads=$((b24_leads + 1)); b24_text=" → Bitrix24 лид #${b24#b24=lead:}" ;;
          b24=queue:*) b24_queue=$((b24_queue + 1)); queued_spools="$queued_spools ${b24#b24=queue:}"; b24_text=' → очередь резерва, дошлётся сам' ;;
          b24=-) b24_text=' → в Bitrix24 не передана' ;;
          *) b24_text= ;;
        esac
        case "$result" in
          result=sent) accepted=$((accepted + 1)); printf '🎯 Заявка №%s принята РЕЗЕРВОМ %s в %s → ✅ #sent%s\n' "$((accepted + errors))" "$BEGET_IP" "$clock" "$b24_text" ;;
          result=err:*) errors=$((errors + 1)); printf '🎯 Заявка №%s принята РЕЗЕРВОМ %s в %s → ❌ %s%s\n' "$((accepted + errors))" "$BEGET_IP" "$clock" "${result#result=}" "$b24_text" ;;
        esac
      done < <(sed -n "$((seen + 1)),$line_count p" "$BACKUP_LOG")
      seen=$line_count
    fi
    now=$(date +%s)
    remaining=$(( ${AUTO_RESTORE_SEC:-900} - (now - started) ))
    [ "$remaining" -gt 0 ] || break
    if [ $(((now - started) % 30)) = 0 ]; then
      printf '⏳ Окно теста: осталось %02d:%02d | принято резервом: %s\n' "$((remaining / 60))" "$((remaining % 60))" "$((accepted + errors))"
    fi
    [ "$remaining" -lt 5 ] && sleep "$remaining" || sleep 5
  done
  trap 'exit 130' INT TERM
  printf '🏆 Резерв принял %s заявок (✅ %s, ❌ %s). В Bitrix24: %s, в очереди: %s\n' "$((accepted + errors))" "$accepted" "$errors" "$b24_leads" "$b24_queue"
  printf '⏱ Автовозврат на Яндекс сработает сам\n'
}
elapsed_minutes() { printf '%s\n' "$(( ($(date +%s) - $1 + 59) / 60 ))"; }
complete_stage() {
  local stage=$1 label=$2 started=$3
  record "step-$stage" "passed=1"
  printf '✅ Этап %s/5: %s (+%s мин)\n' "$stage" "$label" "$(elapsed_minutes "$started")"
}
guard_lines() {
  [ -r "$GUARD_LOG" ] && tail -n "+$((guard_log_start + 1))" "$GUARD_LOG" || true
}
guard_error_lines() {
  [ -r "$GUARD_ERR" ] && tail -n "+$((guard_err_start + 1))" "$GUARD_ERR" || true
}
guard_crashed() {
  local stage=$1 line
  while IFS= read -r line; do
    if [[ "$line" == *'unbound variable'* || "$line" =~ line\ [0-9]+: ]]; then
      printf '❌ Этап %s/5: сторож упал: %s\n' "$stage" "$line" >&2
      return 0
    fi
  done < <(guard_error_lines)
  return 1
}
snapshot_guard_errors() {
  guard_err_start=0
  [ -r "$GUARD_ERR" ] && guard_err_start=$(wc -l < "$GUARD_ERR")
}
guard_event() {
  local line event='ожидание события'
  while IFS= read -r line; do
    case "$line" in
      *'check code=000'*) event='форма не отвечает' ;;
      *'debounced outage'*) event='сбой подтверждён' ;;
      *'sent fallback_outage'*) event='резерв включён' ;;
      *'ssl request rc=0'*) event='сертификат запрошен' ;;
      *'ssl request rc='*) event='сертификат: ошибка, повтор через 15 мин' ;;
      *) event=$line ;;
    esac
  done < <(guard_lines)
  printf '%s\n' "$event"
}
guard_dns_failure() {
  local line failure=
  while IFS= read -r line; do
    case "$line" in *'dns switch failed: '*) failure=${line#*dns switch failed: } ;; esac
  done < <(guard_lines)
  printf '%s\n' "$failure"
}
progress() {
  local started=$1 stage=$2 label=$3 dns=$4 line
  line="Этап $stage/5: $label ⏳ | DNS $dns/6 | сторож: $(guard_event)"
  [ "${last_progress:-}" = "$line" ] && return
  last_progress=$line
  printf '[+%s мин] %s\n' "$(elapsed_minutes "$started")" "$line"
}
dns_count() {
  local wanted=$1 ns value count=0
  local -a names=(ns1.beget.pro ns2.beget.pro ns1.beget.ru ns2.beget.ru ns1.beget.com ns2.beget.com)
  for ns in "${names[@]}"; do
    value=$(dig +norecurse +short "$FQDN" "@$ns" | paste -sd, -)
    [ "${value%.}" = "${wanted%.}" ] && count=$((count + 1))
  done
  printf '%s\n' "$count"
}
wait_for() {
  local wanted=$1 started=$2 stage=${3:-} label=${4:-} timeout=${5:-1200} elapsed ns value all details count failure
  local -a names=(ns1.beget.pro ns2.beget.pro ns1.beget.ru ns2.beget.ru ns1.beget.com ns2.beget.com)
  while :; do
    guard_crashed "${stage:-4}" && return 1
    all=1; count=0
    details="expected=$wanted"
    for ns in "${names[@]}"; do
      value=$(dig +norecurse +short "$FQDN" "@$ns" | paste -sd, -)
      details+=" $ns=${value:-empty}"
      if [ "${value%.}" = "${wanted%.}" ]; then count=$((count + 1)); else all=0; fi
    done
    record wait "$details"
    if [ -n "$stage" ]; then
      failure=$(guard_dns_failure)
      if [ -n "$failure" ]; then printf '❌ Этап 3/5: переключение DNS отклонено: %s\n' "$failure" >&2; return 1; fi
      progress "$started" "$stage" "$label" "$count"
      [ "$all" = 1 ] && { complete_stage "$stage" "$label" "$started"; return 0; }
    elif [ "$all" = 1 ]; then
      return 0
    fi
    elapsed=$(( $(date +%s) - started ))
    if [ "$elapsed" -ge "$timeout" ]; then
      record wait "timeout=1 elapsed=$elapsed"
      if [ -n "$stage" ]; then printf '❌ Этап %s/5: ожидание превысило 20 мин\n' "$stage" >&2; else printf 'timeout: expected %s across all Beget NS\n' "$wanted" >&2; fi
      return 124
    fi
    sleep 15
  done
}
wait_for_guard() {
  local started=$1 elapsed failure lines
  while :; do
    guard_crashed 2 && return 1
    failure=$(guard_dns_failure)
    if [ -n "$failure" ]; then printf '❌ Этап 3/5: переключение DNS отклонено: %s\n' "$failure" >&2; return 1; fi
    progress "$started" 2 "$STEP_2" "$(dns_count "$BEGET_IP")"
    lines=$(guard_lines)
    if [[ "$lines" == *'check code=000'* || "$lines" == *'debounced outage'* ]]; then complete_stage 2 "$STEP_2" "$started"; return 0; fi
    elapsed=$(( $(date +%s) - started ))
    [ "$elapsed" -lt 1200 ] || { printf '❌ Этап 2/5: сторож не подтвердил сбой за 20 мин\n' >&2; return 1; }
    sleep 15
  done
}
wait_for_certificate() {
  local started=$1 elapsed failure
  while :; do
    guard_crashed 4 && return 1
    failure=$(guard_dns_failure)
    if [ -n "$failure" ]; then printf '❌ Этап 3/5: переключение DNS отклонено: %s\n' "$failure" >&2; return 1; fi
    progress "$started" 4 "$STEP_4" "$(dns_count "$BEGET_IP")"
    if curl -s -o /dev/null --max-time 10 --resolve "$FQDN:443:$BEGET_IP" "https://$FQDN/"; then
      complete_stage 4 "$STEP_4" "$started"
      if [ "$FQDN" = forms.arwox.ru ]; then
        printf '🟢 МОЖНО ТЕСТИРОВАТЬ 15 мин: откройте https://arwox.ru/#contact, отправьте заявку → должен открыться #sent\n'
      else
        printf '🟢 МОЖНО ТЕСТИРОВАТЬ: откройте форму https://forms-test.arwox.ru/\n'
      fi
      return 0
    fi
    elapsed=$(( $(date +%s) - started ))
    [ "$elapsed" -lt 1200 ] || { printf '❌ Этап 4/5: сертификат не готов за 20 мин\n' >&2; return 1; }
    sleep 15
  done
}

yc_exit() { # $1 = rc of a `timeout 60 yc` call; 124 keeps the reserve testable through `probe`
  local rc=$1
  if [ "$rc" = 124 ]; then
    printf '❌ Yandex Cloud API не ответил за 60 с — тест сбоя невозможен; состояние резерва: ./forms-ctl.sh probe --prod\n' >&2
    rc=1
  fi
  [ "$rc" = 0 ] || exit "$rc"
}
yc_verify_mutation() { # $1 = add|remove; $2 = rc of the (timeout 300) mutating call; return 0 only when the gateway is already in the target state (`yc serverless api-gateway add-domain` can run ~110 s)
  local kind=$1 rc=$2 gateway=unknown gateway_json
  [ "$rc" = 0 ] && return 0
  gateway_json=$(timeout 60 yc --profile default serverless api-gateway get d5dn462s09a9dpofvl2d --format json) || gateway_json=
  if gateway=$(jq -r --arg fqdn "$FQDN" 'if ((.attached_domains // null) | type) == "array" then (if any(.attached_domains[]; .domain == $fqdn) then "attached" else "detached" end) else "unknown" end' <<< "$gateway_json") \
     && [ "$gateway" = attached -o "$gateway" = detached ]; then :; else gateway=unknown; fi
  if [ "$kind" = add ] && [ "$gateway" = attached ]; then
    record yc-add "verified=attached after rc=$rc"
    return 0
  elif [ "$kind" = remove ] && [ "$gateway" = detached ]; then
    record yc-remove "verified=detached after rc=$rc"
    return 0
  fi
  return 1
}
openssl_notafter_days() {
  local end ts now
  end=$(openssl s_client -connect "$BEGET_IP:443" -servername "$FQDN" </dev/null 2>/dev/null | openssl x509 -noout -enddate 2>/dev/null) || true
  end=${end#notAfter=}
  [ -n "$end" ] || return 1
  if ! ts=$(date -d "$end" +%s 2>/dev/null); then return 1; fi
  now=$(date +%s)
  printf '%s\n' $(( (ts - now) / 86400 ))
}
telegram_send() { # token/chat reach the API only through stdin (`curl -K -`), never on the command line
  local text=$1
  [ -n "${TG_BOT_TOKEN:-}" ] && [ -n "${TG_CHAT_ID:-}" ] || return 0
  curl -s --max-time 30 -K - >/dev/null 2>&1 <<EOF || true
url = "https://api.telegram.org/bot$TG_BOT_TOKEN/sendMessage"
request = "POST"
data = "chat_id=$TG_CHAT_ID&text=${text// /%20}"
EOF
}
probe_gate() { # $1 = reserve|main ; prints on|off|error
  local which=$1 post=( -sS --max-time 20 -X POST ) body response code status rc=0
  response=$(mktemp "$DIR/state/probe.XXXXXX")
  post+=( -o "$response" -w '%{http_code}' )
  if [ "$which" = reserve ]; then post+=( -k --resolve "$FQDN:443:$BEGET_IP" ); fi
  record gate-post "route=$which"
  if body=$(curl "${post[@]}" "https://$FQDN/" \
      --data-urlencode 'NAME=ТЕСТ forms-ctl probe' --data-urlencode 'PHONE=+70000000000' \
      -d 'CONSENT=Y&smart-token=probe'); then rc=0; else rc=$?; fi
  code=${body%% *}
  if [ "$rc" != 0 ]; then status=error
  elif [ "$code" = 200 ] && grep -q 'smartcaptcha.yandexcloud.net/captcha.js' "$response"; then status=on
  elif [ "$code" = 302 ]; then status=off
  else status=error
  fi
  rm -f "$response"
  record gate "route=$which code=${code:-000} result=$status"
  printf '%s\n' "$status"
}

case "$COMMAND" in
  status)
    record dns-status "command=dns-switch.sh status --fqdn $FQDN"
    if dns=$($DIR/dns-switch.sh status --fqdn "$FQDN"); then rc=0; else rc=$?; fi
    record dns-status "result=$dns rc=$rc"
    [ "$rc" = 0 ] || exit "$rc"
    printf 'dns=%s yandex=HTTP %s backup=HTTP %s\n' "$dns" "$(yandex_code)" "$(backup_code)"
    ;;
  test)
    lock_demo
    guard_log_start=0
    [ -r "$GUARD_LOG" ] && guard_log_start=$(wc -l < "$GUARD_LOG")
    backup_log_start=0
    [ -r "$BACKUP_LOG" ] && backup_log_start=$(wc -l < "$BACKUP_LOG")
    snapshot_guard_errors
    record yc-get "command=timeout 60 yc --profile default serverless api-gateway get d5dn462s09a9dpofvl2d --format json"
    if gateway=$(timeout 60 yc --profile default serverless api-gateway get d5dn462s09a9dpofvl2d --format json); then rc=0; else rc=$?; fi
    record yc-get "rc=$rc"
    yc_exit "$rc"
    domain_id=$(jq -r --arg fqdn "$FQDN" '.attached_domains[] | select(.domain == $fqdn) | .domain_id' <<< "$gateway" | tail -1)
    if [ -z "$domain_id" ] || [ "$domain_id" = null ]; then printf 'ℹ️ Сбой уже имитирован — сначала ./forms-ctl.sh restore\n'; exit 0; fi
    record yc-remove "command=timeout 300 yc --profile default serverless api-gateway remove-domain d5dn462s09a9dpofvl2d --domain-id <domain-id>"
    if timeout 300 yc --profile default serverless api-gateway remove-domain d5dn462s09a9dpofvl2d --domain-id "$domain_id"; then rc=0; else rc=$?; fi
    record yc-remove "rc=$rc"
    if yc_verify_mutation remove "$rc"; then rc=0; fi
    yc_exit "$rc"
    started=$(date +%s)
    jq -cn --argjson started "$started" --arg at "$(date -u +%FT%TZ)" '{started:$started,at:$at}' > "$STATE"
    record state "saved=$STATE started=$started"
    complete_stage 1 "$STEP_1" "$started"
    start_auto_restore
    wait_for_guard "$started"
    wait_for "$BEGET_IP" "$started" 3 "$STEP_3"
    wait_for_certificate "$started"
    response=$(mktemp "$DIR/state/demo.XXXXXX")
    headers=$(mktemp "$DIR/state/demo.XXXXXX")
    record backup-post "command=curl POST --resolve $FQDN:443:$BEGET_IP"
    if meta=$(curl -sS -D "$headers" -o "$response" -w '%{http_code} %{ssl_verify_result} %{remote_ip}' --max-time 15 -X POST --resolve "$FQDN:443:$BEGET_IP" "https://$FQDN/" -d 'NAME=ТЕСТ forms-ctl.sh&PHONE=%2B70000000000&CONSENT=Y'); then rc=0; else rc=$?; fi
    read -r code ssl_verify_result remote_ip <<< "${meta:-000 none none}"
    location=$(awk 'BEGIN { IGNORECASE=1 } /^location:/ { sub(/^[^:]*:[[:space:]]*/, ""); sub(/\r$/, ""); print; exit }' "$headers")
    record backup-post "HTTP=$code ssl_verify_result=${ssl_verify_result:-none} remote_ip=${remote_ip:-none} Location=${location:-none} rc=$rc"
    ok_location_re='(^|[?&])ok=1([&#]|$)'
    if { [ "$code" = 302 ] && [[ "$location" =~ $ok_location_re ]]; } || { [ "$code" = 200 ] && grep -q 'smartcaptcha.yandexcloud.net/captcha.js' "$response"; }; then
      complete_stage 5 "$STEP_5" "$started"
      if [ "$code" = 302 ]; then
        printf '🏁 Тест пройден: 5/5 за %s мин (лид принят резервом)\n' "$(elapsed_minutes "$started")"
      else
        printf '🏁 Тест пройден: 5/5 за %s мин (резерв доступен, капча включена)\n' "$(elapsed_minutes "$started")"
      fi
    else
      printf '❌ Этап 5/5: заявка не принята резервом: HTTP %s Location=%s\n' "${code:-000}" "${location:-none}" >&2; exit 1
    fi
    [ "$NO_FEED" = 1 ] || { flock -u 9; exec 9>&-; lead_feed "$auto_restore_started"; }
    ;;
  restore)
    lock_demo
    restore_started=$(date +%s)
    if [ "${DEMO_AUTO_RESTORE:-}" = 1 ]; then rm -f "$TIMER_PID"; else cancel_auto_restore; fi
    guard_log_start=0
    [ -r "$GUARD_LOG" ] && guard_log_start=$(wc -l < "$GUARD_LOG")
    snapshot_guard_errors
    record yc-get "command=timeout 60 yc --profile default serverless api-gateway get d5dn462s09a9dpofvl2d --format json"
    if gateway=$(timeout 60 yc --profile default serverless api-gateway get d5dn462s09a9dpofvl2d --format json); then rc=0; else rc=$?; fi
    record yc-get "rc=$rc"
    yc_exit "$rc"
    attached=0
    if jq -e --arg fqdn "$FQDN" '.attached_domains[]? | select(.domain == $fqdn)' >/dev/null <<< "$gateway"; then
      attached=1
    else
      record yc-certificate-list "command=timeout 60 yc --profile default certificate-manager certificate list --format json"
      if certificates=$(timeout 60 yc --profile default certificate-manager certificate list --format json); then rc=0; else rc=$?; fi
      record yc-certificate-list "rc=$rc"
      yc_exit "$rc"
      certificate_id=$(jq -r --arg fqdn "$FQDN" '[.[] | select(.status == "ISSUED" and .domains == [$fqdn])] | last | .id // empty' <<< "$certificates")
      [ -n "$certificate_id" ] || { printf 'issued certificate not found\n' >&2; exit 1; }
      record yc-add "command=timeout 300 yc --profile default serverless api-gateway add-domain d5dn462s09a9dpofvl2d --domain $FQDN --certificate-id <certificate-id>"
      if timeout 300 yc --profile default serverless api-gateway add-domain d5dn462s09a9dpofvl2d --domain "$FQDN" --certificate-id "$certificate_id"; then rc=0; else rc=$?; fi
      record yc-add "rc=$rc"
      if yc_verify_mutation add "$rc"; then rc=0; fi
      yc_exit "$rc"
    fi
    started=$(jq -r '.started // empty' "$STATE" 2>/dev/null || true)
    started=${started:-$(date +%s)}
    if wait_for "$GW" "$restore_started" '' '' 600; then
      :
    else
      rc=$?
      [ "$rc" = 124 ] || exit "$rc"
      "$DIR/dns-switch.sh" apply normal --fqdn "$FQDN"
      printf '⚠️ сторож не вернул DNS — возвращено тестом\n'
      wait_for "$GW" "$(date +%s)" '' '' 600
    fi
    record step-4 "gateway=$GW"
    rm -f "$STATE"
    printf '4) Возврат на Яндекс: %s (всего %s мин)\n' "$(date -u +%T)" "$(elapsed_minutes "$started")"
    [ "$attached" = 0 ] || printf '✅ Уже восстановлено\n'
    ;;
  probe)
    if days=$(openssl_notafter_days); then cert_days=$days; else cert_days=-9999; fi
    record probe-cert "days=$cert_days"
    vcode=$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 -X POST https://smartcaptcha.yandexcloud.net/validate -d 'secret=probe&token=probe') || vcode=000
    record validator "code=${vcode:-000}"
    case "$vcode" in 200|4??) healthy=1 ;; *) healthy=0 ;; esac
    if [ "$healthy" = 1 ]; then
      gate=$(probe_gate reserve)
      gate_main=$(probe_gate main)
    else
      gate=skip
      gate_main=skip
    fi
    rc=0
    cert_note=
    if [ "$cert_days" -lt 7 ]; then
      if [ "$cert_days" = -9999 ] || [ "$(dns_count "$BEGET_IP")" = 6 ]; then
        rc=1
      else
        cert_note=' cert=expiring' # DNS on Yandex: LE renewal impossible — note only; on the reserve an expiring cert fails the probe
      fi
    fi
    case "$gate" in off|error) rc=1 ;; esac
    case "$gate_main" in off|error) rc=1 ;; esac
    line=$(printf 'probe rc=%d gate=%s gate_main=%s cert_days=%s%s' "$rc" "$gate" "$gate_main" "$cert_days" "$cert_note")
    printf '%s\n' "$line"
    record probe "line=$line"
    [ "$rc" = 0 ] || telegram_send "forms reserve probe FAILED: $line"
    exit "$rc"
    ;;
  cert-sync)
    if days=$(openssl_notafter_days); then cert_days=$days; else cert_days=-9999; fi
    dns=$(dns_count "$BEGET_IP")
    record cert-sync-check "days=$cert_days dns=$dns"
    action=none
    rc=0
    if [ "$cert_days" = -9999 ]; then
      rc=1
    elif [ "$cert_days" -le 30 ] && [ "$dns" = 6 ]; then
      host_id=${NPM_HOST_ID:-}
      if [ -z "$host_id" ]; then
        if [ "$FQDN" = forms.arwox.ru ]; then host_id=40; else host_id=39; fi
      fi
      record npm-ssl "command=npm_ssl_request.sh proxy_host_id=$host_id"
      if "$NPM_SSL_SCRIPT" "{\"proxy_host_id\":\"$host_id\"}"; then action=renewed; else action=failed; rc=1; fi
    fi
    line=$(printf 'cert_sync rc=%d days=%s action=%s' "$rc" "$cert_days" "$action")
    printf '%s\n' "$line"
    record cert-sync "line=$line"
    [ "$rc" = 0 ] || telegram_send "forms reserve cert-sync FAILED: $line"
    exit "$rc"
    ;;
esac
