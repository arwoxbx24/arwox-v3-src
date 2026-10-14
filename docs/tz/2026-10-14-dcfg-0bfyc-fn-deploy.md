# TZ dcfg-0bfyc — forms-failover/fn-deploy.sh (Cloud Function version deploy)

## U1
Goal: one bash script `forms-failover/fn-deploy.sh` that creates a new version of Yandex Cloud Function `d4eb92qbfgt3ac0udlmm` from the repo backend dir `site78-releases/2026-07-29/backend-arwox-lead-form/`, copying all settings of the version tagged `$latest`, and can roll back.

Why: `architecture.md:50` — no deploy script exists; the function still runs the 2026-07-24 code (version `d4egc5urnmocbb7t720n`). Its environment holds secrets (`SMARTCAPTCHA_SECRET`, `WEBHOOK_URL`, `CONSENT_HMAC_KEY`); the agent must never see or print their values.

Interface:
- `fn-deploy.sh --help` → usage on stdout, rc 0, no action.
- `fn-deploy.sh --dry-run` → print the planned `yc` command with every env value masked as `KEY=***`; no API write.
- `fn-deploy.sh` → create the version; print only `old=<id> new=<id> env_keys=<comma list>`.
- `fn-deploy.sh --rollback <version-id>` → `yc serverless function set-tag --id d4eb92qbfgt3ac0udlmm --version-id <id> --tag '$latest'`; print `rollback latest=<id>`.

Implementation (verified syntax, `yc serverless function version create --help` on this host):
- Read source: `yc serverless function version get-by-tag --function-id d4eb92qbfgt3ac0udlmm --tag '$latest' --format json`.
- Take from it with `jq`: `id`, `runtime`, `entrypoint`, `resources.memory` (bytes → pass as `<n>B`… use `--memory "$((mem/1048576))MB"`), `execution_timeout` (e.g. `30s` → `--execution-timeout 30s`), `service_account_id`, `log_options.folder_id` (`--log-folder-id`), and `.environment` as `--environment KEY=VALUE` pairs.
- Pass env through a bash array built from `jq -r '.environment | to_entries[] | "\(.key)=\(.value)"'`; never echo the array, never `set -x`.
- Create: `yc serverless function version create --function-id d4eb92qbfgt3ac0udlmm --runtime … --entrypoint … --memory … --execution-timeout … --service-account-id … --log-folder-id … --source-path <backend dir> "${env_args[@]}" --format json` and print `new=` from `.id`.
- Package dir must contain only `index.py`, `consent.py` and their runtime imports present in that dir; exclude `test_*.py` and `__pycache__` by copying the needed `*.py` (not `test_*`) into a `mktemp -d` dir and passing that dir; remove it with `trap`.
- `set -euo pipefail`; fail fast if `yc` or `jq` missing.

Acceptance (from worktree root):
- `bash -n forms-failover/fn-deploy.sh` exit 0
- `forms-failover/fn-deploy.sh --help` rc 0
- `forms-failover/fn-deploy.sh --dry-run` prints a `yc serverless function version create` line where every `--environment` value is `***`; output contains `SMARTCAPTCHA_SECRET=***`.
- `git diff --check` exit 0

Rules: SOLID, DRY, KISS, YAGNI; minimal; разведка — repowise; индекс: repowise/CBM проверен, нет — `tools/bin/code-memory-enable`. Do not run the real create (no `--dry-run`) — the orchestrator does that after merge. No secrets in output, logs or git. Do not commit; do not push.
Rollback: revert this commit (script only; no runtime change until it is run).

## U2 (TZ v2 — defect found at acceptance)
`forms-failover/fn-deploy.sh:104` passes `"${env_args[@]}"` as bare `KEY=VALUE` positional arguments; `yc` needs `--environment KEY=VALUE` for each pair (same as the `--dry-run` preview at line 98). Fix: build a `real_env` array with `--environment "$kv"` per pair and pass it at line 104. Dry-run output must stay identical. Acceptance: `bash -n` exit 0; `--dry-run` output unchanged; `grep -n 'environment "\$kv"' forms-failover/fn-deploy.sh` finds the new line.

## U3 (independent review, Claude SDK haiku)
After `mapfile` (line ~75) fail fast when the tagged version has no environment: `(( ${#env_args[@]} > 0 )) || die "tagged version has no environment"`, and read it with `jq -r '(.environment // {}) | to_entries[] | …'`; same `// {}` at the `env_keys=` line. Acceptance: `bash -n` exit 0; `--dry-run` output unchanged.

## U4 (independent review, Claude SDK haiku, 2nd pass)
Defect: line 75 reads env pairs line by line; a value containing a newline splits into fragments, the real create passes bogus `--environment` args, and `--dry-run` prints a fragment of a secret value as a "key" (`${kv%%=*}=***`). Fix: emit NUL-delimited pairs — `jq -j '(.environment // {}) | to_entries[] | "\(.key)=\(.value)\u0000"'` and `mapfile -d '' -t env_args`. Nothing else changes. Acceptance: `bash -n` exit 0; `--dry-run` output identical to before; `grep -n "mapfile -d ''" forms-failover/fn-deploy.sh` finds line 75.
