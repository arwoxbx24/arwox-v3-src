---
title: Восстановление приёма заявок forms.arwox.ru и сторож API Gateway
type: fix
status: requirements-only
date: 2026-09-22
artifact_contract: ce-unified-plan/v1
artifact_readiness: requirements-only
product_contract_source: ce-brainstorm
owner_decisions: 2026-09-22 (пакет из 4 вопросов)
---

# Goal Capsule

**Цель.** Формы сайта arwox.ru (квиз/попап/футер) снова доставляют лиды в Bitrix24 через `https://forms.arwox.ru/`, и остановка API Gateway реапером YC больше не остаётся незамеченной: сторож поднимает gateway сам и шлёт алерт; падение баланса YC ниже 10 ₽ — алерт в бот-нотификатор.

**Диагноз (стадия 2, ce-debug, 22.09).**
- `yc serverless api-gateway get d5dn462s09a9dpofvl2d` → `status: STOPPED`; list-operations: `operation_stop` 2026-08-03T14:12 `created_by: yc.iam.reaper`.
- Тот же реапер: site-monitor-gw stop 01.06 и 03.08 (владелец поднимал руками 01.07); функция arwox-lead-form — reset provisioned 03.08/18.08/01.09.
- Биллинг `dn2s45ih4vaq9nodg0sf` сейчас `active: true`, баланс 17.28 ₽ → suspended повторится при ближайшем списании.
- Функции после реактивации биллинга возобновляются сами (`ACTIVE`, отвечает 302), API Gateway — нет.
- `curl -sk https://forms.arwox.ru/` → `403 API Gateway d5dn462s09a9dpofvl2d is stopped and cannot be used`; TLS отдаёт `CN=*.sax5b7yq.apigw.yandexcloud.net` (кастомный домен не обслуживается у STOPPED). Сертификат `fpqtqp780aff9ihjp9qr` forms.arwox.ru `ISSUED`, выдан 21.09, до 20.12 — SSL исправен, симптом вторичен.
- Спека gateway: `site78-releases/2026-07-29/backend-arwox-lead-form/gateway-spec.yaml` (`/` и `/{proxy+}` → function `d4eb92qbfgt3ac0udlmm`, SA `ajesk8iqatt8pn0ahtuk`). Формы: 3 вхождения `https://forms.arwox.ru/` в `block9116-content.html`.

**Не в цели (решение владельца).** freelancer-gw, site-monitor-gw (STOPPED) — находка в bd, ноль действий. Пополнение баланса — контрольная точка владельца. Уход от gateway на прямой URL функции — отклонён.

# Product Contract

## Требования

- **R1. Восстановление.** `arwox-forms-gw` переведён в `ACTIVE`; `https://forms.arwox.ru/` отвечает не-403 с сертификатом `CN=forms.arwox.ru`; тестовый лид с пометкой TEST, отправленный через forms.arwox.ru, появляется в CRM (`crm.lead.get`) и удаляется после проверки.
- **R2. Сторож gateway.** Процесс в `/root/workspaces/tools/ecosystem.config.js` (cron_restart, one-shot, по образцу `context-heartbeat`), скрипт в `/root/workspaces/tools/scripts/schedulers/`: раз в 15 мин проверяет `https://forms.arwox.ru/` (HTTP + строка «is stopped»); при STOPPED — `yc serverless api-gateway start d5dn462s09a9dpofvl2d`, повторная проверка, Telegram-алерт «поднят / не поднялся». Токен и chat — `env_file` `/root/workspaces/secrets/services/pm2-notify.env` (`TG_BOT_TOKEN`, `TG_CHAT_ID`; значения агент не читает). Секретов в логах нет.
- **R3. Алерт баланса.** Тот же скрипт (один процесс, одно расписание): `GET billing.api.cloud.yandex.net/billing/v1/billingAccounts` (IAM-токен через `yc iam create-token` в env, не в argv); `balance < 10` → сообщение в бот-нотификатор `@StatusTrackers_bot` с суммой; антидребезг — не чаще одного алерта в 6 ч (файл-состояние в `data/`). Проверка, что `TG_BOT_TOKEN` из `pm2-notify.env` принадлежит `@StatusTrackers_bot` (`getMe` → username), иначе — контрольная точка владельца.
- **R4. Идемпотентность и безопасность.** Скрипт безопасен к повторному запуску, `set -euo pipefail`, таймауты curl ≤10 с, exit 0 при «всё ок». Не трогает другие gateway/функции. `yc` вызывается с профилем `default` без вывода конфигурации.
- **R5. Проверка.** Один runnable-тест скрипта (bash, подмена `yc`/`curl` через PATH-стабы): три сценария — ACTIVE (ничего не делает), STOPPED→start ок (алерт «поднят»), баланс 5 ₽ (алерт баланса, второй запуск — молчит).

## Критерии приёмки (пункт → команда → цифра)

1. `yc serverless api-gateway get d5dn462s09a9dpofvl2d --format json | grep status` → `ACTIVE`.
2. `curl -s -o /dev/null -w "%{http_code} %{ssl_verify_result}" https://forms.arwox.ru/` → код ≠ 403, `ssl_verify_result` = 0; `openssl s_client` subject `CN=forms.arwox.ru`.
3. Тест-лид: `POST https://forms.arwox.ru/` (тело по контракту index.py) → 200; `b24 crm.lead.get` по ID → TITLE содержит TEST; `crm.lead.delete` → true.
4. `pm2 describe forms-gw-guard` → `cron_restart` задан, последний запуск exit 0; `pm2 startOrReload ecosystem.config.js --only forms-gw-guard` + `pm2 save`.
5. Тест скрипта: `bash <scheduler>-test.sh` → `PASS 3/3`.
6. Ручной прогон с подменой ответа «is stopped» → в лог «start issued», алерт ушёл (ответ Telegram `ok:true`, текст без токена).
7. `gitleaks detect` по diff = 0 находок.

## Контрольные точки владельца
- Пополнить баланс YC (сейчас 17 ₽) — иначе реапер повторит остановку; сторож поднимет gateway только после реактивации биллинга.
- Если `TG_BOT_TOKEN` в `pm2-notify.env` ≠ `@StatusTrackers_bot` — положить токен нужного бота в `secrets/services/` (имя файла назовёт агент).

## Ready for Planning Check
- Цель одной фразой — есть. Границы — есть. Критерии измеримы (7). Решения владельца зафиксированы. Реализация (файлы, инструменты) названа только там, где это инфраструктурная цель.
