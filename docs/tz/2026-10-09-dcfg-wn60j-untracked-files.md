# ТЗ dcfg-wn60j — неотслеживаемые файлы живой копии в GitHub

## U1
Слово владельца 09.10: всё, что есть на сервере, должно быть в GitHub. Добавить:
- `AGENTS.md` (единственная правка: `demo.sh` → `forms-ctl.sh test` / `--prod`, скрипт переименован в PR #18)
- `docs/solutions/architecture-patterns/b24-outcome-thread-local-without-contract-change.md` (ссылка на коммит → PR #18, факт живого теста)
- `docs/solutions/integration-issues/beget-dns-api-method-failed-zone-only-subdomain.md`
- `docs/tz/2026-10-09-dcfg-1ci20.32-prod-dns-switch.md`

`.claude/workflows/code-atom.js` не добавляется: побайтная копия `projects/.claude/workflows/code-atom.js` (cmp — без различий), уже в GitHub репозитория projects (коммит 1bc90653d).

## Критерии
1. `git ls-tree origin/main` по 4 путям → 4 строки.
2. Живая копия `git status --short` → только `.claude/workflows/`.

## Откат
`git revert`.
