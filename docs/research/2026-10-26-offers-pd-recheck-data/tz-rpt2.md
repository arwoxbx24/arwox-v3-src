# TZ dcfg-hfkdm.1 / RPT2 — draft the re-check report (Markdown, Russian). Replaces RPT.

FILE: specs/offers-pd/law-152fz.md

Goal: write the full text of `docs/research/2026-10-26-offers-pd-recheck.md` — the report of the re-check of 5 arwox.ru offers against 152-FZ. Read only; output the file text only. All facts are given below; do not add facts. Law URLs: take them only from specs/offers-pd/law-152fz.md (consultant.ru links), copy exactly.

Hard text rules (an automatic check reads the file):
- One table row per offer; each row starts with `| lid 384 |`, `| lid 390 |`, `| lid 392 |`, `| lid 394 |`, `| lid 396 |` and contains at least one full consultant.ru URL from the law file.
- Never write the words «НЕ ИСПРАВЛЕНО» or «НЕ ПРОВЕРЕНО» anywhere. For a fact the offer text does not state, write «в тексте оферты не указано». For a disputed clause write «спорно — нужен юрист».
- Russian language, plain style, no emojis.

Facts:
Method: each offer's published block (landing/site78/<lid>/block-*.public.html) was read by a separate sdk audit agent against law items L1–L5 (spec file). Candidates were cross-checked: first by agent R1 whose task contained the lead's own decision rules (so R1's verdicts are not independent — the lead admits this), then by two independent agents U1 and U2 with no decision rules. Rule: a clause is changed only if two agents without the lead's rules both say BREACH; otherwise it goes to a lawyer. Agents are not lawyers; this report is not a legal opinion.

Per offer:
- lid 384 — договоры-оферты на лицензии. Status: СООТВЕТСТВУЕТ, правок нет. The offer does not process personal data; the customer's e-mail is only the channel for the licence key (п. 4.3).
- lid 390 — договор на оказание услуг (каталог 1С-Битрикс). Status: БЕЗ ПРАВОК. п. 1.13 «Акцептуя настоящую Оферту, Заказчик также подтверждает свое полное и безоговорочное согласие с условиями Политики конфиденциальности и защиты данных»: U1 и U2 — спорно → спорно — нужен юрист (ст. 9 ч. 1, if read as consent to processing). The offer links the policy https://arwox.ru/legal/politika-konfidentsialnosti-i-zashchity-dannykh/, while 392 and 394 link https://arwox.ru/legal/politika-obrabotka-personalnyh-dannyh/. Database location (ч. 5 ст. 18): в тексте оферты не указано.
- lid 392 — договор внедрения. Status: БЕЗ ПРАВОК. Section 3 «Персональные данные»: basis п. 5 ч. 1 ст. 6, entrustment content ч. 3 ст. 6 (пп. 3.5–3.9), policy link — соответствует. п. 1.3 (оплата = согласие с условиями оферты): U1 и U2 — нарушения нет. п. 3.5 «Заказчик, акцептуя оферту, поручает Исполнителю обработку…»: U1 и U2 — спорно → спорно — нужен юрист (ч. 3 ст. 6: list of data is open, consent of subjects is only the customer's guarantee in п. 2.3.12). Database location for the Bitrix24 portal: в тексте оферты не указано.
- lid 394 — договор техподдержки. Status: БЕЗ ПРАВОК. Section 6 «Персональные данные» — соответствует. п. 8.2.1 (no liability for third-party services incl. Bitrix24, mail gateways): U1 спорно, U2 нарушение → спорно — нужен юрист (ч. 5 ст. 6). Database location: в тексте оферты не указано.
- lid 396 — оферта на сертификат 1С Битрикс24.Маркет Плюс with a confidentiality Policy (п. 1.1 а: confidential information includes personal data). Status: ИСПРАВЛЕНО (1 пункт). п. 3.3: added «Для Субподрядчиков, получающих персональные данные, определяются перечень персональных данных, перечень действий (операций), цели их обработки, обязанность соблюдать конфиденциальность персональных данных и требования, предусмотренные статьей 19 Федерального закона «О персональных данных».» (ч. 3 ст. 6; first audit GAP, tie-break agent T1 BREACH). п. 4 «Ответственность Исполнителя по настоящей Политике ограничена … договором-офертой…»: an edit removing the limit was made and then withdrawn before publication on arwox.ru — the law (ч. 5 ст. 6) makes the processor liable to the operator but does not expressly forbid a contractual limit, R1's vote came under the lead's rules, and the edit widens the company's liability → спорно — нужен юрист. Preamble «Акцепт Заказчиком оферты… означает его полное и безоговорочное согласие с условиями настоящей Политики»: U1 и U2 — спорно → спорно — нужен юрист. п. 3.4 storage in RF (ч. 5 ст. 18) — соответствует. Draft and public blocks edited identically.

Publication: dev copy page 414 of 396, then prod by `deploy-page prod 396` after merge into main, which adds a landing-prod-* tag (results in the final report of atom dcfg-hfkdm.1).

Sections of the file:
1. `# Перепроверка 5 оферт arwox.ru по 152-ФЗ — 26.10.2026`
2. `## Итог` — 3–4 lines.
3. `## Источники закона` — law items with their consultant.ru URLs (from the law file).
4. `## Метод` — the method above, including the admission about R1.
5. `## Результат по офертам` — table `| lid | документ | статус | что найдено | норма и ссылка |`.
6. `## Спорные пункты — показать юристу` — numbered list of 5: 390 п. 1.13; 392 п. 3.5; 394 п. 8.2.1; 396 п. 4; 396 преамбула — each with the verbatim offer words and the law question.
7. `## Что не указано в текстах оферт` — database location for 390, 392, 394; different policy URL in 390.
8. `## Публикация` — the publication facts.

Output: the complete Markdown text only, starting with the `#` title line.

Done-check: 5 rows starting `| lid 3`; ≥5 lines containing consultant.ru; the two forbidden phrases appear 0 times.
