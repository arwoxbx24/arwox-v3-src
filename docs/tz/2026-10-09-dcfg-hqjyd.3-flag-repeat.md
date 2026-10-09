# ТЗ dcfg-hqjyd.3 — forms-ctl.sh: повтор флага не ошибка

Исполнитель пишет код сам, code-channel не вызывает. Разведка — repowise (индекс: repowise/CBM проверен, нет — `tools/bin/code-memory-enable`); читать только `forms-failover/forms-ctl.sh:16-24`. Секреты, .env, `secrets/` не читать. yc, pm2, сеть, DNS, curl, bd, git commit/push не вызывать. KISS/YAGNI. Правка только в `forms-failover/forms-ctl.sh`; тест `forms-ctl-test.sh` не менять.

## Причина
Обёртка теста `run_demo` (`forms-ctl-test.sh:127`) добавляет `--no-feed`; кейс 13 (`:212`) передаёт его сам → `test --no-feed --prod --no-feed` → rc 64 из-за проверки повтора (`forms-ctl.sh:20-21`). Повтор флага безвреден.

## U1. Разбор аргументов `forms-ctl.sh:16-24`
- `--prod` → `export FORMS_FQDN=forms.arwox.ru`, без проверки повтора; переменная `PROD` удаляется, если больше нигде не используется (проверить `grep -n PROD`).
- `--no-feed` → `NO_FEED=1`; допустим только для `test` (иначе usage, rc 64), повтор не ошибка.
- Любой другой аргумент → usage, rc 64 (как сейчас).

## Критерии
1. `bash forms-failover/forms-ctl-test.sh` → `PASS 20/20`.
2. `bash -n forms-failover/forms-ctl.sh` → rc 0.
3. Изменён только `forms-failover/forms-ctl.sh`.

## Откат
`git revert`.

## Паспорт источников
- Прогон оркестратора этого хода: `forms-ctl-test.sh` → `FAIL case 13`, `FAIL 1/20 (PASS 19/20)`.
- `grep -n` этого хода: `forms-ctl.sh:20` (`--prod) [ "$PROD" = 0 ] || { usage; exit 64; }; PROD=1; export FORMS_FQDN=forms.arwox.ru`); `forms-ctl-test.sh:127` (обёртка добавляет `--no-feed`), `:212` (`run_demo test --no-feed --prod`).
