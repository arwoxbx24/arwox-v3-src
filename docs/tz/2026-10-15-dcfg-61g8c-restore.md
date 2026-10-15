# TZ dcfg-61g8c (+ dcfg-5t9af) — forms-ctl.sh: slow yc mutations must not abort restore/test; probe cert rule depends on DNS

Run status: U1 is already implemented in this worktree (uncommitted, tests PASS 33/33). Execute ONLY section U2 below.

## U1
Discovery: repowise first (line "разведка — repowise"); index: repowise/CBM checked, missing → `tools/bin/code-memory-enable`.
Files you own: `forms-failover/forms-ctl.sh`, `forms-failover/forms-ctl-test.sh`. Nothing else.
Method: TDD. Write the new test cases FIRST in forms-ctl-test.sh (stub style already used there), run `bash forms-failover/forms-ctl-test.sh` and confirm the new cases FAIL against the current script; then change forms-ctl.sh until all pass.

Facts:
- `yc serverless api-gateway add-domain` takes up to ~110 s (demo.log 2026-10-09 11:46:29→11:48:19). Today every yc call is `timeout 60` (yc_exit: rc 124 → message + exit 1). 15.10 the auto-restore died: `restore yc-add rc=124`, though Yandex finished the attach server-side.
- probe: `[ "$cert_days" -lt 7 ] && rc=1` regardless of DNS; LE renewal is impossible while DNS is on Yandex → hourly non-actionable Telegram alerts near expiry.

Change:
1. Bounds: read calls (`api-gateway get`, `certificate list`) keep `timeout 60`; mutating calls (`add-domain`, `remove-domain`) use `timeout 300`.
2. After a mutating call returns rc ≠ 0 (any, incl. 124): re-read the gateway once with the bounded `get`; if the domain is already in the target state (attached after add-domain, absent after remove-domain) → `record` a line `yc-<add|remove> verified=attached|detached after rc=<rc>` and continue as success; otherwise keep today's failure path (yc_exit). No retry loops.
3. probe: `cert_days < 7` sets rc 1 only when `dns_count "$BEGET_IP"` = 6 (DNS on reserve). With DNS not on reserve the line gets ` cert=expiring` appended and rc is unaffected. Missing cert (-9999) stays a failure. Keep the output line format `probe rc=<n> gate=… gate_main=… cert_days=<n>` (+ optional ` cert=expiring`).

Tests to add (stubs only, no network):
- T-a restore: add-domain stub sleeps/returns 124, the following `get` stub shows the domain attached → restore rc 0, log has `verified=attached`.
- T-b restore: add-domain 124 and get shows NOT attached → restore rc 1 with the existing message.
- T-c test: remove-domain 124 and get shows detached → test continues past stage 1.
- T-d probe: cert_days=5, dig stubs → 0/6 on reserve → rc 0, line contains `cert=expiring`, no Telegram call.
- T-e probe: cert_days=5, 6/6 on reserve → rc 1 and Telegram called.
Run the suite once at the end; all PASS.

Principles: SOLID, DRY (one helper for "verify after mutating call" used by add and remove), KISS, YAGNI, fail fast; minimal diff; no new files; no real network in tests; no secrets.
Rollback: revert the commit.

## U2 (v2 — review defect of U1, found by orchestrator and SDK review)
Files you own: same two files. Method: TDD — add the failing test first, then fix.
Defect: `yc_verify_mutation` starts with `gateway=detached`; when the re-read `timeout 60 yc … api-gateway get` fails (rc≠0, timeout, unparseable JSON) the state stays `detached`, so a failed `remove-domain` plus a failed read is recorded `verified=detached` and treated as success.
Change: the gateway state is `unknown` until a successful `get` AND a successful jq parse of `.attached_domains`; only then `attached` or `detached`. Return 0 only on a confirmed target state; `unknown` → return 1 (existing yc_exit failure path).
Also fix the probe comment: renewal is impossible while DNS is on Yandex (so only a note); on the reserve (6/6) an expiring cert fails the probe.
Test to add: T-f test/remove: remove-domain stub rc 124 AND get stub rc 1 → command fails (rc ≠ 0), no `verified=detached` in the log.
Run `bash forms-failover/forms-ctl-test.sh` once at the end; all PASS.
