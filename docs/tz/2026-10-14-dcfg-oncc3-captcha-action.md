# TZ dcfg-oncc3 — captcha page posts back to the serving host; captcha outcome in logs

## U1
Goal: the SmartCaptcha page returned by `index.py` must submit the token form back to the same URL that served it, on every route (reserve `forms.arwox.ru` / `forms-test.arwox.ru`, API Gateway, direct Cloud Function URL). Each POST prints one log line with the captcha outcome and no personal data.

Why: owner human test 14.10 15:25:49 — reserve log `host=forms.arwox.ru code=200 result=other b24=-`, no second POST. The live page has `action="https://functions.yandexcloud.net/d4eb92qbfgt3ac0udlmm"` (`index.py:60` template, `index.py:98` fills it from `SELF_URL`). The token POST leaves the reserve and lands on the old-code Cloud Function, so a human pass on the reserve is impossible and DNS switches break the captcha. Logs have no captcha outcome, so a pass cannot be proven.

Change (file `site78-releases/2026-07-29/backend-arwox-lead-form/index.py` only):
1. In `_CAPTCHA_HTML` use `action=""` (an empty action posts to the document URL — HTML spec form submission). Remove the `.replace("[[ACTION]]", …)` line in `_captcha_page`. Keep `SELF_URL` and its use at `ref_origin` (line ~376) unchanged.
2. In `handler`, print exactly one line per captcha decision with `print(f"captcha={state}", flush=True)`:
   - `state = "page"` when the token is missing and the captcha page is returned;
   - otherwise the value of `captcha_state` (`ok`, `fail`, `unavailable`).
   No name, phone, token, IP or other field in the line.

Test (`test_lead.py`, new case 12 after case 11): a POST without `smart-token` returns a body containing `action=""` and not containing `functions.yandexcloud.net`.

Acceptance (from worktree root):
- `env WEBHOOK_URL=https://example/rest/1/x python3 -B site78-releases/2026-07-29/backend-arwox-lead-form/test_lead.py` → `PASS: все проверки прошли`, and its stdout contains `captcha=page` and `captcha=ok`
- `python3 -B forms-failover/server-test.py` → `PASS 3/3`, `PASS 6/6`, `PASS 15/15`
- `git diff --check` exit 0

Rules: SOLID, DRY, KISS, YAGNI; minimal diff; разведка — repowise; индекс: repowise/CBM проверен, нет — `tools/bin/code-memory-enable`. No PII in logs (AGENTS.md backend invariant). Do not change the redirect contract, consent, spool or `_captcha_ok`. Do not commit; do not push.
Threats: an empty action posts to the serving URL only — no open redirect, no new host. Rollback: revert this commit (previous behavior a7cf4ea).
