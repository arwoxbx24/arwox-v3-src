## dcfg-hfkdm.1 — offers 384/390/392/394/396 re-checked against 152-FZ

- `specs/offers-pd/law-152fz.md` — law items L1–L5 with consultant.ru quotes.
- Offer 396 p.3.3: subcontractors receiving personal data get the art.6 ch.3 content (list of data, operations, purposes, confidentiality, art.19 requirements). Draft and public blocks identical.
- Offer 396 p.4: an edit was made and withdrawn before prod (law does not expressly forbid a contractual limit; goes to a lawyer).
- Offers 384, 390, 392, 394: no edits; 5 disputed clauses listed for a lawyer in the report.
- `docs/research/2026-10-26-offers-pd-recheck.md` — re-check report.
- `docs/validator/claude-web-offers-validator.md` — instructions for the Claude Web offers validator.

### Checks (run by the lead)
```
grep -c "не ограничивается условиями договора-оферты" 396 draft/public → 0 / 0
grep -c (original p.4 | p.3.3 art.19 sentence) 396 draft/public → 2 / 2
deploy-page dev 396 → dev: page 414 (copy of 396) = c8b43d6
```
No code, forms or other pages changed; prod publication by `deploy-page prod 396` after merge into main.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
