# TZ dcfg-hfkdm.1 / E3 — revert offer 396 п. 4 to its original wording

FILE: landing/site78/396/block-9304.draft.html
FILE: landing/site78/396/block-9306.public.html

Goal: the earlier edit E1b of п. 4 is withdrawn (not independently confirmed; the law does not expressly forbid a contractual liability limit; it widens the company's liability — goes to a lawyer). Restore the original sentence. Text change only.

Exact edit — in EACH of the two files, exactly once:
old: Ответственность Исполнителя по настоящей Политике не ограничивается условиями договора-оферты.
new: Ответственность Исполнителя по настоящей Политике ограничена в порядке и пределах, установленных соответствующим договором-офертой, за исключением умышленного нарушения.

Constraints:
- Copy `old` exactly as written above (plain spaces; it occurs once in each file).
- Change nothing else; the п. 3.3 sentence about Субподрядчики stays as is.
- Both files get the identical edit. No other files. No git, no deploy, no network.
- Bans: no rm -rf, no secrets.

Done-check: return exactly two edits (one per file), old → new as above.
