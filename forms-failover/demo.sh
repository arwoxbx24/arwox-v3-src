#!/usr/bin/env bash
set -euo pipefail

DIR=$(cd -- "$(dirname -- "$0")" && pwd)
GW=${DNS_GW_CNAME:-d5dn462s09a9dpofvl2d.6brbn2wz.apigw.yandexcloud.net}
BEGET_IP=${BEGET_IP:-45.139.76.176}
export BEGET_IP
case "${FORMS_FQDN:-forms-test.arwox.ru}" in
  forms-test.arwox.ru|forms.arwox.ru) FQDN=${FORMS_FQDN:-forms-test.arwox.ru} ;;
  *) printf 'refused: only forms-test.arwox.ru\n' >&2; exit 2 ;;
esac
mkdir -p "$DIR/state"
STATE="$DIR/state/demo.json"
LOG="$DIR/state/demo.log"
LOCK="$DIR/state/demo.lock"
TIMER_PID="$DIR/state/demo.timer.pid"
if [ "$FQDN" = forms.arwox.ru ]; then
  GUARD_LOG=${GUARD_LOG:-/root/.pm2/logs/forms-gw-guard-out.log}
  GUARD_ERR=${GUARD_ERR:-/root/.pm2/logs/forms-gw-guard-error.log}
else
  GUARD_LOG=${GUARD_LOG:-/root/.pm2/logs/forms-gw-guard-test-out.log}
  GUARD_ERR=${GUARD_ERR:-/root/.pm2/logs/forms-gw-guard-test-error.log}
fi
COMMAND=${1:-}

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

usage() { printf 'usage: %s status|simulate|restore\n' "$0" >&2; exit 64; }
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
  setsid nohup bash -c 'export DEMO_AUTO_RESTORE=1; sleep "$1"; FORMS_FQDN="$2" "$3/demo.sh" restore' _ "${AUTO_RESTORE_SEC:-900}" "$FQDN" "$DIR" </dev/null >/dev/null 2>&1 &
  printf '%s\n' "$!" > "$TIMER_PID"
  printf '⏱ Автовозврат на Яндекс через 15 мин\n'
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

case ${1:-} in
  status)
    record dns-status "command=dns-switch.sh status --fqdn $FQDN"
    if dns=$($DIR/dns-switch.sh status --fqdn "$FQDN"); then rc=0; else rc=$?; fi
    record dns-status "result=$dns rc=$rc"
    [ "$rc" = 0 ] || exit "$rc"
    printf 'dns=%s yandex=HTTP %s backup=HTTP %s\n' "$dns" "$(yandex_code)" "$(backup_code)"
    ;;
  simulate)
    lock_demo
    guard_log_start=0
    [ -r "$GUARD_LOG" ] && guard_log_start=$(wc -l < "$GUARD_LOG")
    snapshot_guard_errors
    record yc-get "command=yc --profile default serverless api-gateway get d5dn462s09a9dpofvl2d --format json"
    if gateway=$(yc --profile default serverless api-gateway get d5dn462s09a9dpofvl2d --format json); then rc=0; else rc=$?; fi
    record yc-get "rc=$rc"
    [ "$rc" = 0 ] || exit "$rc"
    domain_id=$(jq -r --arg fqdn "$FQDN" '.attached_domains[] | select(.domain == $fqdn) | .domain_id' <<< "$gateway" | tail -1)
    if [ -z "$domain_id" ] || [ "$domain_id" = null ]; then printf 'ℹ️ Сбой уже имитирован — сначала ./demo.sh restore\n'; exit 0; fi
    record yc-remove "command=yc --profile default serverless api-gateway remove-domain d5dn462s09a9dpofvl2d --domain-id <domain-id>"
    if yc --profile default serverless api-gateway remove-domain d5dn462s09a9dpofvl2d --domain-id "$domain_id"; then rc=0; else rc=$?; fi
    record yc-remove "rc=$rc"
    [ "$rc" = 0 ] || exit "$rc"
    started=$(date +%s)
    jq -cn --argjson started "$started" --arg at "$(date -u +%FT%TZ)" '{started:$started,at:$at}' > "$STATE"
    record state "saved=$STATE started=$started"
    complete_stage 1 "$STEP_1" "$started"
    wait_for_guard "$started"
    wait_for "$BEGET_IP" "$started" 3 "$STEP_3"
    wait_for_certificate "$started"
    response=$(mktemp "$DIR/state/demo.XXXXXX")
    headers=$(mktemp "$DIR/state/demo.XXXXXX")
    record backup-post "command=curl POST --resolve $FQDN:443:$BEGET_IP"
    if meta=$(curl -sS -D "$headers" -o "$response" -w '%{http_code} %{ssl_verify_result} %{remote_ip}' --max-time 15 -X POST --resolve "$FQDN:443:$BEGET_IP" "https://$FQDN/" -d 'NAME=ТЕСТ demo.sh&PHONE=%2B70000000000&CONSENT=Y'); then rc=0; else rc=$?; fi
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
    start_auto_restore
    ;;
  restore)
    lock_demo
    if [ "${DEMO_AUTO_RESTORE:-}" = 1 ]; then rm -f "$TIMER_PID"; else cancel_auto_restore; fi
    guard_log_start=0
    [ -r "$GUARD_LOG" ] && guard_log_start=$(wc -l < "$GUARD_LOG")
    snapshot_guard_errors
    record yc-get "command=yc --profile default serverless api-gateway get d5dn462s09a9dpofvl2d --format json"
    if gateway=$(yc --profile default serverless api-gateway get d5dn462s09a9dpofvl2d --format json); then rc=0; else rc=$?; fi
    record yc-get "rc=$rc"
    [ "$rc" = 0 ] || exit "$rc"
    attached=0
    if jq -e --arg fqdn "$FQDN" '.attached_domains[]? | select(.domain == $fqdn)' >/dev/null <<< "$gateway"; then
      attached=1
    else
      record yc-certificate-list "command=yc --profile default certificate-manager certificate list --format json"
      if certificates=$(yc --profile default certificate-manager certificate list --format json); then rc=0; else rc=$?; fi
      record yc-certificate-list "rc=$rc"
      [ "$rc" = 0 ] || exit "$rc"
      certificate_id=$(jq -r --arg fqdn "$FQDN" '[.[] | select(.status == "ISSUED" and .domains == [$fqdn])] | last | .id // empty' <<< "$certificates")
      [ -n "$certificate_id" ] || { printf 'issued certificate not found\n' >&2; exit 1; }
      record yc-add "command=yc --profile default serverless api-gateway add-domain d5dn462s09a9dpofvl2d --domain $FQDN --certificate-id <certificate-id>"
      if yc --profile default serverless api-gateway add-domain d5dn462s09a9dpofvl2d --domain "$FQDN" --certificate-id "$certificate_id"; then rc=0; else rc=$?; fi
      record yc-add "rc=$rc"
      [ "$rc" = 0 ] || exit "$rc"
    fi
    started=$(jq -r '.started // empty' "$STATE" 2>/dev/null || true)
    started=${started:-$(date +%s)}
    if wait_for "$GW" "$started" '' '' 600; then
      :
    else
      rc=$?
      [ "$rc" = 124 ] || exit "$rc"
      "$DIR/dns-switch.sh" apply normal --fqdn "$FQDN"
      printf '⚠️ сторож не вернул DNS — возвращено тестом\n'
      wait_for "$GW" "$started" '' '' 600
    fi
    record step-4 "gateway=$GW"
    printf '4) Возврат на Яндекс: %s (всего %s мин)\n' "$(date -u +%T)" "$(elapsed_minutes "$started")"
    [ "$attached" = 0 ] || printf '✅ Уже восстановлено\n'
    ;;
  *) usage ;;
esac
