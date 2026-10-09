# ТЗ dcfg-n575n — контрольные MD arwox-v3-src для Claude и Codex

## U1 — один источник правил проекта
Цель: при входе в `arwox-v3-src` Claude и Codex получают одни правила: prod, бэкенд, DevOps, методология.

Решение (ADR): общий `AGENTS.md`; `CLAUDE.md` импортирует `AGENTS.md`, `prd.md`, `architecture.md`; факты — в `architecture.md`, правила — в `AGENTS.md`, требования — в `prd.md`.

Паспорт источников:
- code.claude.com/docs/en/memory — «Imported files are expanded and loaded into context at launch alongside the CLAUDE.md that references them.»; при наличии `CLAUDE.md` Claude читает AGENTS.md только через `@AGENTS.md`.
- learn.chatgpt.com/docs/agent-configuration/agents-md — «Starting at the project root (typically the Git root), Codex walks down to your current working directory.» У проекта свой `.git` → `projects/AGENTS.md` Codex не грузит сам.
- learn.chatgpt.com/docs/build-skills — `$HOME/.agents/skills`; вызов `$<имя>` → `$prod` (`/root/.agents/skills/prod/SKILL.md`, `name: prod`).

Критерии:
1. `grep -c -E "^@(AGENTS|prd|architecture)\.md$" CLAUDE.md` → 3.
2. `grep -c -E "projects/AGENTS\.md|\$prod" AGENTS.md` ≥ 2.
3. `grep -c -E "^## (Бэкенд|DevOps)" architecture.md` → 2.
4. `wc -l` каждого файла < 200.

Границы: `.claude/CLAUDE.md` (генерирует repowise) и `docs/*` дизайна не трогать; код не трогать.
