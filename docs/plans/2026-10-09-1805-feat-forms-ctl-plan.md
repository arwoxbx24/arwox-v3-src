---
title: Forms reserve control script - Plan
type: feat
date: 2026-10-09
artifact_contract: ce-unified-plan/v1
artifact_readiness: implementation-ready
product_contract_source: ce-plan-bootstrap
execution: code
---

# Forms reserve control script - Plan

## Goal Capsule

- Objective: the owner runs one command to test the reserve, return to Yandex, or check status, and sees for each test lead whether it reached Bitrix24.
- Means: rename `demo.sh` to `forms-ctl.sh` with test/restore/status commands; write the Bitrix24 outcome per lead into the reserve log (KTD1, KTD2).
- Authority: owner's words of 09.10 > this plan > existing code conventions.
- Stop when every Definition of Done item has command output as evidence. One review round only; later findings become separate bd tasks.

## Product Contract

### Summary

One control script replaces `demo.sh`. It has three commands: `test`, `restore` and `status`. The `--prod` flag targets `forms.arwox.ru`. The live feed shows for each lead the Bitrix24 lead id, or that the lead waits in the reserve queue and later the lead id when the queue delivers it.

### Problem Frame

On 09.10 the feed printed "✅ #sent" for reserve leads. `#sent` is returned both when the lead was created in Bitrix24 and when it was only queued (`site78-releases/2026-07-29/backend-arwox-lead-form/index.py:434-452`). So the feed does not prove delivery. A manual CRM check on 09.10 found all 4 reserve leads (ids 3192, 3194, 3196, 3198) in Bitrix24; the tool must show this without a manual check. The name "demo" and the `FORMS_FQDN=` variable do not read as a control tool. Manual restore reports a false `rc 124` (bd dcfg-rh17x).

### Requirements

Control commands
- R1. `forms-ctl.sh test|restore|status` replaces `demo.sh`; `demo.sh` no longer exists; `--help` lists the three commands; an unknown command exits 64.
- R2. `--prod` is the only owner-facing way to target `forms.arwox.ru`; without it the target is `forms-test.arwox.ru`. `FORMS_FQDN` stays an internal test hook and is not documented for the owner.
- R3. `test` keeps the auto-restore timer; `restore` returns to Yandex manually and cancels the timer.
- R4. `restore` exits 0 when DNS returns to normal within its own timeout, counted from the restore start (closes dcfg-rh17x).

Bitrix24 visibility
- R5. Each reserve log line `forms-backup lead …` ends with `b24=lead:<id>`, `b24=queue:<spool-file>` or `b24=-`.
- R6. When the queue later delivers a lead, stdout gets `forms-backup spool-sent spool=<spool-file> b24=lead:<id>`.
- R7. The feed prints per lead: "→ Bitrix24 лид #<id>"; "→ очередь резерва, дошлётся сам" and later "📬 из очереди: Bitrix24 лид #<id>"; for `b24=-` "→ в Bitrix24 не передана"; for an old line without `b24=` no Bitrix24 text.
- R8. No personal data (name, phone, e-mail) appears in any log line.

### Scope Boundaries

- Out: `forms-gw-guard.sh`, `dns-switch.sh` logic, the HTTP response contract of `index.py`, the Yandex function deployment, pm2 ecosystem config, historical TZ files in `docs/tz/`, untracked `AGENTS.md`.

## Planning Contract

### Key Technical Decisions

- KTD1. Pass the outcome via a module-level `B24_OUTCOME = threading.local()` in `index.py`. `_lead_status` sets `.value = "lead:<id>"` after `crm.lead.add` succeeds. `handler` sets `queue:<spool-file>` after `_enqueue_lead` succeeds. `server.py` resets it before `index.handler` and reads it after, in the same thread, with `getattr(getattr(index, "B24_OUTCOME", None), "value", "-")` so the read never raises. `drain_spool` reads its own thread value after each successful send and prints the R6 line. Chosen over a separate log line (misattributed under `ThreadingHTTPServer`, `forms-failover/server.py:6,82`), over a new response key (changes the Yandex contract), and over wrapping functions in `server.py` (the queue drain inside `index.py` also needs the id).
- KTD2. Rename with `git mv`; no wrapper or alias for `demo.sh`. Every `demo.sh` literal inside the script (timer child `:88`, restore hint `:275`, test NAME `:291`) becomes `forms-ctl.sh`.
- KTD3. `--prod` may appear anywhere after the command; it sets the internal `FORMS_FQDN=forms.arwox.ru`. The timer child passes the target the same way it does today.
- KTD4. Restore uses `restore_started=$(date +%s)` as the timeout base for both `wait_for` calls; `started` from state stays only for the "всего N мин" line.

### Threats and rollback (runtime: `index.py`, `server.py`)

- Asset: lead delivery and the visitor redirect. A read error after `handler` would drop the 302; KTD1's defensive read prevents it.
- PII: only the lead id and the spool file name (random token) are logged.
- Rollback: `git revert <sha>`, sync live checkout, `pm2 reload forms-backup`; health check is a test POST to forms-test returning 302.

## Implementation Units

### U1. Bitrix24 outcome in the reserve log

- Goal: R5, R6, R8.
- Files: `site78-releases/2026-07-29/backend-arwox-lead-form/index.py`, `forms-failover/server.py`, tests `forms-failover/server-test.py` (extend; its stub `index.py` gains `B24_OUTCOME`) and `site78-releases/2026-07-29/backend-arwox-lead-form/test_lead.py` (extend).
- Approach: KTD1. Line format: `forms-backup lead <ISO> host=<h> code=<c> result=<r> b24=<v>`.
- Test scenarios:
  - `_lead_status` with stubbed `call_b24` result 123 → `B24_OUTCOME.value == "lead:123"`.
  - transient failure and enqueue success → `queue:<file>`.
  - consent refusal → server line ends `b24=-`.
  - two sequential requests do not leak the previous value.
  - drain of one queued item with stubbed success → stdout has `spool-sent spool=<file> b24=lead:<id>`.
  - server line contains no name, phone or e-mail from the POST.
- Verification: `python3 forms-failover/server-test.py` and `WEBHOOK_URL=x python3 site78-releases/2026-07-29/backend-arwox-lead-form/test_lead.py` → PASS, rc 0.

### U2. Control script

- Goal: R1–R4, R7. Dependencies: U1 (log format).
- Files: `git mv forms-failover/demo.sh forms-failover/forms-ctl.sh`, `git mv forms-failover/demo-test.sh forms-failover/forms-ctl-test.sh`.
- Approach: KTD2–KTD4. Rename `simulate` to `test`; keep `--no-feed`; `simulate` is an unknown command. `lead_feed` reads a fifth field for `b24` so `result=sent` still matches; it also prints `spool-sent` lines (R7). State file names may stay.
- Test scenarios:
  - `--help` lists test, restore, status; `simulate` exits 64.
  - `--prod` in any position targets `forms.arwox.ru`; no flag targets `forms-test.arwox.ru`.
  - feed: `b24=lead:55` → "Bitrix24 лид #55"; `b24=queue:x.json` then `spool-sent spool=x.json b24=lead:56` → queue line then "📬 из очереди: Bitrix24 лид #56"; `b24=-` → "не передана"; old line without `b24=` counted.
  - restore with state `.started` 20 min old → exit 0 on both the first wait and the retry after `apply normal`.
  - timer child calls `forms-ctl.sh restore`.
  - all existing demo-test cases pass under the new name.
- Verification: `bash forms-failover/forms-ctl-test.sh` → PASS N/N.

### U3. References

- Goal: R1.
- Files: `forms-failover/README.md`, `architecture.md`.
- Approach: replace `demo.sh` / `demo-test.sh` with `forms-ctl.sh` / `forms-ctl-test.sh`; owner usage shows `test [--prod]`, `restore [--prod]`, `status [--prod]`.
- Test expectation: none -- documentation only; checked by grep.

## Verification Contract

- U1 and U2 verification commands → PASS, rc 0.
- `bash -n forms-failover/forms-ctl.sh`; `python3 -m py_compile` on `index.py` and `server.py` → rc 0.
- `grep -rnE "demo(-test)?\.sh" forms-failover forms-failover/README.md architecture.md` → 0 lines.
- Pre-sync gate before updating the live checkout: no live process from `forms-failover/state/demo.timer.pid`, `dns-switch.sh status` normal for forms-test and forms.arwox.ru.
- Live: after sync and `pm2 reload forms-backup`, a test POST to forms-test returns 302 and the log line ends with `b24=lead:<id>`.

## Definition of Done

- All Verification Contract items pass with output recorded in the bd atom.
- PR merged to `main`; live checkout synced after the pre-sync gate; `forms-backup` reloaded.
- dcfg-rh17x closed by R4 evidence.
- No abandoned code from failed attempts in the diff.
