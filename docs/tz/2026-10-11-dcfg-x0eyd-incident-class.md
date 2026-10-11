# ТЗ dcfg-x0eyd — сторож форм: класс инцидента, 2 сообщения на инцидент

Разведка — repowise (индекс arwox-v3-src, HEAD 5582206); индекс: repowise/CBM проверен.
Worktree: `/root/workspaces/projects/arwox-v3-src/.worktrees/claude/dcfg-x0eyd` (ветка `claude/dcfg-x0eyd-incident-class`). Править только здесь.
Принципы: KISS, YAGNI, fail fast; без новых файлов, без абстракций; минимальный дифф.

## Источники (паспорт)
- Машинного API статуса Yandex Cloud нет: https://yandex.cloud/ru/docs/support/notify — «Техническая поддержка не рассылает уведомления об инцидентах платформы. Вы можете проверить доступность сервисов на странице статуса компонентов платформы или следить за оповещениями в телеграм-канале». status.yandex.cloud не опрашивать (капча для роботов) — только ссылка в тексте сообщения.
- Факт 11.10: шлюз `*.apigw.yandexcloud.net` → TCP timeout; `https://storage.yandexcloud.net/` → 200 за 0.2 с.

## U1. Класс инцидента (только `forms-failover/forms-gw-guard.sh`)
Функция `incident_classify` (одна, case/if, без новых файлов). Вызывается в каждом запуске, где исход = failed (места вызова `fallback_track failed`: `:265`, `:274`, `:314`, `:316`). Порядок правил — первый сработавший:
1. `network` — и `curl -s -o /dev/null --max-time 5 https://storage.yandexcloud.net/`, и `curl ... --max-time 5 https://ya.ru/` не дали HTTP-код (000). Значит, у сервера нет сети до Яндекса.
2. `gw_stopped` — `$stopped = 1`.
3. `billing` — из state прошлого запуска: `.last_active == "false"` или `.last_balance` число < `GUARD_BALANCE_MIN`.
4. `yandex_service` — `code = 000` или `code` 5xx или `dns_empty = 1` (шлюз Яндекса не отвечает, а остальной Yandex Cloud отвечает — правило 1 не сработало).
5. `access` — `.last_iam_ok == false` или `.last_active` = null/пусто (нет доступа сторожа к облаку), при прочих сбоях (например 4xx).
6. `unknown` — иначе.
Пробы сети (правило 1) — только в failed-запусках, каждая `--max-time 5`.
- Блок баланса (`:335-345`): записывать в state `.last_iam_ok` (true/false по пустому IAM), `.last_balance`, `.last_active` (как пришли из ответа, в т.ч. null). Тексты и логика low_balance не меняются.
- State: на каждом failed-запуске `.incident_class=<класс>`; в момент переключения в outage (fallback_track, ветка `outage`, `:231`) — `.outage_class=<класс>`. На success-запуске `.incident_class` не трогать.
- Лог: каждый запуск пишет `class=<класс>` (на success — `class=ok`) одной строкой через существующий `log`.

## U2. Тексты 2 сообщений (fallback_track `:229-233`; типы уведомлений не добавлять)
- `fallback_outage`: `"$GUARD_FQDN: сбой — <текст класса>. Заявки принимает резерв, ждём восстановления. Статус Яндекса: https://status.yandex.cloud. Снимок: $snapshot"`.
- Тексты классов: `yandex_service` → «Yandex API Gateway недоступен, остальной Yandex Cloud отвечает»; `gw_stopped` → «шлюз форм остановлен в Yandex Cloud»; `billing` → «баланс Yandex Cloud <last_balance> ₽ или аккаунт не активен»; `access` → «нет доступа сторожа к Yandex Cloud (IAM/биллинг)»; `network` → «у сервера нет сети до Yandex Cloud»; `unknown` → «причина не определена (код <code>)». В тексте также имя класса в скобках, например `(yandex_service)`.
- `fallback_normal`: `"$GUARD_FQDN: восстановлено — Yandex API Gateway заработал, основной канал стабилен $GUARD_RISE_N мин (сбой: <outage_class>, длительность <outage_duration>)"`. `<outage_class>` = `.outage_class // .incident_class // "unknown"` (прод уже в outage без этих полей — первый возврат должен работать). Длительность — существующая `outage_duration` (`:33`), если применима; иначе без неё.
- Лог при возврате: `recovered class=<outage_class>`; после возврата удалить `.outage_class`, `.incident_class` из state.
- Количество сообщений не меняется: на инцидент только fallback_outage + fallback_normal (существующий гистерезис 3/15 и дедуп — не трогать).

## U3. Тесты (`forms-failover/forms-gw-guard-test.sh`, к существующим 40)
Использовать существующие заглушки curl/yc/dig (`:146-175`); для правила 1 — заглушка curl отвечает 000 на storage.yandexcloud.net и ya.ru по файлу-сценарию в `$GUARD_TEST_TMP`.
- 6 кейсов — по одному на класс: `jq -r .incident_class state.json` = ожидаемый класс; в логе строка `class=<класс>`.
- Кейс «сбой → возврат»: 3 запуска 000 + 15 запусков 302 → ровно 2 отправки Telegram (по существующему счётчику отправок в заглушке curl api.telegram.org); 1-я содержит `yandex_service` и «ждём восстановления», 2-я — «восстановлено» и «Yandex API Gateway»; в логе `recovered class=yandex_service`.
- Кейс «старт в outage без outage_class» (как прод сейчас): state `fallback_mode=outage`, 3 запуска 000 → 0 отправок; затем 15 × 302 → 1 отправка с «восстановлено».
- Существующий флап-кейс должен по-прежнему давать 0 отправок.
- Итог `PASS N/N`, N ≥ 46; строки итога и цикл кейсов обновить под N.
- Тест-first: сначала новые кейсы без U1/U2 — показать FAIL (вывод), затем код — PASS.

## Угрозы (prod §3) и откат (prod §5)
- Новые входы: 2 исходящих HTTPS-пробы (storage.yandexcloud.net, ya.ru) только при сбое; секретов, прав, ПДн нет. В текст Telegram не попадают токены (только класс, баланс, код).
- Время запуска: +≤10 с только в failed-запусках; итог должен оставаться < 60 с.
- Откат: `git revert` коммита; новые поля state игнорируются старым кодом.

## Запреты
Не трогать: `dns-switch.sh`, `index.py`, `server.py`, `/root/workspaces/tools/ecosystem.config.js`, `secrets/`, `.env`, пороги 3/15 (`GUARD_FALL_N`, `GUARD_RISE_N`), таймауты yc, pm2, боевой DNS, реальные вызовы yc/Telegram. Без коммита (коммит делает ship-post). Правки только в двух файлах выше.

## v2 (11.10) — причина: попытка 1 ушла в таймаут 590 с на пробных сценариях, правок 0
- ПРОБЫ ЗАПРЕЩЕНЫ: не писать `.probe-*`, сценарии, временные скрипты; не запускать guard вручную. Сразу правка двух файлов, затем один прогон `bash forms-failover/forms-gw-guard-test.sh | tail -3`.
- Факты harness (уже сняты, не перепроверять):
  - Отправки Telegram пишутся в `$tmp/sent.log` (`:117`), считать `wc -l < "$tmp/sent.log"` / `grep -c`.
  - Заглушка curl: ветка `*)` (`:139-141`) отдаёт код из `$GUARD_TEST_TMP/forms.code` для ЛЮБОГО адреса. Поэтому добавить в заглушку ДО `*)` ветку `https://storage.yandexcloud.net/*|https://ya.ru/*)`: печатать `$(cat "$GUARD_TEST_TMP/net.code" 2>/dev/null || echo 200)`. Без этого все 000-кейсы станут `network`.
  - Шаблоны кейсов «сбой → возврат»: `case35` (`:682`) и `case36` (`:693`) — `snapshot_setup`, `export GUARD_FALL_N=3 GUARD_RISE_N=15`, `dns_success_setup`, `run_guard`. Новые кейсы — копией этой схемы, номера 41+.
  - Существующие проверки текста: `case35` ищет «сбой основного канала», `case36` — «стабилен 15 мин». Новый текст outage обязан содержать «сбой основного канала»: `"$GUARD_FQDN: сбой основного канала — <текст класса> (<класс>). Заявки принимает резерв, ждём восстановления. Статус Яндекса: https://status.yandex.cloud. Снимок: $snapshot"`. Текст normal из U2 содержит «стабилен $GUARD_RISE_N мин» — сохранить. Существующие проверки не ослаблять и не удалять.
  - Цикл кейсов `:790`, итоги `:793`, `:796` — заменить 40 на новое N.
- Кейс `network`: `printf '000\n' > "$tmp/net.code"`; остальные кейсы этот файл не создают.

## v3 (11.10, атом dcfg-x0eyd.4) — причина: попытка 2 записала код, тест `FAIL 12/48 (PASS 36/48)`
Код U1–U3 уже в worktree (`git diff`). НЕ переписывать заново — только найти и исправить причину падений.
- Упали: 6, 8, 14, 15, 24 (старые) и 41, 42, 43, 44, 45, 46, 47 (новые). В 41–47 `sent.log` не создаётся: при сбое не уходит ни одного сообщения, хотя `case35` с той же настройкой шлёт 1.
- Диагностика (без проб-файлов): каталог теста удаляется `trap rm -rf` (`:13`), поэтому временно добавить в упавший кейс (например `case45`) строку `tail -8 "$tmp/guard.log" >&2` после трёх `run_guard`, прогнать тест один раз, прочитать вывод, строку удалить. Итоговый дифф не содержит отладки.
- Гипотезы проверить первыми: (а) `fallback_failed` пишет state ДО `fallback_track` — если state не было, создаётся `{"incident_class":…}` без полей, которые ждёт `fallback_track`/fallback-page; (б) `incident_text`/`$cls` под `set -u` в ветке, где `incident_classify` не вызывался; (в) `jq` в `fallback_track` выдаёт многострочный JSON (`state=$(echo … | jq …)` без `-c`).
- Существующие проверки кейсов 1–40 не ослаблять, не удалять, не менять ожидаемые числа.
- Готово: `bash forms-failover/forms-gw-guard-test.sh | tail -1` → `PASS 48/48`; `bash -n` rc 0.

## v4 (11.10, атом dcfg-x0eyd.4) — причина найдена оркестратором, только 4 правки, без диагностики
1. `forms-gw-guard.sh:283` (текст fallback_outage): `Заявки принимает резерв` → `заявки принимает резерв` (строчная «з»; старые кейсы 6, 14, 24 ищут `заявки принимает резерв`, `:301`, `:381`, `:544`). Итог: `"$GUARD_FQDN: сбой основного канала — $(incident_text "$cls") ($cls), заявки принимает резерв, ждём восстановления. Статус Яндекса: https://status.yandex.cloud. Снимок: $snapshot"`.
2. `forms-gw-guard.sh` текст fallback_normal: вернуть фразу `вернулись на основной` (кейсы 8, 14 ищут её, `:318`, `:382`). Итог: `"$GUARD_FQDN: восстановлено — Yandex API Gateway заработал, основной канал стабилен $GUARD_RISE_N мин, вернулись на основной ($prob_details)"`.
3. `forms-gw-guard-test.sh` `cls_setup`: добавить `unset GUARD_NOTIFY` (case38 `:752` экспортирует `GUARD_NOTIFY=0`, утечка выключает уведомления в 41–47).
4. Удалить отладку попытки 3: в `case6` строку `tail -6 "$tmp/guard.log" >&2`; в `case45` строки `echo "== after1"…`, `run_guard; cat "$tmp/state/state.json" >&2`, `tail -8 …>&2`, `tail -4 …>&2` (case45 = cls_setup + 3 run_guard + проверки).
Затем один прогон `bash forms-failover/forms-gw-guard-test.sh 2>/dev/null | tail -3`. Если что-то ещё падает — исправить только это, проверки не ослаблять.

## Готово, когда
1. `bash -n forms-failover/forms-gw-guard.sh` rc 0.
2. `bash forms-failover/forms-gw-guard-test.sh | tail -1` → `PASS N/N`, N ≥ 46.
3. `grep -c incident_classify forms-failover/forms-gw-guard.sh` ≥ 2.
4. `git status --porcelain` → только два файла выше и этот ТЗ.
