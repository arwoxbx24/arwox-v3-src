# TZ dcfg-k54yf — SmartCaptcha HTTP 4xx is a rejection, not an outage

## U1
Goal: in `site78-releases/2026-07-29/backend-arwox-lead-form/index.py`, `_captcha_ok` must return `"fail"` when the SmartCaptcha validator answered with HTTP 4xx. Only no response (network error, timeout) or HTTP 5xx is `"unavailable"`.

Why: live probe 14.10 on forms-test (reserve, merged 358fdb3) — POST with `smart-token=fc14-invalid-token` returned 302 `?ok=1#sent` and created lead 3220. `https://smartcaptcha.yandexcloud.net/validate` answers rejections with HTTP 4xx and a JSON body `{"status":"failed",...}` (probe: `code=403`). `urllib.request.urlopen` raises `urllib.error.HTTPError` (a subclass of `URLError`), the bare `except Exception` maps it to `"unavailable"`, and the lead passes with the `[captcha-unverified] ` prefix. That reopens the spam hole the captcha closes.

Change (minimal, inside `_captcha_ok` only):
- `except urllib.error.HTTPError as e:` before the generic handler: `return "unavailable" if e.code >= 500 else "fail"`.
- Keep the generic `except Exception: return "unavailable"` for network errors, timeouts, non-JSON.
- Do not touch the call site, the TITLE prefix, consent, the redirect contract or the spool.

Test (`test_lead.py`, one new case 11 after case 10): `urlopen` raises `urllib.error.HTTPError(url, 403, "Forbidden", {}, None)` → `index.handler` with `smart-token` returns the captcha error page (not 302 `#sent`) and makes 0 `crm.lead.add` calls. Add one assert that HTTP 503 → `_captcha_ok(...) == "unavailable"`.

Acceptance (run from the worktree root):
- `env WEBHOOK_URL=https://example/rest/1/x python3 -B site78-releases/2026-07-29/backend-arwox-lead-form/test_lead.py` → `PASS: все проверки прошли`
- `python3 -B forms-failover/server-test.py` → `PASS 3/3`, `PASS 6/6`, `PASS 15/15`
- `git diff --check` exit 0

Rules: SOLID, DRY, KISS, YAGNI; minimal diff; разведка — repowise; индекс: repowise/CBM проверен, нет — `tools/bin/code-memory-enable`. No secrets, no `secrets/`, no PII in logs. Do not commit; do not push.
Rollback: revert this commit; the previous behavior is 358fdb3.
