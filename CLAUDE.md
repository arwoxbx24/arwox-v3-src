# arwox-v3-src

Правила проекта — общий для Claude и Codex `AGENTS.md`; цель — `prd.md`; устройство — `architecture.md`. Импорты ниже грузят их при старте сессии (code.claude.com/docs/en/memory: «Imported files are expanded and loaded into context at launch»).

@AGENTS.md
@prd.md
@architecture.md

---

Правила наследуются из /root/workspaces/projects/CLAUDE.md (инструменты — TOOLS-REGISTRY.md, цели — beads-mcp)

## Claude — адаптация
- Первый ход — `Skill csb`; разработка и приёмка — `Skill prod` (AGENTS.md §«prod»).
- Код — Workflow code-atom → code-channel; Edit — только MD/JSON.
- Субагенту и ТЗ исполнителю — разделы «Бэкенд» и «DevOps» AGENTS.md строками в ТЗ: субагент может не грузить проектные инструкции.

---

<!-- TEMPLATE_VERSION: v1 -->
