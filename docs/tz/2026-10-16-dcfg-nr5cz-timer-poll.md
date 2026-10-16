# TZ dcfg-nr5cz — forms-ctl-test timer cases fail under load

## U1
Discovery: repowise first (line "разведка — repowise"); index: repowise/CBM checked, missing → `tools/bin/code-memory-enable`.
Files you own: `forms-failover/forms-ctl-test.sh` only. Do NOT touch `forms-ctl.sh` unless step 1 proves a script bug.
Method: systematic debugging — measure first, then the minimal fix.

Facts: `bash forms-failover/forms-ctl-test.sh` prints `FAIL case 15`, `FAIL case 17`, `FAIL 2/35` (two runs, load average ~26). Cases 15 (line ~268) and 17 (line ~285) wait for the detached auto-restore timer (forms-ctl.sh line 95, `setsid nohup ... sleep; forms-ctl.sh restore`) to write `apply normal --fqdn forms-test.arwox.ru` into `$TMP/dns-switch.args`, polling only `{1..30}` × `sleep 0.1` = 3 s. Case 16 and 17 also poll a pid file for 3 s.

Steps:
1. Prove the cause: run the suite once; for case 15 record how many seconds pass until the `apply normal` line appears (e.g. temporarily extend the poll and print elapsed time, then remove the print). If the line never appears even after 60 s → it is a real script bug: report the exact restore error from `$TMP/err`/timer output and stop, no test change.
2. If it is only slow: raise the poll ceiling in cases 15, 16 and 17 from `{1..30}` to `{1..300}` (30 s). The loops already return as soon as the condition holds, so fast runs are unaffected and no assertion is weakened.
3. Run the suite once at the end: must print `PASS 35/35`.
Report: the measured seconds from step 1 and the final suite line.
Principles: KISS, minimal diff, no other changes. Rollback: revert the commit.

## U2
Run this part now (U1 is already applied in the working tree — keep it). TZ v2 — reason: U1 fixed cases 15–17, but the same 3 s poll ceiling remains in two places, and the suite now prints `FAIL case 20`, `FAIL 1/35`.
File: `forms-failover/forms-ctl-test.sh` only.
Change: line ~78 (stub, `DEMO_RELEASE_TIMER_ON_FEED`) `for _ in {1..30}` → `{1..300}`; line ~315 (case20) `for _ in {1..30}` → `{1..300}`. After the change, `grep -c '{1\.\.30}' forms-failover/forms-ctl-test.sh` must print 0. Nothing else.
Run the suite once: must print `PASS 35/35`. Report the grep count and the suite line.
