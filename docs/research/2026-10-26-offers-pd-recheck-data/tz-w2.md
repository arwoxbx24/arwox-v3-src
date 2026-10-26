# TZ dcfg-hfkdm.1 / W2 — resolve TODO(lead) lines in the validator instructions

FILE: docs/validator/claude-web-offers-validator.md

Goal: the file has exactly 7 lines containing `TODO(lead)` (lines 39, 55, 57, 62, 107, 127, 155). Replace each whole TODO line with the answer below, keeping the line's leading indentation and list marker (`- ` or `  - `). Text change only; nothing else in the file changes.

Answers (English, use verbatim):
- line 39 (draft must match public): `Draft and public blocks of one page hold the same text in the repo: deploy-page writes the draft and then publishes it, so the public block becomes equal to the draft. A draft/public mismatch in the repo is a finding of type DRIFT.`
- line 55 (column order): `Column order: as in the findings table in section 5.`
- line 57 (dev lids exist): `Dev copies are listed in landing/dev-lids.txt; dev page 414 (copy of 396) was written on 2026-10-26 (deploy-page dev 396). Compare other dev pages only if the owner gives their URLs.`
- line 62 (live URLs): `The owner gives the validator the live URL of each offer page; write every URL you used at the top of the findings file.`
- line 107 (U+00A0): `The offer files do contain U+00A0: lines with it per public block on 2026-10-26 — 384: 1, 390: 3, 392: 7, 394: 15, 396: 1. Keep them in quotes and mark each as {nbsp}.`
- line 127 (docs/validator): `docs/validator/ exists in the repo (this instruction file lives there); create offers-findings.md in it.`
- line 155 (publishing): `Accepted edits are published only by the lead: bash landing/b24-landing.sh deploy-page dev <lid> (one lid, dev copy), then after merge into main deploy-page prod <lid>... at origin/main, which adds a landing-prod-* tag.`

Constraints:
- Return one edit per TODO line: old = the full current line exactly as in the file (copy it exactly), new = indentation + marker + answer.
- No other edits. No other files. No git, no network.
- Bans: no rm -rf, no secrets.

Done-check: 7 edits; afterwards the file contains no `TODO(lead)`.
