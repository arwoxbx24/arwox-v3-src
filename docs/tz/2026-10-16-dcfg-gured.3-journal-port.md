# TZ dcfg-gured.3 v2 — port the accepted journal change (U1/U2) onto current main

## U1
Goal: the form handler writes one JSON journal line per stage with a shared request id and no personal data, as already implemented and accepted by Claude on Codex commit `57bc72b` (branch `origin/codex/dcfg-gured.3-journal`, PR #20). PR #20 conflicts with main because main later changed the captcha page in the same `index.py` (dcfg-xjdha, merge `0fc8f15`). Re-apply the same change on current main.

Source of truth for the change: `git show 57bc72b -- site78-releases/2026-07-29/backend-arwox-lead-form/index.py site78-releases/2026-07-29/backend-arwox-lead-form/test_journal.py docs/tz/2026-10-08-gured-journal.md` (read it with git, do not merge the branch).

Change:
- `site78-releases/2026-07-29/backend-arwox-lead-form/index.py`: apply the journal hunks of `57bc72b` by hand so that every current main line stays (keep the xjdha captcha page JS and the `captcha=` prints). No other behavior change.
- `site78-releases/2026-07-29/backend-arwox-lead-form/test_journal.py`: take it from `57bc72b` unchanged unless a test needs the current main API.
- `docs/tz/2026-10-08-gured-journal.md`: take it from `57bc72b` unchanged.

Acceptance (run from the worktree root):
- `env WEBHOOK_URL=https://example/rest/1/x PYTHONDONTWRITEBYTECODE=1 python3 site78-releases/2026-07-29/backend-arwox-lead-form/test_journal.py` exit 0
- `env WEBHOOK_URL=https://example/rest/1/x python3 -B site78-releases/2026-07-29/backend-arwox-lead-form/test_lead.py` → `PASS: все проверки прошли`
- `python3 -B forms-failover/server-test.py` → all PASS, 0 FAIL
- `git diff --check` exit 0; `git diff origin/main --stat` lists only the three files above plus this TZ; index.py changed lines ≤ 40.

Threats: journal lines must carry no name, phone, email or message text (test_journal.py asserts it). Rollback: revert the commit; Cloud Function previous version stays for rollback (`fn-deploy.sh --rollback`).
Rules: SOLID, DRY, KISS, YAGNI; minimal diff; no secrets; do not commit, do not push.
