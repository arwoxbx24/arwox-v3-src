# TZ dcfg-hfkdm.1 / RPT — draft the re-check report (Markdown, Russian)

FILE: specs/offers-pd/law-152fz.md

Goal: write the full text of `docs/research/2026-10-26-offers-pd-recheck.md` — the report of the re-check of 5 arwox.ru offers against 152-FZ. Read only; output the file text only. All facts are given below; do not add facts. Law URLs: take them only from specs/offers-pd/law-152fz.md (consultant.ru links), copy exactly.

Hard text rules (an automatic check reads the file):
- One table row per offer; each row starts with `| lid 384 |`, `| lid 390 |`, `| lid 392 |`, `| lid 394 |`, `| lid 396 |` and contains at least one full consultant.ru URL from the law file.
- Never write the words «НЕ ИСПРАВЛЕНО» or «НЕ ПРОВЕРЕНО» anywhere. For a fact the offer text does not state, write «в тексте оферты не указано». For a disputed clause write «спорно — нужен юрист».
- Russian language, plain style, light, no emojis.

Facts:
Method: each offer's published block (landing/site78/<lid>/block-*.public.html) was read by a separate sdk audit agent against law items L1–L5 (spec file). Found candidates were cross-checked: first by one agent R1 whose task contained the lead's decision rules (so its «нет нарушения» verdicts were not independent — the lead admits this), then by two independent agents U1 and U2 with no decision rules. Rule: a clause is changed only if two independent agents both say BREACH. Clause 396 п. 3.3 got a third tie-break agent T1.

Per offer:
- lid 384 — «Договоры-оферты ИП Димитрюк А. А.» (licences). Status: СООТВЕТСТВУЕТ, правок нет. Personal data are not processed by the offer; the customer's e-mail is only the channel for the licence key (п. 4.3). L1–L5: не применяются.
- lid 390 — «Договор на оказание услуг» (1С-Битрикс catalogue). Status: БЕЗ ПРАВОК. п. 1.13 «Акцептуя настоящую Оферту, Заказчик также подтверждает свое полное и безоговорочное согласие с условиями Политики конфиденциальности и защиты данных»: U1 DOUBT, U2 DOUBT → спорно — нужен юрист (ст. 9 ч. 1: согласие оформляется отдельно — if read as PD consent). Note: the offer links the policy at https://arwox.ru/legal/politika-konfidentsialnosti-i-zashchity-dannykh/, while 392 and 394 link https://arwox.ru/legal/politika-obrabotka-personalnyh-dannyh/. Where the databases are located (ч. 5 ст. 18): в тексте оферты не указано.
- lid 392 — договор внедрения. Status: БЕЗ ПРАВОК. Section 3 «Персональные данные»: basis п. 5 ч. 1 ст. 6, entrustment ч. 3 ст. 6 with required content (3.5–3.9), policy link — OK. п. 1.3 (payment = agreement with offer terms): U1 and U2 NOT_BREACH → соответствует. п. 3.5 «Заказчик, акцептуя оферту, поручает Исполнителю обработку…»: U1 DOUBT, U2 DOUBT → спорно — нужен юрист (ч. 3 ст. 6: list of data is open-ended, subject consent is only the customer's guarantee in п. 2.3.12). Database location (ч. 5 ст. 18) for the Bitrix24 portal: в тексте оферты не указано.
- lid 394 — договор техподдержки. Status: БЕЗ ПРАВОК. Section 6 «Персональные данные»: basis п. 5 ч. 1 ст. 6, entrustment content — OK. п. 8.2.1 (no liability for third-party services incl. Bitrix24, mail gateways): U1 DOUBT, U2 BREACH → спорно — нужен юрист (ч. 5 ст. 6: processor is liable to the operator). Database location: в тексте оферты не указано.
- lid 396 — оферта на сертификат 1С Битрикс24.Маркет Плюс with a confidentiality Policy (п. 1.1 а: confidential information includes personal data). Status: ИСПРАВЛЕНО (2 пункта). п. 4: «Ответственность Исполнителя по настоящей Политике ограничена в порядке и пределах, установленных соответствующим договором-офертой, за исключением умышленного нарушения.» → «Ответственность Исполнителя по настоящей Политике не ограничивается условиями договора-оферты.» (ч. 5 ст. 6; first audit + R1 both BREACH). п. 3.3: added «Для Субподрядчиков, получающих персональные данные, определяются перечень персональных данных, перечень действий (операций), цели их обработки, обязанность соблюдать конфиденциальность персональных данных и требования, предусмотренные статьей 19 Федерального закона «О персональных данных».» (ч. 3 ст. 6; first audit GAP, T1 BREACH). Preamble «Акцепт Заказчиком оферты… означает его полное и безоговорочное согласие с условиями настоящей Политики»: U1 DOUBT, U2 DOUBT → спорно — нужен юрист. п. 3.4 storage in RF (ч. 5 ст. 18) — соответствует. Both draft and public blocks edited identically; commit e76f008.

Publication: dev page 414 (copy of 396) = e76f008, 2026-10-26. Prod: after merge into main by `deploy-page prod 396`, which adds a landing-prod-* tag (result in the final report of atom dcfg-hfkdm.1).

Sections of the file:
1. `# Перепроверка 5 оферт arwox.ru по 152-ФЗ — 26.10.2026`
2. `## Итог` — 3–4 lines.
3. `## Источники закона` — list of the law items with their consultant.ru URLs (from the law file).
4. `## Метод` — the method above, including the lead's admission about R1.
5. `## Результат по офертам` — the table: `| lid | документ | статус | что найдено | норма и ссылка |`.
6. `## Спорные пункты — показать юристу` — numbered list of the 5 disputed clauses (390 п. 1.13, 392 п. 3.5, 394 п. 8.2.1, 396 преамбула) — that is 4 disputed clauses plus a note that 392 п. 1.3 was cleared by both agents.
7. `## Что не указано в текстах оферт` — database location for 390, 392, 394; different policy URL in 390.
8. `## Публикация` — the publication facts.

Output: the complete Markdown text only, starting with the `#` title line.

Done-check: 5 rows starting `| lid 3`; ≥5 lines containing consultant.ru; the two forbidden phrases appear 0 times.
