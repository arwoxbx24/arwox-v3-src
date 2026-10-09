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

## U2 — ТЗ v2: изоляция проектных правил от глобальных (dcfg-jkd6x)
Причина: слово владельца 09.10 — глобальные и проектные инструкции не смешивать, не перегружать контекст. Дефект U1: `AGENTS.md` повторял законы `projects/CLAUDE.md` и `~/.codex/AGENTS.md`; `CLAUDE.md` импортировал `prd.md` и `architecture.md` на каждый старт.

Решение (ADR): `AGENTS.md` — только дельта проекта (стек, зоны, runtime для prod, инварианты бэкенда и DevOps); `CLAUDE.md` — один импорт `@AGENTS.md`; `prd.md` и `architecture.md` — чтение по требованию.

Источник: code.claude.com/docs/en/memory — «Imports help you organize a long file but don't reduce its context cost, because imported files also load at launch.»

Критерии:
1. `grep -c -E "^@" CLAUDE.md` → 1.
2. `grep -c -E "code-channel|ship-post|repowise|csb|ПРИНЦИПЫ|projects/AGENTS.md" AGENTS.md` → 0.
3. `wc -c` CLAUDE.md + AGENTS.md < 1030 + 5957.

## U3 — ТЗ v3: инструкция владельца дословно (dcfg-3v3z1)
Причина: слово владельца 09.10 — инструкции текущей директории; «строго следовать моим требованиям, а также инструкция» + вставленный текст.
Решение: текст владельца дословно разделом в начале `AGENTS.md`; Claude получает его через `@AGENTS.md`, Codex — нативно.

Критерии:
1. `grep -c -F "Never claim completion" AGENTS.md` → 1.
2. `grep -c -F "A clear stopping condition" AGENTS.md` → 1.
3. `grep -c -E "^@AGENTS.md$" CLAUDE.md` → 1.
