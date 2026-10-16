#!/usr/bin/env bash
# fn-deploy-test: contract tests for fn-deploy.sh --rollback and --target/--env
# using a stub yc first on PATH. Never calls the real yc: no cloud calls, no secrets.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY="$SCRIPT_DIR/fn-deploy.sh"

tmp=$(mktemp -d /tmp/fn-deploy-test.XXXXXX)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin"

# Fixture for `yc ... version get-by-tag` (dry-run cases): dummy values only.
cat > "$tmp/version.json" <<'EOF'
{"id":"ver-old-0001","runtime":"python312","entrypoint":"index.handler","resources":{"memory":134217728},"execution_timeout":"5s","service_account_id":"sa-test","log_options":{"folder_id":"folder-test"},"environment":{"WEBHOOK_URL":"https://prod-webhook.invalid/token","LOG_LEVEL":"info"}}
EOF

cat > "$tmp/bin/yc" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$GUARD_TEST_TMP/yc.calls"
case "$*" in
  *get-by-tag*) cat "$GUARD_TEST_TMP/version.json" ;;
esac
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

case3() { # --target X with WEBHOOK_URL override: dry-run shows new id, env masked
  rm -f "$tmp/yc.calls"
  out=$(bash "$DEPLOY" --target X --env WEBHOOK_URL=https://crm.invalid/rest/1/x --dry-run 2>&1); rc=$?
  [ "$rc" = 0 ] \
    && grep -q -- '--function-id X' <<<"$out" \
    && grep -q 'WEBHOOK_URL=\*\*\*' <<<"$out" \
    && ! grep -q 'https://' <<<"$out"
}

case4() { # --target X without WEBHOOK_URL override: refused before any yc call
  rm -f "$tmp/yc.calls"
  out=$(bash "$DEPLOY" --target X --dry-run 2>&1); rc=$?
  [ "$rc" != 0 ] && grep -q 'WEBHOOK_URL' <<<"$out" && [ ! -e "$tmp/yc.calls" ]
}

case5() { # default dry-run still targets the production function id
  rm -f "$tmp/yc.calls"
  out=$(bash "$DEPLOY" --dry-run 2>&1); rc=$?
  [ "$rc" = 0 ] \
    && grep -q -- '--function-id d4eb92qbfgt3ac0udlmm' <<<"$out" \
    && grep -q 'WEBHOOK_URL=\*\*\*' <<<"$out"
}

PASS=0
FAIL=0
for i in 1 2 3 4 5; do
  if "case$i"; then PASS=$((PASS+1)); else FAIL=$((FAIL+1)); printf 'FAIL case %s\n' "$i"; fi
done
if [ "$FAIL" = 0 ]; then
  printf 'PASS %d/5\n' "$PASS"
  exit 0
else
  printf 'FAIL %d/5 (PASS %d/5)\n' "$FAIL" "$PASS"
  exit 1
fi
