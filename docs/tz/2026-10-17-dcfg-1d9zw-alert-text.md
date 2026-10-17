# TZ dcfg-1d9zw (v2 of dcfg-9wggj) — cloud_read_outage text states only observed facts

Atom: dcfg-1d9zw (discovered-from dcfg-9wggj, merged PR #55 f881246). Executor: sdk-agent code.
Recon: repowise / codebase-memory first, then grep; index: repowise/CBM checked; if missing — `tools/bin/code-memory-enable`.

## U1 — message text

Files (only these):
FILE: forms-failover/forms-gw-guard.sh
FILE: forms-failover/forms-gw-guard-test.sh

### Defect (v1 TZ error)
`notify` text for `cloud_read_outage` (forms-gw-guard.sh, case table near :74) hard-codes `incidents/2136` and `Формы работают`. The guard checks neither at that point, so the message can be false (other outage, or forms down at the same time).

### Required
1. `cloud_read_outage` text, exactly (`$text` = consecutive failure count):
   `⚠️ Журнал Yandex Cloud Logging недоступен: Яндекс отвечает Unavailable $text раз подряд. Счётчик заявок без капчи видит только резерв. Повтор — только после восстановления. Статус Яндекса: status.yandex.cloud`
2. The call site in `check_captcha_unverified` passes the counter: `notify cloud_read_outage "$fails"` (now `""`).
3. `cloud_read_recovered` text unchanged. Nothing else changes.

### Tests (forms-gw-guard-test.sh, test-first)
- case66: keep the existing assertions (count of `Yandex Cloud Logging недоступен` = 1, no `не читается`) and add: `sent_has 'Unavailable 3 раз подряд'`, and `! grep -q '2136' "$tmp/sent.log"`, and `! grep -q 'Формы работают' "$tmp/sent.log"`.
- No other test changes.

## Acceptance (I run once after the edit)
- `grep -c '2136\|Формы работают' forms-failover/forms-gw-guard.sh` = 0.
- `bash -n forms-failover/forms-gw-guard.sh` rc 0.
- `bash forms-failover/forms-gw-guard-test.sh` → `PASS 68/68`.
- `git diff --check` rc 0; diff only in the two listed files.

## Threats / rollback
- Text only; no logic, state or Telegram path change. No secrets, no PII.
- Rollback: `git revert` of the merge commit.

## Forbidden
No secrets read or printed; no edits outside the two listed files; no live yc/Telegram calls; no `rm`, no pm2 commands.
