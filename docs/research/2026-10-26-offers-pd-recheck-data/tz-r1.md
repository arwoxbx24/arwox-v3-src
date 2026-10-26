# TZ dcfg-hfkdm.1 / R1 — read-only cross-check of GAP verdicts (offers 390, 392, 394, 396)

FILE: specs/offers-pd/law-152fz.md
FILE: landing/site78/390/block-9294.public.html
FILE: landing/site78/392/block-9298.public.html
FILE: landing/site78/394/block-9302.public.html
FILE: landing/site78/396/block-9306.public.html

Goal: four earlier read-only audits produced the GAP lines below. Two of them disagree on the same wording (392 X1 = GAP, 394 X1 = OK for «Заказчик, акцептуя оферту, поручает Исполнителю обработку этих данных…»). Decide, for each candidate, whether it is a real breach of the law text quoted in specs/offers-pd/law-152fz.md. Read only. No edits, no shell, no git, no web.

Decision rules (apply in this order):
1. Who is the subject? If the clause is about personal data that the Customer (a legal entity / sole trader acting as operator) entrusts to the Contractor, the right instrument is a contract (ч. 3 ст. 6: «на основании заключаемого с этим лицом договора») — accepting the offer is that contract, so «акцептуя оферту, поручает» is NOT a breach by itself.
2. A clause saying acceptance = agreement with the offer or with a policy's terms is a breach of ч. 1 ст. 9 ONLY if the text treats it as the data subject's consent to personal-data processing (the clause or the policy it names is about personal data, and no other legal basis such as п. 5 ч. 1 ст. 6 is stated for that processing). Quote the words that make it PD consent; without such words → NOT_BREACH.
3. A liability limit is a breach of п. 5 ч. 1 ст. 6 / ч. 5 ст. 6 only if it limits the data subject's rights or the processor's liability to the operator for personal-data processing; quote the words.
4. Never guess. A fact not in the files → UNKNOWN.

Candidates (from the earlier audits):
C1 | 390 | п. 1.13 | «Акцептуя настоящую Оферту, Заказчик также подтверждает свое полное и безоговорочное согласие с условиями Политики конфиденциальности и защиты данных» | claimed: ч. 1 ст. 9
C2 | 392 | п. 1.3 | «Совершение оплаты означает безусловное и полное согласие с условиями настоящей оферты и всех Приложений, согласованных в рамках деловой переписки» | claimed: ч. 1 ст. 9
C3 | 392 | п. 3.5 | «Заказчик, акцептуя оферту, поручает Исполнителю обработку этих данных на условиях пп. 3.5–3.9» | claimed: ч. 1 ст. 9
C4 | 394 | п. 8.2.1 | «Исполнитель не несет ответственности за работу, стабильность, корректность, доступность, обновления, а также за любые действия или бездействие сторонних сервисов» | claimed: ч. 5 ст. 6
C5 | 396 | п. 4 | «Ответственность Исполнителя по настоящей Политике ограничена в порядке и пределах, установленных соответствующим договором-офертой, за исключением умышленного нарушения.» | claimed: п. 5 ч. 1 ст. 6
C6 | 396 | п. 3.3 | «Исполнитель вправе привлекать к работе с Конфиденциальной информацией третьих лиц» | claimed: ч. 3 ст. 6 (no list of data, actions, purposes)
C7 | 396 | преамбула | «Акцепт Заказчиком оферты на оказание услуг означает его полное и безоговорочное согласие с условиями настоящей Политики.» | claimed: ч. 1 ст. 9

Output (plain text, nothing else), one line per candidate:
VERDICT | C<n> | BREACH or NOT_BREACH or UNKNOWN | «<offer words that decide it, verbatim, ≤200 chars>» | <law words, verbatim from law-152fz.md> | <minimal fix in Russian if BREACH: one sentence to add or replace, no new facts, else "-">
Last line: SUMMARY | R1 | BREACH=<n> NOT_BREACH=<n> UNKNOWN=<n>

Done-check: exactly 7 VERDICT lines and 1 SUMMARY line.
