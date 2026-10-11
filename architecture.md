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
- Инцидент 11.10: по письму Яндекса недоступна зона ru-central1-b; шлюз не отвечает с 01:50Z 11.10 (TCP timeout, `dcfg-jcwf2`), заявки принимает резерв. Связь отказа шлюза с этой зоной — UNVERIFIED: зона шлюза не проверялась.

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
- Капчи на резерве нет (`SMARTCAPTCHA` в конфиге резерва — 0 упоминаний).

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
