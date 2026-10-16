# TZ dcfg-5e55i — review owner and hourly alert for [captcha-unverified] leads

## U1
Goal: (1) the project docs name who reviews CRM leads titled `[captcha-unverified] …`; (2) the form guard sends one alert when more than N=5 such submissions happened in the last hour.

Facts:
- `index.py:395` prints `captcha=<state>` to stdout for every submission that reached the captcha check; `captcha=unavailable` = lead created with the `[captcha-unverified] ` prefix.
- Reserve route: stdout of pm2 `forms-backup` goes to `/root/.pm2/logs/forms-backup-out.log`; pm2 `time: true` prefixes each line with a timestamp (check the real format in the file before parsing).
- Cloud Function route (function id `d4eb92qbfgt3ac0udlmm`, folder `b1g7fof71b9b632o3a4r`): stdout goes to the folder default log group. Verified syntax (yc 1.36.0 `yc logging read --help`): `yc logging read <LOG-GROUP-NAME>|<LOG-GROUP-ID> [SINCE] [FILTER]` with flags `--group-name`, `--since` (e.g. `1h`), `--resource-ids`, `--limit`, `--format json` is a global flag. Do not use `--filter`; count `captcha=unavailable` locally. Exact call: `yc --profile default logging read default --since 1h --resource-ids d4eb92qbfgt3ac0udlmm --folder-id b1g7fof71b9b632o3a4r --format json` (log group name `default`; yc needs `--profile default`). Reserve log line format: `2026-10-16T11:21:44: captcha=unavailable` (local time +0300). Tests stub `yc`; never call the real one in tests.
- `forms-failover/forms-gw-guard.sh` runs every minute under pm2 and already has `notify <type> <text>` (sanitized text, Telegram channel, anti-repeat state).

Change:
1. `forms-failover/forms-gw-guard.sh`: add one function `check_captcha_unverified` called once per guard tick but doing work at most once per hour (timestamp in the guard's existing state dir). It sums `captcha=unavailable` lines of the last 60 minutes from the reserve log and from `yc logging read … --resource-ids d4eb92qbfgt3ac0udlmm --since 1h`. If the sum > `GUARD_CAPTCHA_UNVERIFIED_MAX` (default 5) → `notify captcha_unverified "<sum>"` with a message type line in the first `case` of `notify()`: `⚠️ Заявок без проверки капчи за час: <n> (> <max>). Проверьте лиды [captcha-unverified] в Bitrix24.` A failure to read either source must not break the guard tick (log the reason, continue). No personal data in messages or logs — only counts.
2. `forms-failover/forms-gw-guard-test.sh`: new cases with stubs (no real yc, no Telegram): sum 6 → one `captcha_unverified` notify; sum 5 → none; second tick within the hour → no second read; yc stub failing → tick still exits 0. Existing 50 cases stay green.
3. `architecture.md`: one short English section «Captcha-unverified leads»: the reviewer is the lead's responsible user in Bitrix24 (`ASSIGNED_BY_ID` set by the form handler); they check every `[captcha-unverified]` lead and delete spam; alert rule `> 5 per hour` from forms-gw-guard.

Acceptance (run from the worktree root):
- `bash -n forms-failover/forms-gw-guard.sh` exit 0
- `bash forms-failover/forms-gw-guard-test.sh` → `PASS n/n`, n ≥ 54
- `grep -c 'captcha_unverified' forms-failover/forms-gw-guard.sh` ≥ 2
- `grep -c 'Captcha-unverified leads' architecture.md` = 1
- `git diff --check` exit 0; changed files only the three above plus this TZ.

Threats: the guard reads a local log and the cloud log with existing credentials; output is a count only (no PII). Rollback: revert the commit; the guard re-reads the file every tick.
Rules: SOLID, DRY, KISS, YAGNI; minimal diff; no secrets, no `secrets/`; do not commit, do not push.

## U2 (v2 — review fixes; the U1 diff is already in the worktree, keep it)
Review of the current diff (test run: `FAIL 2/54 (PASS 52/54)`, cases 51 and 53). Fix only these:
1. `forms-gw-guard.sh` ~319: reserve timestamps (`2026-10-16T11:21:44: captcha=unavailable`, local +0300) are parsed with host-local `date -d`; parse with explicit `+0300`. Test ~946-953 writes them with `date -u`; write the same `+0300` local format so cases 51/53 pass on any host TZ.
2. Cases 52/54 pass even with a broken counter: add one reserve line older than 60 min that must not count, so the window and the sum are proven.
3. ~339-343: yc stderr goes to /dev/null; log the first stderr line as the failure reason (counts/reasons only, no PII).
4. Declare `total` local.
5. Add the `architecture.md` section from U1 Change 3 (not done yet).
Acceptance: the U1 list, all green.
