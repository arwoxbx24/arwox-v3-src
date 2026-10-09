#!/usr/bin/env bash
set -euo pipefail

DIR=$(cd -- "$(dirname -- "$0")" && pwd)
GW=${DNS_GW_CNAME:-d5dn462s09a9dpofvl2d.6brbn2wz.apigw.yandexcloud.net}
BEGET_IP=${BEGET_IP:-45.139.76.176}
case "${FORMS_FQDN:-forms-test.arwox.ru}" in
  forms-test.arwox.ru) FQDN=forms-test.arwox.ru ;;
  forms.arwox.ru) printf 'refused: production FQDN\n' >&2; exit 2 ;;
  *) printf 'refused: only forms-test.arwox.ru\n' >&2; exit 2 ;;
esac
mkdir -p "$DIR/state"
STATE="$DIR/state/demo.json"
LOG="$DIR/state/demo.log"
COMMAND=${1:-}

record() { printf '%s %s %s %s\n' "$(date -u +%FT%TZ)" "$COMMAND" "$1" "$2" >> "$LOG"; }
finish() {
  local rc=$?
  [ -z "${response:-}" ] || rm -f "$response"
  [ -z "${headers:-}" ] || rm -f "$headers"
  record result "rc=$rc"
}
trap finish EXIT
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
  if code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 15 --resolve "$FQDN:443:$BEGET_IP" "https://$FQDN/"); then rc=0; else rc=$?; fi
  record backup-http "code=${code:-000} remote_ip=$BEGET_IP rc=$rc"
  printf '%s\n' "${code:-000}"
}
wait_for() {
  local wanted=$1 started=$2 elapsed ns value all details
  local -a names=(ns1.beget.pro ns2.beget.pro ns1.beget.ru ns2.beget.ru ns1.beget.com ns2.beget.com)
  while :; do
    all=1
    details="expected=$wanted"
    for ns in "${names[@]}"; do
      value=$(dig +norecurse +short "$FQDN" "@$ns" | paste -sd, -)
      details+=" $ns=${value:-empty}"
      [ "${value%.}" = "${wanted%.}" ] || all=0
    done
    record wait "$details"
    [ "$all" = 1 ] && return 0
    elapsed=$(( $(date +%s) - started ))
    if [ "$elapsed" -ge 1200 ]; then printf 'timeout: expected %s across all Beget NS\n' "$wanted" >&2; record wait "timeout=1 elapsed=$elapsed"; return 1; fi
    sleep 15
  done
}
elapsed_minutes() { printf '%s\n' "$(( ($(date +%s) - $1 + 59) / 60 ))"; }

case ${1:-} in
  status)
    record dns-status "command=dns-switch.sh status --fqdn $FQDN"
    if dns=$($DIR/dns-switch.sh status --fqdn "$FQDN"); then rc=0; else rc=$?; fi
    record dns-status "result=$dns rc=$rc"
    [ "$rc" = 0 ] || exit "$rc"
    printf 'dns=%s yandex=HTTP %s backup=HTTP %s\n' "$dns" "$(yandex_code)" "$(backup_code)"
    ;;
  simulate)
    record yc-get "command=yc --profile default serverless api-gateway get d5dn462s09a9dpofvl2d --format json"
    if gateway=$(yc --profile default serverless api-gateway get d5dn462s09a9dpofvl2d --format json); then rc=0; else rc=$?; fi
    record yc-get "rc=$rc"
    [ "$rc" = 0 ] || exit "$rc"
    domain_id=$(jq -r '.attached_domains[] | select(.domain == "forms-test.arwox.ru") | .domain_id' <<< "$gateway" | tail -1)
    [ -n "$domain_id" ] && [ "$domain_id" != null ] || { printf 'domain id not found\n' >&2; exit 1; }
    record yc-remove "command=yc --profile default serverless api-gateway remove-domain d5dn462s09a9dpofvl2d --domain-id <domain-id>"
    if yc --profile default serverless api-gateway remove-domain d5dn462s09a9dpofvl2d --domain-id "$domain_id"; then rc=0; else rc=$?; fi
    record yc-remove "rc=$rc"
    [ "$rc" = 0 ] || exit "$rc"
    started=$(date +%s)
    jq -cn --argjson started "$started" --arg at "$(date -u +%FT%TZ)" '{started:$started,at:$at}' > "$STATE"
    record state "saved=$STATE started=$started"
    record step-1 "outage-simulated=1"
    printf '1) Сбой Яндекса имитирован: %s\n' "$(date -u +%T)"
    wait_for "$BEGET_IP" "$started"
    record step-2 "backup=$BEGET_IP"
    printf '2) Переключено на резерв (наш сервер): %s (+%s мин)\n' "$(date -u +%T)" "$(elapsed_minutes "$started")"
    response=$(mktemp "$DIR/state/demo.XXXXXX")
    headers=$(mktemp "$DIR/state/demo.XXXXXX")
    record backup-post "command=curl POST --resolve $FQDN:443:$BEGET_IP"
    if meta=$(curl -sS -D "$headers" -o "$response" -w '%{http_code} %{ssl_verify_result} %{remote_ip}' --max-time 15 -X POST --resolve "$FQDN:443:$BEGET_IP" "https://$FQDN/" -d 'NAME=demo&PHONE=%2B70000000000'); then rc=0; else rc=$?; fi
    read -r code ssl_verify_result remote_ip <<< "${meta:-000 none none}"
    location=$(awk 'BEGIN { IGNORECASE=1 } /^location:/ { sub(/^[^:]*:[[:space:]]*/, ""); sub(/\r$/, ""); print; exit }' "$headers")
    record backup-post "HTTP=$code ssl_verify_result=${ssl_verify_result:-none} remote_ip=${remote_ip:-none} Location=${location:-none} rc=$rc"
    if [ "$code" = 200 ] && grep -q 'smartcaptcha.yandexcloud.net/captcha.js' "$response"; then
      record step-3 "backup-handler=ok HTTP=$code captcha=shown"
      printf '3) Заявка дошла до резервного обработчика: HTTP %s, показана капча\n' "$code"
    else
      printf 'backup handler check failed: HTTP %s\n' "${code:-000}" >&2; exit 1
    fi
    ;;
  restore)
    record yc-certificate-list "command=yc --profile default certificate-manager certificate list --format json"
    if certificates=$(yc --profile default certificate-manager certificate list --format json); then rc=0; else rc=$?; fi
    record yc-certificate-list "rc=$rc"
    [ "$rc" = 0 ] || exit "$rc"
    certificate_id=$(jq -r '[.[] | select(.status == "ISSUED" and .domains == ["forms-test.arwox.ru"])] | last | .id // empty' <<< "$certificates")
    [ -n "$certificate_id" ] || { printf 'issued certificate not found\n' >&2; exit 1; }
    record yc-add "command=yc --profile default serverless api-gateway add-domain d5dn462s09a9dpofvl2d --domain $FQDN --certificate-id <certificate-id>"
    if yc --profile default serverless api-gateway add-domain d5dn462s09a9dpofvl2d --domain "$FQDN" --certificate-id "$certificate_id"; then rc=0; else rc=$?; fi
    record yc-add "rc=$rc"
    [ "$rc" = 0 ] || exit "$rc"
    started=$(jq -r '.started // empty' "$STATE" 2>/dev/null || true)
    started=${started:-$(date +%s)}
    wait_for "$GW" "$started"
    record step-4 "gateway=$GW"
    printf '4) Возврат на Яндекс: %s (всего %s мин)\n' "$(date -u +%T)" "$(elapsed_minutes "$started")"
    ;;
  *) usage ;;
esac
