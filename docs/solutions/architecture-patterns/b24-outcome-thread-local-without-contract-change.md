---
title: "Резерв форм: видимость доставки в Bitrix24 без смены контракта handler"
date: 2026-10-09
category: architecture-patterns
module: forms-failover
problem_type: architecture_pattern
component: infrastructure
severity: medium
applies_when:
  - "нужно знать исход внутри index.py (лид или очередь), а ответ handler одинаков (302 #sent)"
  - "один handler обслуживает и Yandex Cloud Function, и резерв server.py"
  - "forms-ctl.sh ведёт состояние/таймер для нескольких FQDN"
related_components: [index.py, server.py, forms-ctl.sh]
tags: [bitrix24, threading-local, failover, forms-ctl, observability, fqdn-state]
---

# Резерв форм: видимость доставки в Bitrix24 без смены контракта handler

## Context
`index.py` отвечает 302 `#sent` и при созданном лиде, и при постановке заявки в очередь резерва. `server.py` эти случаи не различал, лента теста не могла показать, дошла ли заявка до Bitrix24. Исправлено в PR #18 (смёржен 09.10).

## Guidance
1. Исход — в `threading.local` модуля handler, не в ответе:
   - `index.py:27` `B24_OUTCOME = threading.local()`;
   - `:256` успех `crm.lead.add` → `lead:<id>`; `:301` очередь → `queue:<file>`;
   - `server.py:55` сбрасывает перед вызовом handler, `:78-79` читает после и пишет `b24=` в строку `forms-backup lead`;
   - досылка из очереди: `index.py:333` `forms-backup spool-sent spool=<f> b24=lead:<id>`.
2. Состояние и PID таймера автовозврата в `forms-ctl.sh` — свои на каждый FQDN: `state/demo-$FQDN.json`, `state/demo-$FQDN.timer.pid`.

## Why This Matters
- Новый ключ в ответе handler меняет контракт Yandex Cloud Function (302, `#sent`, `?err=`) — запрещено без сверки фронта.
- Склейка отдельных лог-строк по порядку ломается: `ThreadingHTTPServer` обрабатывает соединения параллельно, строки разных заявок перемешиваются. Thread-local читается в том же потоке, что вызвал handler.
- Общий PID-файл: `restore` теста `forms-test` убивал таймер автовозврата боевого `forms.arwox.ru` (найдено ревью, кейс 16 `forms-ctl-test.sh`).

## When to Apply
- Нужна телеметрия исхода из общего handler, а ответ трогать нельзя.
- Скрипт с фоновыми таймерами работает с несколькими средами.

## Examples
Лента `forms-ctl.sh test`: `🎯 Заявка №1 … → Bitrix24 лид #<id>` или `→ очередь резерва, дошлётся сам`, затем `📬 из очереди: Bitrix24 лид #N` — только для спулов этого теста.

Проверка: `forms-ctl-test.sh` PASS 21/21, `server-test.py` PASS 15/15; живой тест forms-test 09.10 — 5/5, `→ Bitrix24 лид #3200`.

## Related
- `docs/solutions/integration-issues/beget-dns-api-method-failed-zone-only-subdomain.md`
