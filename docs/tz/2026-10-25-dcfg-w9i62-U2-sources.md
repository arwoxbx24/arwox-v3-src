# TZ dcfg-w9i62 U2 — the owner's sources: RKN statistics H1 2026 and the consent guide (read-only research)

Goal: extract verified facts from two articles the owner forwarded and confirm the key numbers with one independent source.
Mode: read-only. You write nothing. Use WebFetch and WebSearch. Do not open app.getresponse.com tracking links.

## Sources
- A: https://iz.ru/2173140/2026-09-25/roskomnadzor-vyiavil-bolee-500-narushenii-v-sfere-personalnykh-dannykh-za-polgoda
- B: https://pohodu.media/kak-sobrat-soglasie-na-rassylku-i-obrabotku-personalnyh-dannyh/

## Questions (a correct answer contains each)
1. From A: number of violations in H1 2026 (expected 504), number of leaks (expected 12), growth of leaked data vs 2025 (expected 31%), any listed typical violations of website operators (forms, consent, policy).
2. Independent confirmation of the numbers from question 1 on another domain (rkn.gov.ru, tass.ru, ria.ru, rbc.ru, kommersant.ru, interfax.ru). Not found → `UNVERIFIED`.
3. From B: every concrete rule on how to collect consent on a website form: separate document, separate checkbox, no pre-ticked box, link to consent text, separate consent for mailings, what the consent text must contain, how to store proof.
4. From B: the date of the article and which law changes it cites.

## Output format (only these lines)
`FACT | <claim> | <URL> | «<verbatim quote, up to 250 chars>»`
`INFERENCE | <claim> | <based on FACT n>`
`UNVERIFIED | <what was not found>`

## Done-check
At least 8 FACT lines with https URL and verbatim quote; questions 1-4 each covered by a FACT or UNVERIFIED line.

## Rules
R5: separate FACT, INFERENCE, HYPOTHESIS. R7: do not invent. No secrets, no personal data in output.
