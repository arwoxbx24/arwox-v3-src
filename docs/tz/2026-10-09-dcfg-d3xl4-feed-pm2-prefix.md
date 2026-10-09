# ТЗ dcfg-d3xl4 — лента demo.sh: строки лога pm2 с префиксом времени

Исполнитель пишет код сам, code-channel не вызывает. Разведка — repowise (индекс: repowise/CBM проверен, нет — `tools/bin/code-memory-enable`); читать только указанные строки. Секреты, .env не читать. yc, pm2, сеть, DNS, git push не вызывать. ПДн не в лог. KISS: правки только `forms-failover/demo.sh` и `forms-failover/demo-test.sh`.

## Факт живого теста 09.10 16:35
Лог `/root/.pm2/logs/forms-backup-out.log` (pm2 `time: true`) — строка:
`2026-10-09T16:39:46: forms-backup lead 2026-10-09T13:39:46Z host=forms.arwox.ru code=302 result=sent`
3 такие строки, лента показала `принято резервом: 0`.

## U1. `demo.sh:99`
`while read -r _ _ at host code result` разбирает строку без префикса pm2 → с префиксом поля сдвинуты. Разбирать от слова `forms-backup lead` независимо от префикса (например, отбросить всё до `forms-backup lead ` и читать `at host code result`). Строки без `forms-backup lead` — пропускать.

## U2. `demo-test.sh:232`
Кейс ленты: подложить строки с префиксом pm2 `2026-10-09T15:00:00: forms-backup lead …`; добавить один кейс со строками без префикса (прежний формат) — оба дают `Заявка №1`, `Заявка №2`, `🏆 Резерв принял 2`.

## v2 — дефект автовозврата (живой тест 09.10 16:51)
Прогон 1: правки U1–U2 в дереве оставить (`PASS 19/19`). Факт `state/demo.log`: `13:51:07Z restore start fqdn=forms.arwox.ru` → `restore result rc=75` — таймер автовозврата получил отказ блокировки: `simulate` держит `flock` (fd 9, `demo.sh:69-78`, вызов `:263`) всё время ленты (`:305`). Боевой адрес остался на резерве.
- U3. Перед `lead_feed` (`:305`) снять блокировку simulate (`flock -u 9; exec 9>&-`), чтобы автовозврат и ручной `restore` работали во время ленты.
- U4. Лента кончается к сроку таймера: срок = момент `start_auto_restore` (`:283`) + `AUTO_RESTORE_SEC`, а не старт ленты.
- U5. Тест: во время ленты (`DEMO_FEED=1`, `AUTO_RESTORE_SEC=2`) таймер вызывает `apply normal` (заглушка dns-switch фиксирует), `restore` не rc 75.

## Критерии
1. `bash forms-failover/demo-test.sh` → `PASS N/N`, N = 20.
2. `bash -n forms-failover/demo.sh` rc 0.
3. `git diff --stat` — только `demo.sh`, `demo-test.sh`, этот ТЗ.

## Откат
`git revert`.

## Паспорт источников
- `grep -n` этого хода: `demo.sh:99`, `demo-test.sh:232`; строка лога — `grep "forms-backup lead" /root/.pm2/logs/forms-backup-out.log`.
