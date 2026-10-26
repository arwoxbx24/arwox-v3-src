# TZ dcfg-hfkdm.1 / A384b — read-only audit of offer lid 384, requirements L1 and L5 only

FILE: landing/site78/384/block-9282.public.html
FILE: specs/offers-pd/law-152fz.md

Goal: an earlier audit of this offer left L5 unchecked and L1 UNKNOWN. Check only L1 and L5 from specs/offers-pd/law-152fz.md against the offer text. Read only. No edits, no shell, no git, no web.

Rules:
- One verdict per requirement: OK, GAP, N/A (the rule does not apply; quote the words that show it), or UNKNOWN.
- Does the offer itself collect, store or process personal data of a natural person (name, phone, e-mail of a person)? Quote the words. If the offer only names an e-mail as a delivery channel for a licence key and says nothing about storing or processing personal data, say so with the quote.
- GAP must quote the law words not met and give one sentence of fix in Russian, no new facts.
- Never guess. A fact not in the two files → UNKNOWN.

Output (plain text, nothing else):
FACT | L1 | <verdict> | <clause no.> | «<offer quote ≤200 chars>» | <law words not met or "-"> | <fix or "-">
FACT | L5 | <verdict> | <clause no.> | «<offer quote ≤200 chars>» | <law words not met or "-"> | <fix or "-">
SUMMARY | lid 384b | GAP=<n> OK=<n> N/A=<n> UNKNOWN=<n>

Done-check: exactly 2 FACT lines and 1 SUMMARY line.
