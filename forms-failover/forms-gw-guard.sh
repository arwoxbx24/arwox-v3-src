#!/usr/bin/env bash
# forms-gw-guard: one-shot watchdog for the API gateway serving forms.arwox.ru.
# Polled by pm2 cron; must complete within ~60s. Alerts go to Telegram via
# TG_BOT_TOKEN/TG_CHAT_ID injected by pm2 from pm2-notify.env.
set -uo pipefail

export PATH="$PATH:/root/yandex-cloud/bin"

GUARD_GW_ID="${GUARD_GW_ID:-d5dn462s09a9dpofvl2d}"
GUARD_FORMS_URL="${GUARD_FORMS_URL:-https://forms.arwox.ru/}"
GUARD_FQDN="${GUARD_FORMS_URL#*://}"; GUARD_FQDN="${GUARD_FQDN%%/*}"
GUARD_GW_HOST="${GUARD_GW_HOST:-}"; DNS_SWITCH="${DNS_SWITCH:-}"; NPM_HOST_ID="${NPM_HOST_ID:-}"; BEGET_IP="${BEGET_IP:-45.139.76.176}"
NPM_SSL_REQUEST="${NPM_SSL_REQUEST:-/root/workspaces/tools/acc1-scripts/actions/npm_ssl_request.sh}"
GUARD_BALANCE_MIN="${GUARD_BALANCE_MIN:-10}"
GUARD_STATE_DIR="${GUARD_STATE_DIR:-/root/workspaces/tools/scripts/schedulers/state}"
GUARD_DEBOUNCE_SEC="${GUARD_DEBOUNCE_SEC:-21600}"
GUARD_REMINDER_SEC="${GUARD_REMINDER_SEC:-3600}"
GUARD_FALL_N="${GUARD_FALL_N:-3}"
GUARD_RISE_N="${GUARD_RISE_N:-15}"
GUARD_YC_TIMEOUT="${GUARD_YC_TIMEOUT:-15}"
GUARD_NOTIFY="${GUARD_NOTIFY:-1}"
GUARD_CAPTCHA_UNVERIFIED_MAX="${GUARD_CAPTCHA_UNVERIFIED_MAX:-5}"
GUARD_RESERVE_LOG="${GUARD_RESERVE_LOG:-/root/.pm2/logs/forms-backup-out.log}"
GUARD_CAPTCHA_FUNCTION_ID="${GUARD_CAPTCHA_FUNCTION_ID:-d4eb92qbfgt3ac0udlmm}"
GUARD_CAPTCHA_FOLDER_ID="${GUARD_CAPTCHA_FOLDER_ID:-b1g7fof71b9b632o3a4r}"
GUARD_RESERVE_BUCKET="${GUARD_RESERVE_BUCKET:-arwox-forms-reserve-b1g7fof71b9b632o3a4r}"
[ "$GUARD_NOTIFY" = 0 ] && unset TG_BOT_TOKEN TG_CHAT_ID
FALLBACK_SWITCH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/forms-fallback-switch.sh"
GUARD_DRILL_STATE="${GUARD_DRILL_STATE:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/state/demo-$GUARD_FQDN.json}"

STATE_FILE="$GUARD_STATE_DIR/state.json"
BODY_FILE="$GUARD_STATE_DIR/forms-gw-guard.body"
failed=0
form_error=0
dns_empty=0

log() { printf '%s %s %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%S')" "$1" "${2:-}" ; }
state_write() { cat > "$STATE_FILE.tmp" && mv -f "$STATE_FILE.tmp" "$STATE_FILE"; }
state_put() { # key json-value: sets one key of the state file, the file is created when missing
  [ -f "$STATE_FILE" ] || printf '{}\n' > "$STATE_FILE"
  jq --arg k "$1" --argjson v "$2" '.[$k] = $v' "$STATE_FILE" > "$STATE_FILE.tmp" && mv -f "$STATE_FILE.tmp" "$STATE_FILE"
}

outage_duration() { # seconds
  local seconds="$1" hours minutes
  hours=$((seconds / 3600))
  minutes=$(((seconds % 3600) / 60))
  if [ "$hours" -gt 0 ]; then printf '%sч %sм' "$hours" "$minutes"; else printf '%sм' "$minutes"; fi
}

notify() { # type text
  local type="$1" text="$2" now ts state json out msg started last elapsed
  text=$(printf '%s' "$text" | tr -d '"\r\n' | head -c 600)
  now=$(date +%s)
  if [ -n "$DNS_SWITCH" ] && { [ "$type" = form_error ] || [ "$type" = form_recovered ]; }; then
    log "notify $type suppressed (DNS_SWITCH)"
    if [ "$type" = form_recovered ] && [ -f "$STATE_FILE" ]; then
      json=$(jq 'del(.form_outage_started_at, .form_outage_notified_at)' "$STATE_FILE") &&
        printf '%s\n' "$json" | state_write
    fi
    if [ "$type" = form_error ]; then # DNS_SWITCH silences the message only; the outage start is still recorded
      [ -f "$STATE_FILE" ] || printf '{}\n' > "$STATE_FILE"
      jq --argjson n "$now" 'if (.form_outage_started_at // 0) == 0 then .form_outage_started_at = $n else . end' \
        "$STATE_FILE" > "$STATE_FILE.tmp" && mv -f "$STATE_FILE.tmp" "$STATE_FILE" || log "outage start write failed"
    fi
    return 0
  fi
  case "$type" in
    gw_resumed) msg="✅ $GUARD_FQDN: шлюз форм был остановлен (реапер YC) — поднят сторожем, форма отвечает <$text>." ;;
    low_balance) msg="💸 Баланс Yandex Cloud $text ₽ (< $GUARD_BALANCE_MIN). Пополнить, иначе реапер остановит шлюз форм." ;;
    captcha_unverified) msg="⚠️ Заявок без проверки капчи за час: $text (> $GUARD_CAPTCHA_UNVERIFIED_MAX). Проверьте лиды [captcha-unverified] в Bitrix24." ;;
    reserve_lead) msg="📥 Заявок в резерве (Bitrix24 не принял): $text. Ключи в бакете $GUARD_RESERVE_BUCKET/reserve/." ;;
    cloud_read_failed) msg="⚠️ Яндекс-журнал функции не читается $text раз подряд — счётчик заявок без капчи видит только резерв." ;;
    cloud_read_outage) msg="⚠️ Журнал Yandex Cloud Logging недоступен — сбой на стороне Яндекса (status.yandex.cloud/ru/incidents/2136). Формы работают; заявки без капчи пока считает только резерв." ;;
    cloud_read_recovered) msg="✅ Журнал Yandex Cloud Logging снова читается. Счётчик заявок без капчи работает полностью." ;;
    *) msg="${text:-}" ;;
  esac
  state="{}"
  if [ -f "$STATE_FILE" ]; then
    if json=$(cat "$STATE_FILE" 2>/dev/null) && echo "$json" | jq -e . >/dev/null 2>&1; then
      state="$json"
    else
      log "state reset"
      state="{}"
    fi
  fi
  case "$type" in
    form_error|gw_failed)
      started=$(echo "$state" | jq -r '.form_outage_started_at // 0' 2>/dev/null || echo 0)
      case "$started" in ''|*[!0-9]*) started=0 ;; esac
      if [ "$started" = 0 ]; then
        started="$now"
        state=$(echo "$state" | jq --argjson n "$now" '.form_outage_started_at = $n')
        printf '%s\n' "$state" | state_write
      fi
      elapsed=$((now - started))
      case "$type" in
        gw_failed) msg="🚨 $GUARD_FQDN: шлюз форм STOPPED, resume не удался: $text. Сбой длится $(outage_duration "$elapsed"). Проверить биллинг YC." ;;
        form_error) msg="⚠️ $GUARD_FQDN отвечает <$text> (шлюз не остановлен). Сбой длится $(outage_duration "$elapsed"). Проверить функцию arwox-lead-form." ;;
      esac
      last=$(echo "$state" | jq -r '.form_outage_notified_at // 0' 2>/dev/null || echo 0)
      case "$last" in ''|*[!0-9]*) last=0 ;; esac
      if [ "$last" != 0 ] && awk -v now="$now" -v last="$last" -v interval="$GUARD_REMINDER_SEC" 'BEGIN{exit !(now-last<interval)}'; then
        log "debounced outage"
        return 0
      fi
      ;;
    form_recovered)
      started=$(echo "$state" | jq -r '.form_outage_started_at // 0' 2>/dev/null || echo 0)
      case "$started" in ''|*[!0-9]*) started=0 ;; esac
      [ "$started" = 0 ] && return 0
      elapsed=$((now - started))
      msg="✅ $GUARD_FQDN: восстановлено. Сбой длился $(outage_duration "$elapsed")."
      ;;
    fallback_outage|fallback_normal|fallback_*|reserve_lead|cloud_read_outage|cloud_read_recovered)
      ;;
    *)
      ts=$(echo "$state" | jq -r --arg t "$type" '.[$t] // 0' 2>/dev/null || echo 0)
      ts=${ts:-0}
      if [ "$ts" != 0 ] && [ $((now - ts)) -lt "$GUARD_DEBOUNCE_SEC" ]; then
        log "debounced $type"
        return 0
      fi
      ;;
  esac
  if [ -z "${TG_BOT_TOKEN:-}" ] || [ -z "${TG_CHAT_ID:-}" ]; then
    log "telegram skipped $type"
    return 0
  fi
  if [ -f "$GUARD_DRILL_STATE" ]; then msg="УЧЕНИЯ: $msg"; fi
  if out=$(printf 'url = "https://api.telegram.org/bot%s/sendMessage"\ndata = "chat_id=%s"\ndata-urlencode = "text=%s"\n' \
      "$TG_BOT_TOKEN" "$TG_CHAT_ID" "$msg" | curl -s --max-time 10 -K - 2>&1) && \
     printf '%s' "$out" | jq -e '.ok == true' >/dev/null 2>&1; then
    case "$type" in
      form_error|gw_failed)
        echo "$state" | jq --arg t "$type" --argjson n "$now" '.form_outage_notified_at = $n | .[$t] = $n' | state_write
        ;;
      form_recovered)
        echo "$state" | jq 'del(.form_outage_started_at, .form_outage_notified_at)' | state_write
        ;;
      *) echo "$state" | jq --arg t "$type" --argjson n "$now" '.[$t] = $n' | state_write ;;
    esac
    log "sent $type"
  else
    log "send failed $type"
  fi
}

check_form() { # sets code, ssl, stopped
  local out extra rc total ip
  local -a resolve=()
  if [ -n "$GUARD_GW_HOST" ]; then
    ip=$(dig +short "$GUARD_GW_HOST" | tail -1)
    [ -n "$ip" ] || { dns_empty=1; log "check skip dns-empty"; return; }
    resolve=(--resolve "$GUARD_FQDN:443:$ip")
  fi
  out=$(curl -s --max-time 30 -o "$BODY_FILE" -w '%{http_code} %{ssl_verify_result} %{time_total}' "${resolve[@]}" "$GUARD_FORMS_URL" 2>/dev/null); rc=$?
  case "$out" in [0-9][0-9][0-9]\ *) read -r code ssl total <<<"$out" ;; *) code=000; ssl=0; total=0 ;; esac
  [ "$rc" -ne 0 ] && [ "$code" = "000" ] && ssl=0
  stopped=0
  if grep -q "is stopped and cannot be used" "$BODY_FILE" 2>/dev/null; then stopped=1; fi
  if [ "$code" = "000" ]; then
    extra=$(curl -sk --max-time 10 "${resolve[@]}" "$GUARD_FORMS_URL" 2>&1) || extra=""
    if printf '%s' "$extra" | grep -q "is stopped and cannot be used"; then stopped=1; fi
  fi
  case "$code" in 2??|3??) ;; *)
    log evidence "code=$code time_total=${total:-0} body=$(LC_ALL=C head -c 200 "$BODY_FILE" 2>/dev/null | tr '\r\n\t' '   ')" ;; esac
  if [[ $code == [23]?? ]] && awk -v t="${total:-0}" 'BEGIN{exit !(t>10)}'; then # form_slow only for working 2xx/3xx; 000/5xx is outage (form_error)
    log "медленно" "code=$code time_total=$total"
    notify form_slow "$GUARD_FQDN: медленно (${total} с), HTTP $code"
  fi
  log "check code=$code ssl=$ssl stopped=$stopped"
}

form_err_code() { # notify form_error when code is 5xx or 000
  if [ "$code" = "000" ] || { [ -n "$code" ] && [ "$code" -ge 500 ] 2>/dev/null; }; then
    notify form_error "$code"
    form_error=1
  fi
}

incident_classify() { # failed-run diagnosis: sets cls (Yandex доступен первым двум пробам)
  cls=unknown
  local c1 c2 st
  c1=$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 https://storage.yandexcloud.net/ 2>/dev/null) || true
  c1=${c1:-000}
  c2=$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 https://ya.ru/ 2>/dev/null) || true
  c2=${c2:-000}
  st="{}"
  if [ -f "$STATE_FILE" ]; then st=$(cat "$STATE_FILE" 2>/dev/null) || st="{}"; fi
  printf '%s' "$st" | jq -e . >/dev/null 2>&1 || st="{}"
  if [ "$c1" = 000 ] && [ "$c2" = 000 ]; then cls=network; return; fi
  if [ "${stopped:-0}" = 1 ]; then cls=gw_stopped; return; fi
  if printf '%s' "$st" | jq -e --argjson m "$GUARD_BALANCE_MIN" \
    '.last_active == "false" or ((try (.last_balance | tonumber) catch null) as $b | ($b | type) == "number" and $b < $m)' \
    >/dev/null 2>&1; then cls=billing; return; fi
  if [ "$dns_empty" = 1 ]; then cls=yandex_service; return; fi
  case "${code:-000}" in
    000|5??) cls=yandex_service; return ;;
  esac
  if printf '%s' "$st" | jq -e '.last_iam_ok == false or .last_active == "" or .last_active == "null" or (has("last_active") and .last_active == null)' \
    >/dev/null 2>&1; then cls=access; fi
}

incident_text() { # class → короткий текст для сообщения (класс добавляет вызывающий)
  case "$1" in
    yandex_service) printf 'Yandex API Gateway недоступен, остальной Yandex Cloud отвечает' ;;
    gw_stopped) printf 'шлюз форм остановлен в Yandex Cloud' ;;
    billing) printf 'баланс Yandex Cloud %s ₽ или аккаунт не активен' "$(jq -r '.last_balance // "неизвестен"' "$STATE_FILE" 2>/dev/null)" ;;
    access) printf 'нет доступа сторожа к Yandex Cloud (IAM/биллинг)' ;;
    network) printf 'у сервера нет сети до Yandex Cloud' ;;
    *) printf 'причина не определена (код %s)' "${code:-000}" ;;
  esac
}

incident_tier_of() { # class → уровень инцидента: инфраструктура, архитектура или код
  case "$1" in
    billing|access|network|yandex_service) printf 'инфраструктура' ;;
    gw_stopped) printf 'архитектура' ;;
    *) printf 'код' ;;
  esac
}

incident_fn_status() { # sets fn_status to the captcha function status; empty when the read fails
  local out
  if out=$(timeout "$GUARD_YC_TIMEOUT" yc serverless function get "$GUARD_CAPTCHA_FUNCTION_ID" --format json 2>/dev/null); then
    fn_status=$(printf '%s' "$out" | jq -r '.status // empty' 2>/dev/null)
  else
    log "function status read failed"
    fn_status=""
  fi
}

fallback_failed() { # failed-run bookkeeping: класс, уровень и каскад инцидента в state и лог, затем счётчик
  local st gw_down=0
  incident_classify
  tier=$(incident_tier_of "$cls")
  incident_fn_status
  if [ "${stopped:-0}" = 1 ] || { [ -n "${status:-}" ] && [ "$status" != ACTIVE ]; }; then gw_down=1; fi
  cascade=0
  if [ "$gw_down" = 1 ] && [ "$fn_status" != ACTIVE ]; then cascade=1; fi
  log "class=$cls tier=$tier cascade=$cascade"
  st='{"incident_class":"'"$cls"'","incident_tier":"'"$tier"'","incident_cascade":'"$cascade"'}'
  if [ -f "$STATE_FILE" ] && st=$(cat "$STATE_FILE" 2>/dev/null) && printf '%s' "$st" | jq -e . >/dev/null 2>&1; then
    st=$(printf '%s' "$st" | jq -c --arg c "$cls" --arg t "$tier" --argjson k "$cascade" \
      '.incident_class=$c | .incident_tier=$t | .incident_cascade=$k')
  fi
  printf '%s\n' "$st" | state_write
  fallback_track failed
}

incident_snapshot() {
  local incidents dir ip oldest
  local -a resolve=()
  incidents="$GUARD_STATE_DIR/incidents"
  dir="$incidents/$(date -u '+%Y%m%dT%H%M%SZ')"
  mkdir -p "$dir" || true
  if [ -n "$GUARD_GW_HOST" ]; then
    ip=$(dig +short "$GUARD_GW_HOST" | tail -1)
    [ -n "$ip" ] && resolve=(--resolve "$GUARD_FQDN:443:$ip")
  fi
  curl -sv --max-time 15 "${resolve[@]}" "$GUARD_FORMS_URL" > "$dir/curl.txt" 2>&1 || true
  for ns in ns1.beget.pro ns2.beget.pro ns1.beget.ru ns2.beget.ru ns1.beget.com ns2.beget.com; do
    dig +short "$GUARD_FQDN" "@$ns"
  done > "$dir/dns.txt" 2>&1 || true
  if [ -n "${GUARD_LOG_FILE:-}" ] && [ -r "$GUARD_LOG_FILE" ]; then
    tail -n 50 "$GUARD_LOG_FILE" > "$dir/guard.txt" || true
  else
    printf 'no log\n' > "$dir/guard.txt" || true
  fi
  while [ "$(ls -1d "$incidents"/*/ 2>/dev/null | wc -l)" -gt 10 ]; do
    oldest=$(ls -1d "$incidents"/*/ 2>/dev/null | sort | head -n 1)
    [ -n "$oldest" ] || break
    rm -rf "$oldest" || true
  done
  printf '%s\n' "$dir"
}

fallback_track() { # failed|success; switch only after two consecutive outcomes
  local outcome="$1" state failures successes mode target result rc dns_result dns_rc snapshot
  [ -n "${FALLBACK_PAGE_ID:-}" ] && [ -n "${FALLBACK_BLOCK_ID:-}" ] || [ -n "$DNS_SWITCH" ] || return 0
  state="{}"
  if [ -f "$STATE_FILE" ] && state=$(cat "$STATE_FILE" 2>/dev/null) && echo "$state" | jq -e . >/dev/null 2>&1; then :; else state="{}"; fi
  failures=$(echo "$state" | jq -r '.fallback_failures // 0')
  successes=$(echo "$state" | jq -r '.fallback_successes // 0')
  mode=$(echo "$state" | jq -r '.fallback_mode // "normal"')
  case "$outcome" in
    failed)
      failures=$((failures + 1)); successes=0; target=outage
      state=$(echo "$state" | jq --argjson f "$failures" --argjson s "$successes" '.fallback_failures=$f | .fallback_successes=$s')
      [ "$failures" -ge "$GUARD_FALL_N" ] && [ "$mode" != outage ] || { printf '%s\n' "$state" | state_write; return 0; }
      ;;
    success)
      successes=$((successes + 1)); failures=0; target=normal
      state=$(echo "$state" | jq --argjson f "$failures" --argjson s "$successes" '.fallback_failures=$f | .fallback_successes=$s')
      [ "$mode" = outage ] && [ "$successes" -ge "$GUARD_RISE_N" ] || { printf '%s\n' "$state" | state_write; return 0; }
      ;;
    *) return 0 ;;
  esac
  if [ "$target" = outage ]; then
    state=$(echo "$state" | jq '.outage_class = (.incident_class // "unknown") | if (.form_outage_started_at // 0) != 0 then .outage_started_at = .form_outage_started_at else . end')
  fi
  printf '%s\n' "$state" | state_write
  rc=0
  result=
  if [ -n "${FALLBACK_PAGE_ID:-}" ] && [ -n "${FALLBACK_BLOCK_ID:-}" ]; then
    result=$(bash "$FALLBACK_SWITCH" apply "$target" 2>&1); rc=$?
  fi
  if [ -n "$DNS_SWITCH" ]; then
    dns_result=$(bash "$DNS_SWITCH" apply "$target" --fqdn "$GUARD_FQDN" 2>&1); dns_rc=$?
    if [ "$dns_rc" != 0 ]; then
      if [ "$target" = outage ] && ! jq -e '.dns_fail_snapshot == true' "$STATE_FILE" >/dev/null; then
        snapshot=$(incident_snapshot)
        jq '.dns_fail_snapshot=true' "$STATE_FILE" > "$STATE_FILE.tmp" && mv -f "$STATE_FILE.tmp" "$STATE_FILE"
        log "dns switch failed: ${dns_result%%$'\n'*}; snapshot: $snapshot"
      else
        log "dns switch failed: ${dns_result%%$'\n'*}"
      fi
      [ "$rc" = 0 ] && return 0
    fi
  fi
  result=${result%%$'\n'*}
  if [ "$rc" = 0 ]; then
    jq --arg mode "$target" '.fallback_mode=$mode | del(.dns_fail_snapshot)' "$STATE_FILE" > "$STATE_FILE.tmp" && mv -f "$STATE_FILE.tmp" "$STATE_FILE"
    case "$target" in
      outage)
        snapshot=$(incident_snapshot)
        cascade_note=""
        if [ "${cascade:-0}" = 1 ]; then cascade_note=", каскад: шлюз+функция"; fi
        notify fallback_outage "$GUARD_FQDN: сбой основного канала — $(incident_text "$cls") ($cls), класс: ${tier:-код}$cascade_note, заявки принимает резерв, ждём восстановления. Статус Яндекса: https://status.yandex.cloud. Снимок: $snapshot"
        ;;
      normal)
        oc=$(jq -r '.outage_class // .incident_class // "unknown"' "$STATE_FILE" 2>/dev/null); oc=${oc:-unknown}
        started=$(jq -r '.outage_started_at // 0' "$STATE_FILE" 2>/dev/null)
        case "$started" in ''|*[!0-9]*) started=0 ;; esac
        if [ "$started" != 0 ]; then
          prob_details="сбой: $oc, длительность $(outage_duration "$(( $(date +%s) - started ))")"
        else
          prob_details="сбой: $oc"
        fi
        log "recovered class=$oc"
        notify fallback_normal "$GUARD_FQDN: восстановлено — Yandex API Gateway заработал, основной канал стабилен $GUARD_RISE_N мин, вернулись на основной ($prob_details)"
        jq 'del(.outage_class, .incident_class, .outage_started_at)' "$STATE_FILE" > "$STATE_FILE.tmp" && mv -f "$STATE_FILE.tmp" "$STATE_FILE"
        ;;
    esac
  else
    case "$result" in
      fallback_*) notify "$result" "$result" ;;
      *) notify fallback_switch "$result" ;;
    esac
  fi
}

count_captcha_reserve() { # file → captcha=unavailable lines of the last hour (pm2 stamps are local +0300)
  local f="$1" cutoff="$2" n=0 line ts
  [ -r "$f" ] || { log "captcha reserve log unreadable: $f"; return 1; }
  while IFS= read -r ts; do
    [ -n "$ts" ] || continue
    ts=$(date -d "$ts +0300" +%s 2>/dev/null) || continue
    [ "$ts" -ge "$cutoff" ] && n=$((n + 1))
  done < <(grep 'captcha=unavailable' "$f" 2>/dev/null | \
    sed -n 's/^\([0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}T[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\).*/\1/p')
  printf '%s\n' "$n"
}

check_captcha_unverified() { # at most once per hour: alert when unverified-captcha submissions exceed the limit
  local stamp="$GUARD_STATE_DIR/captcha-check.stamp" now last reserve cloud c total
  now=$(date +%s)
  if [ -f "$stamp" ]; then
    last=$(cat "$stamp" 2>/dev/null); case "$last" in ''|*[!0-9]*) last=0 ;; esac
    [ $((now - last)) -lt 3600 ] && return 0
  fi
  printf '%s\n' "$now" > "$stamp.tmp" && mv -f "$stamp.tmp" "$stamp"
  total=0
  if reserve=$(count_captcha_reserve "$GUARD_RESERVE_LOG" "$((now - 3600))"); then
    total=$(($total + reserve))
  fi
  local yerr="$GUARD_STATE_DIR/captcha-yc.err" reason fails
  if cloud=$(timeout "$GUARD_YC_TIMEOUT" yc --profile default logging read default --since 1h \
      --resource-ids "$GUARD_CAPTCHA_FUNCTION_ID" --folder-id "$GUARD_CAPTCHA_FOLDER_ID" --format json 2>"$yerr"); then
    c=$(printf '%s' "$cloud" | grep -c 'captcha=unavailable') || c=0
    total=$(($total + c))
    if [ -f "$STATE_FILE" ] && [ "$(jq -r '.cloud_outage_notified // 0' "$STATE_FILE" 2>/dev/null)" = 1 ]; then
      notify cloud_read_recovered ""
      state_put cloud_outage_notified 0 || log "cloud outage reset failed"
    fi
    if [ -f "$STATE_FILE" ] && [ "$(jq -r '.cloud_read_fail // 0' "$STATE_FILE" 2>/dev/null)" != 0 ]; then
      state_put cloud_read_fail 0 || log "cloud read reset failed"
    fi
  else
    reason=$(head -n 1 "$yerr" 2>/dev/null)
    log "captcha cloud log read failed: ${reason:-no stderr}"
    fails=$(jq -r '.cloud_read_fail // 0' "$STATE_FILE" 2>/dev/null) || fails=0
    case "$fails" in ''|*[!0-9]*) fails=0 ;; esac
    fails=$((fails + 1))
    state_put cloud_read_fail "$fails" || log "cloud read counter write failed"
    if [ "$fails" -ge 3 ] && [ "$(jq -r '.cloud_outage_notified // 0' "$STATE_FILE" 2>/dev/null)" != 1 ]; then
      if grep -q 'code = Unavailable' "$yerr"; then
        notify cloud_read_outage ""
        state_put cloud_outage_notified 1 || log "cloud outage flag write failed"
      else
        notify cloud_read_failed "$fails"
      fi
    fi
  fi
  rm -f "$yerr"
  log "captcha_unverified count=$total"
  if [ "$total" -gt "$GUARD_CAPTCHA_UNVERIFIED_MAX" ]; then
    notify captcha_unverified "$total"
  fi
}

check_reserve_leads() { # new request ids in the reserve bucket: one count alert per run; cursor last_reserve_key in state
  local initialized=0 last="" out count newest
  local -a args
  if [ -f "$STATE_FILE" ] && jq -e 'has("last_reserve_key")' "$STATE_FILE" >/dev/null 2>&1; then
    initialized=1
    last=$(jq -r '.last_reserve_key // ""' "$STATE_FILE" 2>/dev/null) || last=""
  fi
  args=(storage s3api list-objects --bucket "$GUARD_RESERVE_BUCKET" --prefix reserve/)
  if [ -n "$last" ]; then args+=(--start-after "$last"); fi
  args+=(--format json)
  if ! out=$(timeout "$GUARD_YC_TIMEOUT" yc "${args[@]}" 2>/dev/null); then
    log "reserve list failed"
    return 0
  fi
  count=$(printf '%s' "$out" | jq -r '(.contents // []) | length' 2>/dev/null) || count=""
  newest=$(printf '%s' "$out" | jq -r '(.contents // []) | last | .key // empty' 2>/dev/null) || newest=""
  case "$count" in ''|*[!0-9]*) log "reserve list unparsed"; return 0 ;; esac
  if [ "$initialized" = 1 ] && [ "$count" -gt 0 ]; then
    notify reserve_lead "$count"
  fi
  if [ "$initialized" = 0 ] || [ "$count" -gt 0 ]; then
    [ -f "$STATE_FILE" ] || printf '{}\n' > "$STATE_FILE"
    jq --arg k "$newest" '.last_reserve_key = $k' "$STATE_FILE" > "$STATE_FILE.tmp" && mv -f "$STATE_FILE.tmp" "$STATE_FILE" || log "reserve cursor write failed"
  fi
}

mkdir -p "$GUARD_STATE_DIR"

for tool in yc jq curl flock awk timeout; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    log "env missing $tool"
    notify gw_failed "нет инструмента $tool"
    exit 2
  fi
done

if ! [[ "$GUARD_REMINDER_SEC" =~ ^([0-9]+(\.[0-9]+)?|\.[0-9]+)$ ]] || \
   ! awk -v value="$GUARD_REMINDER_SEC" 'BEGIN{exit !(value>0)}'; then
  log "invalid GUARD_REMINDER_SEC=$GUARD_REMINDER_SEC"
  exit 2
fi

exec 9>"$GUARD_STATE_DIR/forms-gw-guard.lock"
if ! flock -n 9; then
  log "already running"
  exit 0
fi

check_form
[ "$dns_empty" = 1 ] && { fallback_failed; exit 0; }
if [ "$stopped" = 1 ]; then
  if out=$(timeout "$GUARD_YC_TIMEOUT" yc serverless api-gateway get "$GUARD_GW_ID" --format json 2>&1); then
    status=$(printf '%s' "$out" | jq -r .status 2>/dev/null)
    if [ "$status" = "STOPPED" ]; then
      if out=$(timeout "$GUARD_YC_TIMEOUT" yc serverless api-gateway resume "$GUARD_GW_ID" 2>&1); then
        log "resume issued"
        sleep 5
        check_form
        [ "$dns_empty" = 1 ] && { fallback_failed; exit 0; }
        if [ "$stopped" = 0 ]; then
          log "resume ok"
          notify gw_resumed "$code"
          form_err_code
        else
          log "resume pending"
          notify gw_failed "resume принят, форма всё ещё stopped"
          failed=1
        fi
      else
        log "resume failed"
        notify gw_failed "$(printf '%s' "$out" | head -c 200)"
        failed=1
      fi
    else
      notify form_error "тело stopped при статусе $status"
      form_error=1
    fi
  else
    log "resume failed"
    notify gw_failed "$(printf '%s' "$out" | head -c 200)"
    failed=1
  fi
elif [ "$ssl" != 0 ]; then
  notify form_error "TLS ssl_verify_result=$ssl"
  form_error=1
else
  form_err_code
fi

case "$code" in
  2??|3??)
    if [ "$stopped" = 0 ] && [ "$ssl" = 0 ] && [ "$failed" = 0 ] && [ "$form_error" = 0 ]; then
      notify form_recovered ""
    fi
    ;;
esac

if [ "$failed" = 1 ] || [ "$form_error" = 1 ]; then
  fallback_failed
elif [ "${code:0:1}" = 4 ]; then
  fallback_failed
elif [ "$stopped" = 0 ] && [ "$ssl" = 0 ] && { [ "${code:0:1}" = 2 ] || [ "${code:0:1}" = 3 ]; }; then
  log "class=ok"
  fallback_track success
fi

check_captcha_unverified
check_reserve_leads

state=$(jq -c . "$STATE_FILE" 2>/dev/null || printf '%s' '{}')
if [ "$(jq -r '.fallback_mode // "normal"' <<<"$state")" = outage ] && [ -n "$NPM_HOST_ID" ]; then
  all=1; for ns in ns1.beget.pro ns2.beget.pro ns1.beget.ru ns2.beget.ru ns1.beget.com ns2.beget.com; do [ "$(dig +norecurse +short "$GUARD_FQDN" "@$ns")" = "$BEGET_IP" ] || all=0; done
  if [ "$all" = 1 ] && ! curl -s -o /dev/null --max-time 10 --resolve "$GUARD_FQDN:443:127.0.0.1" "https://$GUARD_FQDN/"; then
    le_at=$(jq -r '.le_at // 0' <<<"$state"); now=$(date +%s)
    if [ $((now - le_at)) -ge 900 ]; then
      "$NPM_SSL_REQUEST" "{\"proxy_host_id\":\"$NPM_HOST_ID\"}" >/dev/null; rc=$?
      log "ssl request rc=$rc"
      jq --argjson le_at "$now" '.le_at=$le_at' "$STATE_FILE" > "$STATE_FILE.tmp" && mv -f "$STATE_FILE.tmp" "$STATE_FILE"
    fi
  fi
fi

IAM=$(timeout "$GUARD_YC_TIMEOUT" yc iam create-token 2>/dev/null)
if [ -z "$IAM" ]; then
  log "balance skipped"
  state_put last_iam_ok false || log "iam state write failed"
else
  if resp=$(printf 'url = "https://billing.api.cloud.yandex.net/billing/v1/billingAccounts"\nheader = "Authorization: Bearer %s"\n' \
      "$IAM" | curl -s --max-time 10 -K - 2>/dev/null) && \
     printf '%s' "$resp" | jq -e '.billingAccounts[0].active | type == "boolean"' >/dev/null 2>&1; then
    active=$(printf '%s' "$resp" | jq -r '.billingAccounts[0].active' 2>/dev/null)
    balance=$(printf '%s' "$resp" | jq -r '.billingAccounts[0].balance' 2>/dev/null)
    log "balance $balance active=$active"
    if [ "$active" = "true" ] && awk -v b="$balance" -v m="$GUARD_BALANCE_MIN" 'BEGIN{exit !(b+0<m+0)}'; then
      notify low_balance "$balance"
    fi
    if [ -f "$STATE_FILE" ]; then
      jq -c --arg a "$active" --arg b "$balance" '.last_iam_ok = true | .last_active = $a | .last_balance = $b' \
        "$STATE_FILE" > "$STATE_FILE.tmp" 2>/dev/null && mv -f "$STATE_FILE.tmp" "$STATE_FILE"
    fi
  else
    log "balance no answer"
    state_put last_iam_ok false || log "iam state write failed"
  fi
fi

if [ -n "${TG_BOT_TOKEN:-}" ]; then
  user="unknown"
  if out=$(printf 'url = "https://api.telegram.org/bot%s/getMe"\n' "$TG_BOT_TOKEN" | curl -s --max-time 10 -K - 2>&1); then
    user=$(printf '%s' "$out" | jq -r '.result.username // empty' 2>/dev/null)
  fi
  log "bot ${user:-unknown}"
fi

if [ "$failed" = 1 ] || [ "$form_error" = 1 ]; then exit 1; fi
exit 0
