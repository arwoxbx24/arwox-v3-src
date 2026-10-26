# TZ dcfg-hfkdm.1 / D1 — read-only audit of the landing publish command (deploy-page)

FILE: landing/b24-landing.sh
FILE: landing/README.md
FILE: landing/dev-lids.txt

Goal: describe exactly how `bash landing/b24-landing.sh deploy-page dev <lids>` and `deploy-page prod <lids>` behave, so the lead can plan publishing offer pages 390 392 394 396 (and maybe 384). Read only. No edits, no shell, no git, no web, no runs.

Answer each question with a verbatim code quote (≤200 chars) and its line number in landing/b24-landing.sh (or README line):
Q1 Exact usage line / argument form of deploy-page; which lids it accepts (allow-list?).
Q2 Every refusal condition before writing (uncommitted changes, verify differences, tag checks, branch checks): the condition, the message printed, the exit code.
Q3 Does deploy-page dev run or require `verify 80 landing/site80` (whole site) or only the listed pages? Does a difference on OTHER dev pages block it?
Q4 Does deploy-page prod compare live pages with the latest landing-prod-* tag? Which files, which pages?
Q5 What does deploy-page prod do after success: creates a tag (name format), pushes it, publishes (landing.landing.publication), anything else?
Q6 Does it write both draft and public blocks, or only one? Which file names does it read for each lid (block-*.draft.html, block-*.public.html, CSS)?
Q7 Which git branch must be checked out (dev for dev, main for prod)? Where must the command be run from (repo root, worktree allowed)?
Q8 Mapping prod lid → dev lid: quote dev-lids.txt lines for 384 390 392 394 396.

Output (plain text, nothing else):
FACT | Q<n> | <answer, one line> | <file>:<line> | «<verbatim quote>»
A question you cannot answer from the files → FACT | Q<n> | UNKNOWN | - | -
Last line: SUMMARY | D1 | answered=<n> unknown=<n>

Done-check: at least 8 FACT lines (Q1..Q8) and 1 SUMMARY line.
