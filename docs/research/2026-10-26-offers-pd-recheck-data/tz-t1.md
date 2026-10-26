# TZ dcfg-hfkdm.1 / T1 — read-only tie-break on offer 396 п. 3.3 (subcontractors)

FILE: landing/site78/396/block-9306.public.html
FILE: specs/offers-pd/law-152fz.md

Goal: two earlier audits disagree on 396 п. 3.3 «Исполнитель вправе привлекать к работе с Конфиденциальной информацией третьих лиц (далее – «Субподрядчики»)». Audit 1: GAP by ч. 3 ст. 6 (no list of data, actions, purposes). Audit 2: UNKNOWN. Give a third, final verdict. Read only. No edits, no shell, no git, no web.

Answer these, each with a verbatim quote (≤200 chars) from the files:
Q1 Does the Policy define «Конфиденциальная информация» to include personal data? Quote the definition clause.
Q2 Does any clause of the Policy say subcontractors may get personal data, and on what conditions (contract, list of data, actions, purposes, confidentiality, ст. 19 safeguards)? Quote all such clauses, or say none.
Q3 Does the Policy anywhere state that the Contractor processes data «по поручению» of the Customer (operator)? Quote.
Q4 Verdict for п. 3.3: BREACH only if Q1 = yes AND Q2 shows conditions required by ч. 3 ст. 6 are missing for subcontractors receiving personal data; NOT_BREACH if the required conditions are present elsewhere in the Policy (quote them); UNKNOWN only if the files cannot decide Q1.
If BREACH: give one sentence in Russian to add at the end of п. 3.3, no new facts, using only the law words of ч. 3 ст. 6 (перечень персональных данных, перечень действий, цели, конфиденциальность, ст. 19).

Output (plain text, nothing else):
FACT | Q1 | <yes/no> | «<quote>»
FACT | Q2 | <answer> | «<quote or ->»
FACT | Q3 | <yes/no> | «<quote or ->»
VERDICT | C6 | BREACH or NOT_BREACH or UNKNOWN | <one-line reason> | <sentence to add or ->
SUMMARY | T1 | done

Done-check: 3 FACT lines, 1 VERDICT line, 1 SUMMARY line.
