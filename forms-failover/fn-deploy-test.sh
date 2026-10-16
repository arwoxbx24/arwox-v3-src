#!/usr/bin/env bash
# fn-deploy-test: contract tests for fn-deploy.sh --rollback using a stub yc
# first on PATH. Never calls the real yc: no cloud calls, no secrets.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY="$SCRIPT_DIR/fn-deploy.sh"

tmp=$(mktemp -d /tmp/fn-deploy-test.XXXXXX)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin"

cat > "$tmp/bin/yc" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$GUARD_TEST_TMP/yc.calls"
exit 0
EOF
chmod +x "$tmp/bin/yc"

export PATH="$tmp/bin:$PATH"
export GUARD_TEST_TMP="$tmp"

case1() { # --rollback V1 moves $latest via an existing yc subcommand
  rm -f "$tmp/yc.calls"
  out=$(bash "$DEPLOY" --rollback V1 2>&1); rc=$?
  [ "$rc" = 0 ] && [ "$(cat "$tmp/yc.calls")" = 'serverless function version set-tag --id V1 --tag $latest' ]
}

case2() { # --rollback without version-id fails and never calls yc
  rm -f "$tmp/yc.calls"
  bash "$DEPLOY" --rollback >/dev/null 2>&1
  rc=$?
  [ "$rc" != 0 ] && [ ! -e "$tmp/yc.calls" ]
}

PASS=0
FAIL=0
for i in 1 2; do
  if "case$i"; then PASS=$((PASS+1)); else FAIL=$((FAIL+1)); printf 'FAIL case %s\n' "$i"; fi
done
if [ "$FAIL" = 0 ]; then
  printf 'PASS %d/2\n' "$PASS"
  exit 0
else
  printf 'FAIL %d/2 (PASS %d/2)\n' "$FAIL" "$PASS"
  exit 1
fi
