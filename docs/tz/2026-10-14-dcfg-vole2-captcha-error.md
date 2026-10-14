# TZ dcfg-vole2 — log why SmartCaptcha validation is "unavailable"

## U1
Goal: when `_captcha_ok` in `site78-releases/2026-07-29/backend-arwox-lead-form/index.py` (lines 105-121) returns `"unavailable"`, stdout gets one line naming the cause, so the next live probe shows the root cause.

Why: 14.10 15:43 an invalid token on the reserve gave `captcha=unavailable` and created lead 3224 (fail-open), while a direct `curl` to `https://smartcaptcha.yandexcloud.net/validate` answers 403 in 0.2 s. `except Exception: return "unavailable"` (line 120) hides the error.

Change (only `_captcha_ok`, nothing else):
- `except urllib.error.HTTPError as e:` — before returning `"unavailable"` for `e.code >= 500`, `print(f"captcha_error=http{e.code}", flush=True)`.
- `except Exception as e:` — `print(f"captcha_error={type(e).__name__}:{getattr(e, 'reason', '')}", flush=True)` then `return "unavailable"`.
- Never print the token, secret, IP, request data or response body (PII/secret rule, AGENTS.md).
- `test_lead.py`: in the existing outage case (urlopen raises `URLError`), assert stdout contains `captcha_error=URLError:`. Follow how the file already captures stdout for `captcha=` lines.

Acceptance (from worktree root, backend dir):
- `env WEBHOOK_URL=https://example/rest/1/x python3 -B site78-releases/2026-07-29/backend-arwox-lead-form/test_lead.py` → `PASS: все проверки прошли`
- `python3 -B forms-failover/server-test.py` → PASS lines unchanged
- `git diff --check` exit 0

Threats (prod §3): log line could leak data → only exception class, `reason` and HTTP code. Rollback (prod §5): revert commit, `pm2 reload forms-backup`.
Rules: SOLID, DRY, KISS, YAGNI; minimal diff; разведка — repowise; индекс: repowise/CBM проверен, нет — `tools/bin/code-memory-enable`. No secrets. Do not commit; do not push.
