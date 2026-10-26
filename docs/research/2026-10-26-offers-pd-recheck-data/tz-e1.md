# TZ dcfg-hfkdm.1 / E1 — fix offer 396 п. 4 (liability limit on personal-data Policy)

FILE: landing/site78/396/block-9304.draft.html
FILE: landing/site78/396/block-9306.public.html

Goal: two independent read-only audits found that п. 4 of the Policy on page 396 limits the Contractor's liability for personal-data processing by the offer contract. Law (152-FZ ч. 5 ст. 6, specs/offers-pd/law-152fz.md L3): «Лицо, осуществляющее обработку персональных данных по поручению оператора, несет ответственность перед оператором.» Remove that limit. Text change only.

Exact edit — in EACH of the two files, exactly once:
old: Ответственность Исполнителя по настоящей Политике ограничена в порядке и пределах, установленных соответствующим договором-офертой, за исключением умышленного нарушения.
new: Ответственность Исполнителя по настоящей Политике не ограничивается условиями договора-оферты.

Constraints:
- Copy `old` exactly as written above (it is plain ASCII spaces; preflight grep -c found it once in each file).
- Change nothing else: no HTML, attributes, whitespace, other sentences.
- Both files get the identical edit.
- No other files. No git, no deploy, no network.
- Bans: no rm -rf, no secrets, no reading .env/secrets.

Check: command grep -c 'не ограничивается условиями договора-оферты' landing/site78/396/block-9304.draft.html landing/site78/396/block-9306.public.html

Done-check: each file prints :1 for the new sentence; the old sentence occurs 0 times in both files.
