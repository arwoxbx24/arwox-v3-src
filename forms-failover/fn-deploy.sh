#!/usr/bin/env bash
# fn-deploy.sh — create/rollback Yandex Cloud Function d4eb92qbfgt3ac0udlmm versions.
# ponytail: single-purpose bash helper; upgrade path = orchestrator-run CI pipeline.
# Never prints env values; `--dry-run` previews; real create is orchestrator-owned.
set -euo pipefail

readonly FN_ID=d4eb92qbfgt3ac0udlmm
readonly FN_DIR="site78-releases/2026-07-29/backend-arwox-lead-form"

usage() {
  cat <<'EOF'
Usage: forms-failover/fn-deploy.sh --help | --dry-run | --rollback <version-id>

  (no args)              Create a new function version from the repo backend dir,
                         copying all settings of the version tagged $latest.
                         Prints: old=<id> new=<id> env_keys=<keys>
  --dry-run              Print the planned "yc serverless function version create"
                         command with every env value masked as KEY=***; no API write.
  --rollback <version-id>
                         Move the $latest tag to <version-id>.
EOF
}

die() { echo "fn-deploy: $*" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || die "required tool missing: $1"; }

TMP_DIR=""; trap '[[ -n "$TMP_DIR" ]] && rm -rf "$TMP_DIR"' EXIT

main() {
  case "${1:-}" in
    --help|-h) usage; exit 0 ;;
  esac

  need yc
  need jq

  local dry=0
  case "${1:-}" in
    --rollback)
      [[ $# -ge 2 ]] || { usage >&2; die "--rollback requires <version-id>"; }
      yc serverless function set-tag --id "$FN_ID" --version-id "$2" --tag '$latest'
      echo "rollback latest=$2"
      exit 0
      ;;
    --dry-run) dry=1; [[ $# -eq 1 ]] || die "--dry-run takes no arguments" ;;
    "") [[ $# -eq 0 ]] || die "unexpected arguments" ;;
    *) usage >&2; die "unknown argument: $1" ;;
  esac

  local root src
  root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  src="$root/$FN_DIR"
  [[ -d "$src" ]] || die "backend dir not found: $src"

  # Settings copied from the currently tagged version (read-only call).
  local j
  j="$(yc serverless function version get-by-tag --function-id "$FN_ID" --tag '$latest' --format json)"

  local old_id runtime entrypoint mem mem_mb exec_timeout sa log_folder
  old_id="$(jq -r '.id' <<<"$j")"
  runtime="$(jq -r '.runtime' <<<"$j")"
  entrypoint="$(jq -r '.entrypoint' <<<"$j")"
  mem="$(jq -r '.resources.memory' <<<"$j")"
  exec_timeout="$(jq -r '.execution_timeout' <<<"$j")"
  sa="$(jq -r '.service_account_id // empty' <<<"$j")"
  log_folder="$(jq -r '.log_options.folder_id // empty' <<<"$j")"

  [[ "$runtime" != "null" && "$entrypoint" != "null" ]] || die "cannot read runtime/entrypoint from tagged version"
  [[ "$mem" =~ ^[0-9]+$ ]] || die "cannot read memory from tagged version"
  [[ -n "$exec_timeout" && "$exec_timeout" != "null" ]] || die "cannot read execution_timeout from tagged version"
  mem_mb=$((mem / 1048576))

  # Env as KEY=VALUE array; values are secrets — never echo them, never set -x.
  local -a env_args=()
  mapfile -d '' -t env_args < <(jq -j '(.environment // {}) | to_entries[] | "\(.key)=\(.value)\u0000"' <<<"$j")
  (( ${#env_args[@]} > 0 )) || die "tagged version has no environment"

  local -a flags=(
    --function-id "$FN_ID"
    --runtime "$runtime"
    --entrypoint "$entrypoint"
    --memory "${mem_mb}MB"
    --execution-timeout "$exec_timeout"
  )
  [[ -n "$sa" ]] && flags+=(--service-account-id "$sa")
  [[ -n "$log_folder" ]] && flags+=(--log-folder-id "$log_folder")

  # Package dir: only runtime *.py (no test_*, no __pycache__).
  local tmp
  tmp="$(mktemp -d)"
  TMP_DIR="$tmp"
  find "$src" -maxdepth 1 -type f -name '*.py' ! -name 'test_*.py' -print0 |
    xargs -0 -r cp -t "$tmp"
  find "$tmp" -maxdepth 1 -type f -name '*.py' | grep -q . || die "no runtime .py files to package"

  if [[ "$dry" == 1 ]]; then
    local -a shown=("${flags[@]}" --source-path "<package-dir>")
    local kv
    for kv in "${env_args[@]}"; do shown+=(--environment "${kv%%=*}=***"); done
    echo "yc serverless function version create ${shown[*]}"
    return 0
  fi

  local j2 new_id
  local -a real_env=()
  for kv in "${env_args[@]}"; do real_env+=(--environment "$kv"); done
  j2="$(yc serverless function version create "${flags[@]}" --source-path "$tmp" "${real_env[@]}" --format json)"
  new_id="$(jq -r '.id' <<<"$j2")"
  [[ "$new_id" != "null" && -n "$new_id" ]] || die "version create returned no id"

  echo "old=$old_id new=$new_id env_keys=$(jq -r '(.environment // {}) | keys | join(",")' <<<"$j")"
}

main "$@"
