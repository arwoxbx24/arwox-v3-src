# TZ dcfg-w8ul9 — restore clears the drill state; guard test 50 hermetic

## U1
Discovery: repowise first (line "разведка — repowise"); index: repowise/CBM checked, missing → `tools/bin/code-memory-enable`.
Files you own: `forms-failover/forms-ctl.sh`, `forms-failover/forms-ctl-test.sh`, `forms-failover/forms-gw-guard-test.sh`. Nothing else.
Method: TDD — tests first, see them fail, then fix.

Facts: `test` writes `$STATE` (`state/demo-$FQDN.json`, forms-ctl.sh ~line 352); `restore` (~lines 403-419) never removes it. forms-gw-guard.sh prefixes alerts with «УЧЕНИЯ: » while that file exists (GUARD_DRILL_STATE). Guard test case50 does `unset GUARD_DRILL_STATE`, so it reads the real path and fails when a drill file exists in the checkout.

Change:
1. forms-ctl.sh `restore`: after the step-4 line (DNS back on Yandex) remove `$STATE` (`rm -f "$STATE"` — same idiom as the script's other rm -f of its own temp/state files). Only on success; failure paths unchanged.
2. forms-gw-guard-test.sh case50: set `GUARD_DRILL_STATE="$tmp/drill/absent.json"` (non-existent) instead of unset.
Tests: forms-ctl-test.sh — a restore case asserts the state file is gone after a successful restore (and stays if restore fails, if such a case is cheap with existing stubs). Guard: run case50 with a drill file present at the default path is NOT needed — the explicit path makes it hermetic.
Run both suites once at the end; all PASS.
Principles: KISS, minimal diff. Rollback: revert the commit.
