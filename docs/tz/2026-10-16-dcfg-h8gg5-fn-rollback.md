# TZ dcfg-h8gg5 — fn-deploy.sh --rollback calls a yc subcommand that does not exist

## U1
Goal: `forms-failover/fn-deploy.sh --rollback <version-id>` must move the `$latest` tag of the Cloud Function back to `<version-id>` with a command that exists in yc 1.36.0.

Why (FACT, `yc ... --help` on this server, yc 1.36.0): `fn-deploy.sh:41` runs `yc serverless function set-tag --id "$FN_ID" --version-id "$2" --tag '$latest'`, but `yc serverless function` has no `set-tag` command. The existing command is:
```
yc serverless function version set-tag [--id] <VERSION-ID> --tag <TAG> [--async]
  --id string    Function version id.
  --tag string   Tag to set.
```
All other yc calls in the file (`version get-by-tag --function-id … --tag`, `version create` with its flags) were checked against `--help` and are valid — do not touch them.

Change (one line in `fn-deploy.sh`): line 41 becomes
`yc serverless function version set-tag --id "$2" --tag '$latest'`
Nothing else in `fn-deploy.sh`.

Test first — new file `forms-failover/fn-deploy-test.sh` (bash, style of `forms-gw-guard-test.sh`: `SCRIPT_DIR`, temp dir, `PASS n/n` on success, non-zero exit on failure). It must fail before the change:
- Put a stub `yc` first in `PATH` (temp dir) that appends its arguments as one line to a file and exits 0. Never call the real yc.
- Case 1: `bash "$SCRIPT_DIR/fn-deploy.sh" --rollback V1` → exit 0 and the stub recorded exactly `serverless function version set-tag --id V1 --tag $latest`.
- Case 2: `bash "$SCRIPT_DIR/fn-deploy.sh" --rollback` (no id) → non-zero exit and the stub was not called.
- Print `PASS 2/2` when both pass.

Acceptance (run from the worktree root):
- `bash -n forms-failover/fn-deploy.sh` exit 0
- `bash forms-failover/fn-deploy-test.sh` → `PASS 2/2` (and it failed on case 1 before the one-line change — show that output)
- `git diff --check` exit 0; changed/new files: only `forms-failover/fn-deploy.sh` and `forms-failover/fn-deploy-test.sh`.

Threats (prod §3): none new — the script is run by an operator/agent only; the version id goes to yc as one quoted argument, as before. The test uses a stub, no cloud calls, no secrets.
Rollback (prod §5): revert this commit; the cloud function itself is not changed by this work.
Rules: SOLID, DRY, KISS, YAGNI; minimal diff; разведка — repowise; индекс: repowise/CBM проверен, нет — `tools/bin/code-memory-enable`. No secrets, no `secrets/`. Do not commit; do not push.
