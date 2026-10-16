# TZ dcfg-fpej2 — forms-gw-guard notify(): use the sanitized text everywhere

## U1
Goal: in `forms-failover/forms-gw-guard.sh`, function `notify()`, the first `case "$type"` block builds `msg` from the raw `$2` (types `gw_resumed`, `low_balance` and the default `*)`), while the second block already uses the sanitized local `text` (quotes, CR/LF removed, max 400 chars, set at the top of `notify()`). Replace those three raw `$2` / `${2:-}` uses with `$text` / `${text:-}`.

Why: finding from ce-simplify-code 22.09 (dcfg-fpej2): the sanitized `text` is not used consistently; a message with a newline or quote reaches Telegram unsanitized for these three types.

Change: exactly those three substitutions inside the first `case "$type"` of `notify()`. Nothing else in the file; no other file.

Acceptance (run from the worktree root):
- `bash -n forms-failover/forms-gw-guard.sh` exit 0
- `sed -n '/^notify()/,/^}/p' forms-failover/forms-gw-guard.sh | grep -c '\$2\|\${2'` → 1 (only the `local ... text="$2"` line)
- `bash forms-failover/forms-gw-guard-test.sh` → `PASS 50/50`
- `git diff --check` exit 0; diff ≤ 6 lines.

Threats: none new — output text only gets stricter. Rollback: revert this commit; `pm2 reload forms-gw-guard` is not needed (cron-run script re-reads the file each tick).
Rules: SOLID, DRY, KISS, YAGNI; minimal diff; разведка — repowise; индекс: repowise/CBM проверен, нет — `tools/bin/code-memory-enable`. No secrets. Do not commit; do not push.
