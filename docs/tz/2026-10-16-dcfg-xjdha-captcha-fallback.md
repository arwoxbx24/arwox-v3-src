# TZ dcfg-xjdha — captcha page must not lose a lead when the SmartCaptcha widget cannot load

## U1
Goal: in `site78-releases/2026-07-29/backend-arwox-lead-form/index.py`, the captcha page button «Отправить заявку» must send the form even when `https://smartcaptcha.yandexcloud.net/captcha.js` did not load (`window.smartCaptcha` is undefined). Then the server decides as it does today: a live validator rejects the placeholder token (HTTP 4xx or `status != ok` → `"fail"`, `index.py:117-122`, no lead); an unreachable validator → `"unavailable"` → lead with TITLE prefix `[captcha-unverified] ` and 302 `#sent` (`index.py:123-125`, `:396`).

Why (FACT, code): when `captcha.js` fails, `__fail()` shows the button; the button calls `__capGo()` (`index.py:70`), which calls `__fail()` again when `window.smartCaptcha` is missing. No token is ever posted, and a POST without `smart-token` returns the captcha page again (`index.py:386-390`). The page promises «Нажмите кнопку — и заявка уйдёт менеджеру» (`index.py:59`), but the lead is lost. Project invariant (AGENTS.md «Бэкенд — инварианты»): a lead is never lost.

Change (minimal, captcha page JS only):
- In `__capGo()`: when `window.smartCaptcha` is undefined, put the value `captcha-unavailable` into the hidden `smart-token` input and submit the form `#f`, reusing the same hidden-input + submit code the widget callback already uses (`index.py:75-77`); guard with `__sent` so it posts once. When `window.smartCaptcha` exists but `__wid === null`, keep `__fail()`.
- Do not change `_captcha_ok`, the handler, consent, the redirect contract, the spool, `server.py`, or any other file except the test below.

Test first (`test_lead.py`, one new case 13 after case 12; it must fail before the change):
- The captcha page HTML (`index._captcha_page({...})` as case 12 builds it) contains, inside `__capGo`, a branch that sets `captcha-unavailable` and submits (assert both the literal `captcha-unavailable` and that `__capGo` no longer has `else{__fail();}` as its only fallback when `window.smartCaptcha` is missing).
- `index.handler` with `smart-token=captcha-unavailable` and validator raising HTTP 403 → captcha error page, 0 `crm.lead.add` calls.
- `index.handler` with `smart-token=captcha-unavailable` and validator raising `URLError` → exactly one `crm.lead.add` with TITLE starting `[captcha-unverified] ` and 302 `#sent`.

Acceptance (run from the worktree root):
- `env WEBHOOK_URL=https://example/rest/1/x python3 -B site78-releases/2026-07-29/backend-arwox-lead-form/test_lead.py` → `PASS: все проверки прошли`
- `python3 -B forms-failover/server-test.py` → all `PASS`
- `git diff --check` exit 0; changed files: only `index.py` and `test_lead.py`; diff ≤ 40 lines.

Threats (prod §3): no new server-side input path — any client can already post any `smart-token`; a live validator rejects it. Accepted risk unchanged: while the validator is unreachable, any token passes with the `[captcha-unverified]` mark (backlog dcfg-qj6w1, review process dcfg-5e55i).
Rollback (prod §5): revert this commit through the normal route; Cloud Function: previous version stays for rollback (`fn-deploy.sh`); reserve: `pm2 reload forms-backup` after revert.
Rules: SOLID, DRY, KISS, YAGNI; minimal diff; разведка — repowise; индекс: repowise/CBM проверен, нет — `tools/bin/code-memory-enable`. No secrets, no `secrets/`, no PII in logs. Do not commit; do not push.
