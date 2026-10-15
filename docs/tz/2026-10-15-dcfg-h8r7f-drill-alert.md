# TZ dcfg-h8r7f — forms-gw-guard.sh: alerts sent during a forms-ctl drill are marked «УЧЕНИЯ:»

## U1
Discovery: repowise first (line "разведка — repowise"); index: repowise/CBM checked, missing → `tools/bin/code-memory-enable`.
Files you own: `forms-failover/forms-gw-guard.sh`, `forms-failover/forms-gw-guard-test.sh`. Nothing else.
Method: TDD. Add the test cases FIRST, run `bash forms-failover/forms-gw-guard-test.sh`, confirm the new cases FAIL, then implement.

Facts:
- forms-ctl.sh `test` writes the drill state file `forms-failover/state/demo-<fqdn>.json` (`{started,at}`) and `restore` removes it; path base = the forms-failover directory (forms-ctl.sh: `STATE="$DIR/state/demo-$FQDN.json"`).
- Owner got a real-looking alert during the 15.10 drill: notify fallback_outage text at forms-gw-guard.sh:283 «$GUARD_FQDN: сбой основного канала — … ждём восстановления …».
- Guard knows `$GUARD_FQDN` (line 11); messages are built into `msg` inside notify() (lines 41-127) and sent via curl -K - (token on stdin).

Change:
1. New env `GUARD_DRILL_STATE` (default `<directory of forms-gw-guard.sh>/state/demo-$GUARD_FQDN.json`).
2. In notify(), right before sending: if that file exists, prefix the final `msg` with `УЧЕНИЯ: ` (exactly this, then the existing text). Nothing else changes: same debounce, same state writes, same types, same failover decisions.

Tests to add:
- drill file present → the captured Telegram text starts with `УЧЕНИЯ: ` for a fallback_outage notification.
- drill file absent → text unchanged (no prefix).
Run the whole suite once at the end; all PASS.

Principles: KISS, YAGNI, minimal diff; no change to failover logic; no secrets printed; no real network in tests.
Rollback: revert the commit.
