# TZ dcfg-9wggj — forms-gw-guard: Yandex Cloud Logging outage alerts once

Atom: dcfg-9wggj (discovered-from dcfg-ac9i1.2). Executor: sdk-agent code.
Recon: repowise / codebase-memory first, then grep; index: repowise/CBM checked; if missing — `tools/bin/code-memory-enable`.

## U1 — provider-outage classification for the cloud log read

Files (only these):
FILE: forms-failover/forms-gw-guard.sh
FILE: forms-failover/forms-gw-guard-test.sh

### Problem (facts, 17.10.2026)
- `check_captcha_unverified` (forms-gw-guard.sh:364-398) reads Cloud Logging with `yc ... logging read`. Since 16.10 every read fails: stderr first line contains `rpc error: code = Unavailable desc = Unavailable` (36 of 36 failures). Cause is Yandex incident https://status.yandex.cloud/ru/incidents/2136 (open since 11.10, Cloud Logging listed).
- At `fails >= 3` the code calls `notify cloud_read_failed "$fails"` (:391). `notify` falls into the generic `*)` debounce (:115-121, `GUARD_DEBOUNCE_SEC=21600`), so the owner gets the same alert every ~7 h: "3 раз", "10 раз", "16 раз", "23 раз".

### Required behavior
1. Read failure whose stderr (`$yerr`, already captured) contains `code = Unavailable` = provider outage.
   - Keep counting `cloud_read_fail` as now.
   - At the 3rd consecutive failure send ONE message, new notify type `cloud_read_outage`, text exactly:
     `⚠️ Журнал Yandex Cloud Logging недоступен — сбой на стороне Яндекса (status.yandex.cloud/ru/incidents/2136). Формы работают; заявки без капчи пока считает только резерв.`
   - Record `cloud_outage_notified` = 1 in state (via `state_put`). While it is 1, no further `cloud_read_outage` / `cloud_read_failed` messages, however many failures follow.
2. First successful read after `cloud_outage_notified` = 1: send ONE message, type `cloud_read_recovered`, text exactly:
   `✅ Журнал Yandex Cloud Logging снова читается. Счётчик заявок без капчи работает полностью.`
   then set `cloud_outage_notified` 0 and `cloud_read_fail` 0 (existing reset).
3. Failure WITHOUT `code = Unavailable` in stderr: behavior unchanged (current `cloud_read_failed` path, current debounce). Existing case62 must still pass unchanged.
4. Both new types must bypass the generic 6 h debounce (add them to the `fallback_*|reserve_lead)` no-debounce branch at :113), because state flag 1 already guarantees once-only.
5. Message types added to the `case "$type"` text table near :73.

### Tests (forms-gw-guard-test.sh, TDD: write cases first)
- Stub (:209-214): when file `$GUARD_TEST_TMP/yc-logging-unavailable` exists, print to stderr `ERROR: ... getting log group by ID: rpc error: code = Unavailable desc = Unavailable` and exit 1 (keep the existing `yc-logging-fail` behavior as is). Add the new file to the cleanup list(s) where `yc-logging-fail` is cleaned (:976, :1047).
- New case A: Unavailable stub, 10 hourly runs (advance `$tmp/clock` by 3600 each, as case62 does) → `grep -c 'Yandex Cloud Logging недоступен' sent.log` = 1 and no `не читается` lines.
- New case B: after case-A style outage, remove stub, next hourly run → exactly 1 `снова читается` line, state `.cloud_read_fail == 0` and `.cloud_outage_notified == 0`.
- New case C: success with no prior outage → no `снова читается` message.
- Register new cases the same way existing cases are registered (follow the file's runner list).

### Style
Minimal diff, existing idioms (`log`, `state_put`, `jq`, `notify`). No refactor of untouched code. No new env vars.

## Acceptance (I run once after the edit)
- `bash -n forms-failover/forms-gw-guard.sh` rc 0.
- `bash forms-failover/forms-gw-guard-test.sh` → all PASS, including case62 and new A, B, C.
- `git diff --check` rc 0; diff only in the two listed files.

## Threats / rollback
- Runtime: pm2 `forms-gw-guard` (one-shot per minute). A wrong match could hide a real non-outage failure → match only the literal `code = Unavailable`; other errors keep the old path (item 3).
- No secrets, no PII in messages; Telegram path unchanged.
- Rollback: `git revert` of the merge commit; the next tick uses the reverted file.

## Forbidden
No secrets read or printed; no edits outside the two listed files; no live yc/Telegram calls; no `rm`, no pm2 commands.
