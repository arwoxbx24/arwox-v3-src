# ТЗ dcfg-wowp4 — аномалии /doctor 09.10 (только найденные)

## U2 — убрать устаревший `.claude/CLAUDE.md` (dcfg-wowp4.2)
Причина: файл грузится каждой сессией; данные индекса в нём от 2026-09-27 (commit f07f05f) устарели; `.repowise/config.yaml` → `editor_files.claude_md: false`, repowise его больше не пишет; правила repowise уже в `projects/.claude/rules/repowise.md`.
Решение: `git rm .claude/CLAUDE.md`. Откат: `git revert <SHA>`.

Критерии:
1. `git ls-files .claude/CLAUDE.md` → 0 строк.
2. Коммит с трейлером `Atom: dcfg-wowp4.2`.
