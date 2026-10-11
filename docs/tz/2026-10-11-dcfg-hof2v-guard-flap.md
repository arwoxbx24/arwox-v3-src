# ТЗ dcfg-hof2v — сторож форм: без флапа, 2 сообщения на сбой

Атом: dcfg-hof2v. Worktree: `/root/workspaces/projects/arwox-v3-src/.worktrees/claude/dcfg-hof2v`. Разведка — repowise (`get_context` по `forms-failover/forms-gw-guard.sh`), затем `grep -n`; индекс: repowise/CBM проверен.

## Проблема (факты)
Ночь 11.10: Yandex API Gateway то отвечал, то нет; сторож (pm2 cron раз в минуту) слал ~99 сообщений Telegram и дёргал DNS туда-обратно.
- `forms-gw-guard.sh:187` — переход на резерв после 2 сбоев; `:192` — возврат после 2 успехов (симметрично, 2 минуты).
- `:296` — `notify form_recovered` после одного успеха; `:105` при recovered стирает `form_outage_started_at/notified_at` → каждый флап = новый инцидент и новое сообщение.
- `:82-83` — `fallback_*` без дедупа.
- `:302-303` — любой код кроме `000` (в т.ч. 4xx) считается успехом.
- Тестовый сторож (`/root/workspaces/tools/ecosystem.config.js:256`, `forms-gw-guard-test`) наследует Telegram-переменные и шлёт столько же сообщений.

## U1. Гистерезис (только `forms-failover/forms-gw-guard.sh`, функция `fallback_track` и вызов `:300-304`)
1. Переход на резерв: `GUARD_FALL_N` подряд сбоев, по умолчанию 3.
2. Возврат с резерва: `GUARD_RISE_N` подряд успехов, по умолчанию 15 (≈15 мин при cron 1 мин). Любой сбой обнуляет счёт успехов.
3. Успех = код 2xx/3xx, не stopped, ssl 0. 4xx/5xx/000 = сбой.
4. Аварийный уход на резерв ничем не задерживается (никакого общего запрета переключений).

## U2. Сообщения (функция `notify`, `:36-110`)
1. Когда задан `DNS_SWITCH` (резерв настроен), `form_error` и `form_recovered` в Telegram НЕ отправляются — только строка в лог. Напоминания `GUARD_REMINDER_SEC` для них тоже не шлются.
2. На инцидент ровно 2 сообщения:
   - `fallback_outage`: «⚠️ <FQDN>: сбой основного канала, заявки принимает резерв. Снимок: …»
   - `fallback_normal`: «✅ <FQDN>: основной канал стабилен 15 мин, вернулись на основной.»
3. Ошибки самого переключения (`:224-225`, `fallback_switch`, `gw_failed`, `low_balance`) — как сейчас, не трогать.
4. Новый env `GUARD_NOTIFY` (по умолчанию `1`). `0` → `notify` пишет только лог, Telegram не вызывается.

## U3. Тестовый сторож без Telegram
`/root/workspaces/tools/ecosystem.config.js:256` (блок `forms-gw-guard-test`): добавить в `env` `GUARD_NOTIFY: '0'`. Больше в файле ничего не менять. Проверка: `node --check`.

## U4. Тесты (`forms-failover/forms-gw-guard-test.sh`, добавить кейсы к существующим 33)
1. Флап: 60 прогонов, чередование 000/302 → 0 переключений DNS-заглушки, 0 сообщений Telegram-заглушки.
2. Жёсткий сбой: 3 прогона 000 → 1 вызов `DNS_SWITCH apply outage`, 1 сообщение `fallback_outage`.
3. Возврат: после outage 14 успехов → возврата нет; 15-й → 1 `apply normal`, 1 сообщение `fallback_normal`; сбой на 10-м успехе обнуляет счёт.
4. 4xx (404) считается сбоем.
5. `GUARD_NOTIFY=0` → 0 обращений к Telegram при переключении.
Итог: `bash forms-failover/forms-gw-guard-test.sh` → `PASS N/N`, N ≥ 38; число в строке итога обновить.

## Угрозы (prod §3) и откат (prod §5)
- Сторож — runtime прод-формы. Риск: не уйти на резерв при реальном сбое → тест U4.2 обязателен.
- Секреты: `secrets/` не читать, токены Telegram не печатать. ПДн заявок — не в логи.
- Откат: `git revert` коммита атома; ecosystem — удалить строку `GUARD_NOTIFY: '0'`. Состояние сторожа не мигрирует (новые поля по умолчанию 0).

## Запреты
Не трогать: `dns-switch.sh`, `index.py`, `server.py`, `forms-fallback-switch.sh`, фронт `src/`, боевой DNS, `pm2` (не перезапускать), очередь `/var/lib/forms-backup/spool`. Не запускать реальный сторож и `forms-ctl.sh`. Без новых зависимостей и файлов, кроме тестовых кейсов. Принципы: KISS, YAGNI, DRY — одна логика порогов в `fallback_track`, без копий.

## v2 — правки по ревью Codex (11.10, сверены с кодом)
1. `forms-gw-guard.sh:252` `[ "$dns_empty" = 1 ] && exit 0` — сторож выходит до счётчика: при падении DNS шлюза резерв не включится. Пустой DNS шлюза = сбой для `fallback_track` (без отдельного сообщения), затем выход. Тест: 3 прогона с пустым DNS → `apply outage`.
2. `GUARD_NOTIFY=0`: в начале скрипта `unset TG_BOT_TOKEN TG_CHAT_ID` — тогда молчат и `notify`, и `getMe` (`:335`), и дочерний `dns-switch.sh` (`:27` пропускает без токена). Отдельной логики в `notify` для `GUARD_NOTIFY` не нужно. Тест AC5: переключение при `GUARD_NOTIFY=0` и заданных TG_* → 0 обращений к Telegram-заглушке (и от сторожа, и от DNS-заглушки).
3. Поля инцидента (`form_outage_started_at/notified_at`, `:105`) очищаются при восстановлении всегда, независимо от того, ушло ли сообщение в Telegram.
4. Старые кейсы с порогами 2/2 (напр. `case8:292`, `case6:279`) — обновить ожидания под 3/15; это смена поведения по критериям, не ослабление. Каждый изменённый кейс — перечислить в отчёте.
5. Предел (признан): при бесконечном чередовании 000/302 сторож остаётся на основном канале — так задумано (AC1); длительная частичная деградация вне этого атома.

## Прогон 2 — только это (прогон 1: run=124 t=581, `FAIL 17/38`)
Правки прогона 1 в `forms-gw-guard.sh` (пороги, notify, 2xx/3xx) — оставить. Сделать по порядку, не трогая остальное:
1. Старые кейсы 1–33 проверяют механику на порогах 2/2. В `fallback_setup` и `snapshot_setup` (и других setup старых кейсов, где переключение) добавить `export GUARD_FALL_N=2 GUARD_RISE_N=2`. Ожидания старых кейсов не менять. Новые кейсы 34–38 в начале делают `export GUARD_FALL_N=3 GUARD_RISE_N=15` явно.
2. 4xx = сбой: в главном блоке (`:312-316`) ветка `fallback_track failed` срабатывает и при коде 4xx (не 2xx/3xx, не 000-сбой уже учтён). Без сообщения form_error для 4xx.
3. v2 п.1: `:252` пустой DNS шлюза → `fallback_track failed`, потом `exit 0`. Кейс 39: 3 прогона с пустым DNS → `apply outage`.
4. v2 п.2: убрать блок `GUARD_NOTIFY` из `notify`; вместо него в начале скрипта `[ "$GUARD_NOTIFY" = 0 ] && unset TG_BOT_TOKEN TG_CHAT_ID`. Кейс 38: экспортировать `TG_BOT_TOKEN=t TG_CHAT_ID=c` и проверить 0 записей в Telegram-заглушке.
5. v2 п.3: при `form_recovered` с подавленным сообщением поля `form_outage_started_at/notified_at` всё равно удалить.
6. В новых кейсах `local i` в циклах.
7. Итог печатает `/39`. Один прогон `bash forms-failover/forms-gw-guard-test.sh` в конце; если FAIL — отчёт с номерами и причиной, без новых циклов правок.

## Готово, когда
1. `bash forms-failover/forms-gw-guard-test.sh` → `PASS N/N`, N ≥ 38.
2. `bash -n forms-failover/forms-gw-guard.sh` rc 0; `node --check /root/workspaces/tools/ecosystem.config.js` rc 0.
3. `git diff --stat` — только `forms-gw-guard.sh`, `forms-gw-guard-test.sh` (+ строка в ecosystem вне репо).
