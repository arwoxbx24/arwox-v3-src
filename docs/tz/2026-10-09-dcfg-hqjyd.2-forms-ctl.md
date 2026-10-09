# ТЗ dcfg-hqjyd.2 — forms-ctl.sh: единый скрипт управления резервом вместо demo.sh

Исполнитель пишет код сам, code-channel не вызывает. Разведка — repowise (индекс: repowise/CBM проверен, нет — `tools/bin/code-memory-enable`); читать только указанные строки. Секреты, .env, `secrets/` не читать. yc, pm2, сеть, DNS, curl, git commit/push не вызывать; тесты — только на заглушках `forms-ctl-test.sh`. ПДн — не в лог. KISS/YAGNI, минимальный дифф. План: `docs/plans/2026-10-09-1805-feat-forms-ctl-plan.md` U2, U3, KTD2–KTD4, R1–R4, R7. Зависит от dcfg-hqjyd.1: строка журнала `forms-backup lead <ISO> host=<h> code=<c> result=<r> b24=<v>`, где `<v>` = `lead:<id>` | `queue:<файл>` | `-`; доставка из очереди — строка `forms-backup spool-sent spool=<файл> b24=lead:<id>`.

## U1. Переименование (KTD2)
- `git mv forms-failover/demo.sh forms-failover/forms-ctl.sh`; `git mv forms-failover/demo-test.sh forms-failover/forms-ctl-test.sh`. Обёртки/алиаса `demo.sh` нет.
- Все литералы `demo.sh` внутри скрипта → `forms-ctl.sh`: таймер `:88` (`"$3/demo.sh" restore`), подсказка `:275`, NAME тестового лида `:291`. Имена файлов state (`demo.json`, `demo.log`, `demo.lock`, `demo.timer.pid`) и переменная `DEMO_AUTO_RESTORE` — без изменений.

## U2. Команды и флаг (R1, R2, KTD3)
- Команды: `test [--prod] [--no-feed]`, `restore [--prod]`, `status [--prod]`; `--help`/`-h` печатает usage с тремя командами, rc 0; неизвестная команда (в т.ч. `simulate`) и лишние аргументы → usage, rc 64 (`:24-32`).
- `--prod` в любой позиции после команды → `FORMS_FQDN=forms.arwox.ru`; без флага — `forms-test.arwox.ru` (`:9`). `FORMS_FQDN` остаётся внутренним хуком тестов, в usage не показывается.
- Таймер автовозврата (`:88`) передаёт цель как сейчас (через `FORMS_FQDN`).

## U3. Лента Bitrix24 (R7) — `lead_feed` `:92-125`
- `:102`: `read -r at host code result b24` — пятое поле, `result=sent` и `result=err:*` (`:108-109`) снова совпадают.
- Хвост строки по `b24`: `b24=lead:N` → ` → Bitrix24 лид #N`; `b24=queue:F` → ` → очередь резерва, дошлётся сам`; `b24=-` → ` → в Bitrix24 не передана`; поля нет (старая строка) — как сейчас.
- Строка `forms-backup spool-sent spool=F b24=lead:N` → `📬 из очереди: Bitrix24 лид #N`.
- Итог `🏆` (`:95`, `:123`): убрать утверждение про комментарий в Bitrix24, добавить счёт «в Bitrix24: K, в очереди: Q».

## U4. restore без ложного rc 124 (R4, KTD4, bd dcfg-rh17x)
- В ветке restore (`:308-347`): `restore_started=$(date +%s)` — база таймаута для обоих `wait_for` (`:335`, `:342`); `started` из state — только для строки «всего N мин» (`:345`).

## U5. Документы
- `forms-failover/README.md`, `architecture.md`: `demo.sh`/`demo-test.sh` → `forms-ctl.sh`/`forms-ctl-test.sh`; для владельца — `./forms-ctl.sh test [--prod]`, `restore [--prod]`, `status [--prod]`.

## U6. Тесты — `forms-ctl-test.sh` (бывший demo-test.sh; `cp "$DEMO"` и пути — на новое имя)
- `--help` содержит test, restore, status; `simulate` → rc 64.
- `--prod` первым и вторым аргументом → цель `forms.arwox.ru`; без флага → `forms-test.arwox.ru`.
- Лента: `b24=lead:55` → `Bitrix24 лид #55`; `b24=queue:x.json`, затем `spool-sent spool=x.json b24=lead:56` → строка очереди и `📬 из очереди: Bitrix24 лид #56`; `b24=-` → `не передана`; старая строка без `b24=` считается.
- restore при `.started` в state 20 мин назад → rc 0 и при первом ожидании, и при повторе после `apply normal`.
- Таймер вызывает `forms-ctl.sh restore`.
- Все прежние кейсы проходят.

## v2 (прогон 1: таймаут 590 с, FAIL 5/20)
Уже сделано в worktree, не переписывать: U1–U6, режим 755 у `forms-ctl.sh` восстановлен оркестратором (кейсы 15, 17, 20 прошли).
Единственная правка: `forms-ctl.sh:20` — ветка `--prod` экспортирует цель (`export FORMS_FQDN=forms.arwox.ru` вместо присваивания). Причина: дочерние команды (`yc` в тесте) видят `FORMS_FQDN` по умолчанию → кейсы 13 и 14 падают на `--domain-id forms.arwox.ru-id`. Тест не менять. Других правок нет.

## Критерии
1. `bash forms-failover/forms-ctl-test.sh` → `PASS N/N`, FAIL 0.
2. `bash -n forms-failover/forms-ctl.sh` → rc 0.
3. `grep -rnE "demo(-test)?\.sh" forms-failover architecture.md` → 0 строк.
4. `git diff --stat` — только файлы U1–U6 и этот ТЗ.

## Откат
`git revert`.

## Паспорт источников
- `grep -n` этого хода: `demo.sh:9,13-16,24-32,88,92-125,264,275,288-291,308-347`.
- bd dcfg-rh17x: `restore wait timeout=1 elapsed=924` при фактическом `dns=normal` (живой тест 09.10 17:45).
