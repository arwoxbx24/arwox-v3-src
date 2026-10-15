# Architecture — arwox-v3-src

Только проверенные факты (команда/файл, 09.10.2026). Не проверено — помечено UNVERIFIED.

## Стек
- Фронт: React + TypeScript + Vite, пакеты pnpm (`package.json`, `vite.config.ts`). Сборка `pnpm build`, проверка типов `pnpm typecheck`.
- Обработчик форм: Python, `site78-releases/2026-07-29/backend-arwox-lead-form/index.py`; спека шлюза `gateway-spec.yaml` рядом.
- Резерв: `forms-failover/` — bash + Python, процессы pm2 из `/root/workspaces/tools/ecosystem.config.js`.

## Поток заявки (норма)
Браузер → `forms.arwox.ru` (DNS у Beget: CNAME `d5dn462s09a9dpofvl2d.6brbn2wz.apigw.yandexcloud.net.`, dig 09.10) → Yandex API Gateway `arwox-forms-gw` → Cloud Function (`index.py`) → Bitrix24 `crm.lead.add` + согласие → 302 на `https://arwox.ru/?ok=1#sent`.

## Поток заявки (резерв)
DNS `forms.arwox.ru` → A `45.139.76.176` (наш сервер) → NPM proxy host 40 → pm2 `forms-backup` (`server.py`, 172.20.0.1:20140) → тот же `index.py` → Bitrix24. При временном отказе Bitrix24 — очередь `/var/lib/forms-backup/spool`, досылка раз в 60 с.

## Yandex Cloud: квоты и зоны (11.10.2026)
- На Яндексе у нас только serverless: API Gateway `arwox-forms-gw` и одна Cloud Function, ВМ и дисков нет. Ручное управление квотами на ВМ и диски (письмо Яндекса 11.10) схему заявок не задевает: она не создаёт новых ресурсов.
- Посмотреть квоты: `yc quota-manager quota-limit list` / `get` (https://yandex.cloud/ru/docs/cli/release-notes); точные флаги — `--help` перед вызовом.
- Увеличить квоту: `yc quota-manager quota-request create` / `get` или REST `QuotaRequest` Create (https://yandex.cloud/ru/docs/quota-manager/quickstart), либо техподдержка. Квоту можно изменить по запросу, лимит — нельзя (https://yandex.cloud/ru/docs/compute/concepts/limits).
- History, incident 11.10–15.10: Yandex letter reported zone ru-central1-b down; the gateway did not answer from 01:50Z 11.10 (TCP timeout, `dcfg-jcwf2`, `dcfg-k2yg3`), the reserve took leads. Link of the gateway failure to that zone — UNVERIFIED.

## State 2026-10-15
- Owner rule: Yandex (API Gateway → Cloud Function) is the default route; the reserve takes leads only while Yandex is broken. `forms-gw-guard` switches DNS to the reserve on outage and back to Yandex on recovery by itself.
- 15.10 19:13Z: Yandex recovered, guard failed back. `forms-ctl.sh status --prod` → `dns=normal yandex=HTTP 302 backup=HTTP 301`; guard log `class=ok`, `balance <number> active=true`; `yc serverless api-gateway list` answers, `arwox-forms-gw` ACTIVE. Closed: `dcfg-k2yg3`, `dcfg-1u6vj`.
- SmartCaptcha fail-closed gate is on both routes (epic `dcfg-fm4p3`, PRs #33–#37); Cloud Function `$latest` rebuilt 14.10 from merged `index.py` (`fn-deploy.sh`, PR #38), rollback version `d4egc5urnmocbb7t720n`.
- Open: prod live test `dcfg-1ci20.33` (owner phrase only), `forms-ctl.sh test` rc 1 when Yandex is down `dcfg-0p5lb`, review of `[captcha-unverified]` leads `dcfg-5e55i`, captcha hardening backlog `dcfg-qj6w1` (deferred).

## Части резерва (`forms-failover/`)
| Файл | Роль |
|---|---|
| `forms-gw-guard.sh` | сторож (pm2 cron): проверка шлюза, баланс Яндекса, запуск переключений |
| `dns-switch.sh` | Beget DNS: `status`, `apply normal` (CNAME Яндекса) / `apply outage` (A на резерв) |
| `forms-fallback-switch.sh` | переключение формы на запасную страницу (пересечение с `dns-switch.sh` — UNVERIFIED) |
| `server.py` | HTTP-обёртка `index.py` на резерве + очередь |
| `forms-ctl.sh` | живой тест резерва (`test`/`restore`/`status`): по умолчанию `forms-test.arwox.ru`; `--prod` — боевой `forms.arwox.ru`, только по слову владельца |
| `*-test.sh`, `server-test.py` | тесты без сети |

## Бэкенд (`site78-releases/2026-07-29/backend-arwox-lead-form/`)
- Вход: нативный POST (urlencoded) формы лендинга, точка `handler(event, context)` (`index.py:340`).
- Ответ — 302 на `LANDING` с хвостом (`index.py:163-165`): успех `#sent` (попап `#psent`); отказы `?err=consent#contact` (`:349`), `?err=empty#contact` (`:354`), `?err=contact#lead-form` (`:360`), `?err=server#contact` (`:450`, `:452`). Страница SmartCaptcha — 200 (`:99`).
- Bitrix24 через входящий вебхук `WEBHOOK_URL`: `crm.lead.add` (`:198`), `crm.activity.add` (`:229`), `userconsent.consent.add` (`:246`).
- Капча: `https://smartcaptcha.yandexcloud.net/validate` (`:111`).
- Согласие ПДн: `consent.py` — квитанция с HMAC, реестр смарт-процесса 1094, без сетевых вызовов (152-ФЗ).
- Env: `WEBHOOK_URL`, `LANDING_URL`, `CONSENT_*`, `SMARTCAPTCHA_SITEKEY`, `SMARTCAPTCHA_SECRET`, `SELF_URL`; значения — в `secrets/`.
- Тест: `test_lead.py`; зависимости: `requirements.txt`; спека шлюза: `gateway-spec.yaml`.

## DevOps
| pm2 | Скрипт | Режим | Источник |
|---|---|---|---|
| `forms-backup` | `forms-failover/server.py` | постоянно (autorestart) | `ecosystem.config.js:204-218` |
| `forms-gw-guard` | `forms-failover/forms-gw-guard.sh` | cron `* * * * *` | `ecosystem.config.js:221-238` |
| `forms-gw-guard-test` | `forms-failover/forms-gw-guard.sh` | cron `* * * * *` | `ecosystem.config.js:241-258` |
- Логи: `/root/.pm2/logs/forms-backup-{out,error}.log`, `forms-gw-guard-{out,error}.log`, `forms-gw-guard-test-{out,error}.log`.
- Среды: тест `forms-test.arwox.ru` (`forms-ctl.sh`), бой `forms.arwox.ru` (`forms-ctl.sh --prod`).
- Откат на норму: `dns-switch.sh apply normal` (CNAME Яндекса).
- Выкладка Cloud Function: скрипта в репо нет (grep `function version create` → 0, 09.10) — способ UNVERIFIED.

## Известные дефекты (09.10)
- Предпроверка `dns-switch.sh:73` отклоняет резерв с принудительным HTTPS (301) — исправление в атоме `dcfg-1ci20.14`.
- Historical defect (2026-10-09): the reserve had no SmartCaptcha keys; recovery and verification are specified in U1 below.

## U1 — Reserve SmartCaptcha recovery

- Owner outcome: the active reserve rejects missing, invalid, and unverified SmartCaptcha tokens before any Bitrix24 lead creation; valid submissions keep the consent, redirect, and reserve-queue contracts.
- Architecture: both form hosts reach `forms-backup`, whose `server.py` imports the shared `index.py`; the protected reserve environment supplies the existing Yandex Cloud SmartCaptcha key pair. No DNS change is part of U1.
- Incident evidence: on 2026-10-14 the reserve process lacked both keys; after their restoration a missing-token POST returned the widget, but a transient validator failure allowed an invalid-token POST and created marked test lead 3218. The shared `_captcha_ok` exception path was fail-open.
- Ordered implementation: restore the official key pair to the reserve environment; make the shared validator exception path fail closed in `index.py`; run syntax and existing handler tests, isolated real-handler checks for missing token, invalid token, and validator outage; then verify a valid-token submission and live no-token gate before local delivery.
- Local acceptance before `ship-post --submit`: the existing `test_lead.py` and `server-test.py` checks pass, and `git diff --check` is clean. The seven labeled goal checks remain required after merge, live checkout sync, and `forms-backup` reload; a local code pass does not prove live activation.
- Rollback: revert only U1's source change through the normal Git route; the protected-config operator removes only the two added CAPTCHA key lines and reloads `forms-backup` if recovery must be undone. Preserve the lead queue and DNS state.

## Стратегия проверок (задаётся до кода, не по ходу)
Три уровня, каждый пишется один раз и гоняется один раз на атом:
1. **Синтаксис** — `bash -n` для `.sh`, `python3 -m py_compile` для `.py`. Секунды, без сети.
2. **Логика без сети** — `forms-gw-guard-test.sh`, `forms-ctl-test.sh`, `server-test.py`. Правило изоляции: каждый кейс сам задаёт все переменные окружения и свой каталог; кейс не меняет глобальные переменные для следующих (`export` внутри кейса — только в subshell). Нарушение 09.10: `export DNS_SWITCH=<заглушка>` в кейсах 24–27 сломал кейсы 28–30.
3. **Среда, только чтение** — до живого теста одна проверка фактов внешних систем: Beget `getData` для каждого имени, которое скрипт будет менять (09.10: `forms.arwox.ru` → `METHOD_FAILED`); ответ резерва по HTTP и HTTPS через `--resolve` (09.10: 301 вместо 302 после сертификата); `dig` текущей записи. Заглушки эти факты не ловят.
Живой тест (`forms-ctl.sh test`) — один раз, только после зелёных 1–3. Упал — причина в bd, без повтора по кругу.

## Источники правил (не дублировать)
- Правила агентов: `/root/CLAUDE.md` → `/root/workspaces/projects/CLAUDE.md` → `.claude/rules/`; проектные (Claude и Codex) — `AGENTS.md`.
- Консольные утилиты: `/root/workspaces/tools/TOOLS-REGISTRY.md` — новую утилиту добавлять туда до использования.
- Дизайн: `docs/v3-design-spec.md`, `docs/technical_prompt_colors_gradients.md`.
- Задачи и память: bd.
