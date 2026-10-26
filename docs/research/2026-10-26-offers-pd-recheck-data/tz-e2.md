# TZ dcfg-hfkdm.1 / E2 — fix offer 396 п. 3.3 (subcontractors receiving personal data)

FILE: landing/site78/396/block-9304.draft.html
FILE: landing/site78/396/block-9306.public.html

Goal: two of three independent read-only audits found that п. 3.3 of the Policy on page 396 lets subcontractors work with «Конфиденциальная информация» (which by п. 1.1 а includes personal data) without the items required by 152-FZ ч. 3 ст. 6: «В поручении оператора должны быть определены перечень персональных данных, перечень действий (операций) с персональными данными …, цели их обработки, должна быть установлена обязанность такого лица соблюдать конфиденциальность персональных данных … требования, предусмотренные статьей 19». Add one sentence after the existing liability sentence of п. 3.3. Text change only.

Exact edit — in EACH of the two files, exactly once:
old: Исполнитель несет полную ответственность перед Заказчиком за любые действия или бездействие таких Субподрядчиков как за свои собственные.
new: Исполнитель несет полную ответственность перед Заказчиком за любые действия или бездействие таких Субподрядчиков как за свои собственные. Для Субподрядчиков, получающих персональные данные, определяются перечень персональных данных, перечень действий (операций), цели их обработки, обязанность соблюдать конфиденциальность персональных данных и требования, предусмотренные статьей 19 Федерального закона «О персональных данных».

Constraints:
- Copy `old` exactly as written above (plain spaces; a grep found it once in each file).
- The new text is the old sentence unchanged plus one space and the added sentence. Use the same quote marks «» as shown.
- Change nothing else: no HTML, attributes, other sentences.
- Both files get the identical edit.
- No other files. No git, no deploy, no network.
- Bans: no rm -rf, no secrets, no reading .env/secrets.

Done-check: return exactly two edits (one per file), old → new as above.
