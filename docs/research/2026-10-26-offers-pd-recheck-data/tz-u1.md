# TZ dcfg-hfkdm.1 / U — independent read-only legal check of 5 offer clauses against 152-FZ

FILE: specs/offers-pd/law-152fz.md
FILE: landing/site78/390/block-9294.public.html
FILE: landing/site78/392/block-9298.public.html
FILE: landing/site78/394/block-9302.public.html
FILE: landing/site78/396/block-9306.public.html

Goal: decide independently whether each clause below breaches the 152-FZ text quoted in specs/offers-pd/law-152fz.md. You get no hints and no decision rules: read the whole offer around each clause (definitions, who the parties are, what data, what legal basis the offer states) and reason from the law text yourself. Read only. No edits, no shell, no git, no web.

Clauses:
K1 | 390 | п. 1.13 | «Акцептуя настоящую Оферту, Заказчик также подтверждает свое полное и безоговорочное согласие с условиями Политики конфиденциальности и защиты данных»
K2 | 392 | п. 1.3 | «Совершение оплаты означает безусловное и полное согласие с условиями настоящей оферты и всех Приложений, согласованных в рамках деловой переписки»
K3 | 392 | п. 3.5 | «Заказчик, акцептуя оферту, поручает Исполнителю обработку этих данных на условиях пп. 3.5–3.9»
K4 | 394 | п. 8.2.1 | «Исполнитель не несет ответственности за работу, стабильность, корректность, доступность, обновления, а также за любые действия или бездействие сторонних сервисов»
K5 | 396 | преамбула | «Акцепт Заказчиком оферты на оказание услуг означает его полное и безоговорочное согласие с условиями настоящей Политики.»

For each clause: state who the data subject is, whose data is processed, which legal basis the offer itself names, which law item (L1..L5) could apply, and your verdict.
Verdicts: BREACH (quote the law words not met and the offer words that break them), NOT_BREACH (quote the offer words and law words that show it complies), DOUBT (the law text allows two readings; give both in one line each). Never guess facts not in the files.

Output (plain text, nothing else):
VERDICT | K<n> | BREACH or NOT_BREACH or DOUBT | subject=<…>; basis=<…> | «<offer words ≤200 chars>» | «<law words>» | <if BREACH: one Russian sentence of minimal fix, no new facts; else ->
Last line: SUMMARY | U | BREACH=<n> NOT_BREACH=<n> DOUBT=<n>

Done-check: exactly 5 VERDICT lines and 1 SUMMARY line.
