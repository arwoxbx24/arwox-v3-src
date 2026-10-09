# ТЗ dcfg-hqjyd.4 — forms-ctl.sh: исправления по code review (один проход)

Исполнитель пишет код сам, code-channel не вызывает. Разведка — repowise (индекс: repowise/CBM проверен, нет — `tools/bin/code-memory-enable`); читать только указанные строки. Секреты, .env, `secrets/` не читать. yc, pm2, сеть, DNS, curl, bd, git commit/push не вызывать; тесты — только на заглушках. KISS/YAGNI, минимальный дифф. Правки только в `forms-failover/forms-ctl.sh` и `forms-failover/forms-ctl-test.sh`. Документы не трогать (уже исправлены). Файл `forms-ctl.sh` в индексе git; режим 755 сохранить.

## F1 (P1). Состояние и таймер — свои у каждого адреса
`forms-ctl.sh:29,32`: `STATE="$DIR/state/demo-$FQDN.json"`, `TIMER_PID="$DIR/state/demo-$FQDN.timer.pid"`. `LOG` и `LOCK` — без изменений (общие). Итог: `restore` без `--prod` не убивает таймер боевого теста и не читает его `started`.
Тест: `test --prod` с живым таймером (`RUN_TIMER=1 AUTO_TIMER_HOLD=1`), затем `restore` без `--prod` → PID-файл боевого адреса на месте, процесс таймера жив. Пути `demo.json`/`demo.timer.pid` в существующих кейсах (`forms-ctl-test.sh:167,173,237-247`) → `demo-forms-test.arwox.ru.json` / `demo-forms-test.arwox.ru.timer.pid`.

## F2 (P2). Второе ожидание restore — своя база
`forms-ctl.sh:366`: повторный `wait_for` после `dns-switch.sh apply normal` считает таймаут от момента повтора: `wait_for "$GW" "$(date +%s)" '' '' 600`. Первый (`:359`) — без изменений.
Тест (замена проверки в `case6`, `:165-170`, или новый кейс): после `apply normal` заглушка `dig` ещё несколько опросов отдаёт A-запись и только потом CNAME (например, счётчик в `$DEMO_TMP`; часы заглушки `sleep` продвигаются как сейчас) → `restore` rc 0 и строка `⚠️ сторож не вернул DNS`. Кейс обязан падать, если в `:366` вернуть `$restore_started`.

## F3 (P3). «📬 из очереди» — только для спулов этого теста
`lead_feed` (`forms-ctl.sh:109-118`): одна проверка `[[ " $queued_spools " == *" $spool "* ]]`; внутри неё — уменьшение `b24_queue`, увеличение `b24_leads` и печать `📬 из очереди: Bitrix24 лид #${BASH_REMATCH[1]}`; переменная `lead_id` не нужна.
Тест: строка `spool-sent spool=other.json b24=lead:77` без предшествующей `b24=queue:other.json` → в выводе нет `лид #77`.

## F4. Мёртвая ветка
`forms-ctl.sh` последняя ветка `*) usage ;;` в `case "$COMMAND"` недостижима (`COMMAND` проверен в `:11-15`) — удалить.

## Не делать
`--prod` до команды; тест сброса `B24_OUTCOME` в `server.py`; документы.

## Критерии
1. `bash forms-failover/forms-ctl-test.sh` → `PASS N/N`, FAIL 0, N > 20.
2. `bash -n forms-failover/forms-ctl.sh` → rc 0.
3. Изменены только `forms-ctl.sh` и `forms-ctl-test.sh`.

## Откат
`git revert`.

## Паспорт источников
- ce-code-review 09.10, run `/tmp/compound-engineering-0/ce-code-review/20261009-hqjyd/` (correctness.json, testing.json, adversarial.json).
- `grep -n` этого хода: `forms-ctl.sh:29` (`STATE=`), `:32` (`TIMER_PID=`), `:115` (`📬`), `:333` (`restore_started=`), `:359`, `:366` (`wait_for "$GW" "$restore_started"`); `forms-ctl-test.sh:167,173,237,238,240,246,247` (пути state).
