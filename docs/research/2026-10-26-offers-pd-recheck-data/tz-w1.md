# TZ dcfg-hfkdm.1 / W1 — draft instructions for an external Claude Web validator agent (offers vs 152-FZ)

FILE: AGENTS.md
FILE: landing/README.md
FILE: landing/dev-lids.txt
FILE: specs/offers-pd/law-152fz.md
FILE: landing/site78/384/additional-fields.json

Goal: write the full text of a Markdown instruction file for a separate agent (Claude on the web, claude.ai, possibly with a GitHub connector or MCP, possibly without). That agent will: open the live arwox.ru offer pages, read the repository arwoxbx24/arwox-v3-src, find personal-data (152-FZ) errors in the offers, and write its findings into ONE file in the repository. It never changes site pages or landing files; the lead agent on the server later confirms or rejects each finding and applies accepted ones. Read only. No edits, no shell, no git, no web. Output the file text only.

The instruction text must be in English (repo rule: agent instructions are written in English) and contain these sections, every fact taken from the five files (quote file:line in an HTML comment `<!-- src: file:line -->` after each fact; a fact not in the files → write `TODO(lead): <what is missing>`):

1. Role and limits — validator only. Allowed: read live pages, read the repo, write one findings file on its own branch. Forbidden: editing landing/**, src/**, forms-failover/**, any Bitrix24 write, submitting site forms, personal data of real people in any text, secrets.
2. Scope — the offer pages: prod lids 384, 390, 392, 394, 396 on site 78 (arwox.ru), their repo files `landing/site78/<lid>/block-*.public.html` (published text) and `block-*.draft.html` (draft, must match); dev copies from landing/dev-lids.txt (quote the mapping). Live page URLs: take from additional-fields.json if present there, else TODO(lead).
3. Source of truth — the repo files, not the Bitrix24 editor (quote AGENTS.md / landing/README.md). If the live page text differs from the repo public file, report that as a finding of type DRIFT.
4. Method (how to find an error correctly):
   a. For each offer, list who the parties are, whose personal data is processed, and the legal basis the offer itself names.
   b. Check each law item L1..L5 of specs/offers-pd/law-152fz.md (quote their ids and one-line meaning) and only those; cite the official URL given in that file (consultant.ru / pravo.gov.ru). No law text from memory.
   c. A finding needs: the verbatim offer words (copy exactly; the files contain non-breaking spaces U+00A0 — keep them, mark them as `{nbsp}` in the finding), the verbatim law words not met, and why.
   d. Verdict per finding: BREACH, DOUBT (two readings — give both), or DRIFT. No style or wording wishes.
   e. Every proposed fix is minimal: one sentence added or replaced, no new facts (no dates, addresses, registry numbers, day counts not already in the offer).
5. Where and how to write — one file `docs/validator/offers-findings.md` on a new branch `claude/validator-offers-<YYYYMMDD>` from `dev`, then a pull request into `dev` (never into main). If the agent cannot push (no connector), it prints the same file content in chat so the owner can hand it over. Finding format (exact table columns): `id | lid | file | clause | verdict | offer words (verbatim) | law words (verbatim) | law URL | proposed fix (old → new) | reason`.
6. What happens next — the lead agent re-checks each finding against the files by command, marks it ACCEPTED or REJECTED with the reason in the same file, applies accepted text edits through its code channel to both draft and public blocks, publishes dev first then prod (quote landing/README.md for the dev→prod order). The validator never deploys.
7. Self-check before finishing — every finding has a verbatim quote that exists in the named file; every law URL comes from specs/offers-pd/law-152fz.md; no personal data in the file.

Output: the complete Markdown file text and nothing else. First line: `# Claude Web validator — arwox.ru offers vs 152-FZ`.

Done-check: the text has sections 1–7, the findings table header, and at least 5 `<!-- src:` comments.
