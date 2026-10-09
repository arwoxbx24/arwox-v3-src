# ТЗ dcfg-hqjyd.1 — резерв: исход Bitrix24 по каждой заявке в журнале forms-backup

Исполнитель пишет код сам, code-channel не вызывает. Разведка — repowise (индекс: repowise/CBM проверен, нет — `tools/bin/code-memory-enable`); читать только указанные строки. Секреты, .env, `secrets/` не читать. yc, pm2, сеть, DNS, git commit/push не вызывать. ПДн (имя, телефон, e-mail) — не в лог. KISS/YAGNI, минимальный дифф; правки только в 4 файлах ниже. План: `docs/plans/2026-10-09-1805-feat-forms-ctl-plan.md` U1, KTD1, R5, R6, R8.

## Зачем
Ответ `#sent` одинаков при создании лида и при постановке в очередь (`index.py:440-452`). Журнал резерва должен показывать, что именно случилось.

## U1. `site78-releases/2026-07-29/backend-arwox-lead-form/index.py`
- Модульный `B24_OUTCOME = threading.local()` (импорт рядом с `from threading import Lock`, `:22`).
- `_lead_status` (`:197`): перед `return "success"` (`:254`) — `B24_OUTCOME.value = f"lead:{res['result']}"`.
- `_enqueue_lead` (`:288`): при успешной записи файла очереди — `B24_OUTCOME.value = f"queue:{<имя файла очереди>}"`.
- `drain_spool` (`:307`): после успешной отправки (`:327`) — `print(f"forms-backup spool-sent spool={inflight.name} b24={getattr(B24_OUTCOME, 'value', '-')}", flush=True)` в stdout. Имя файла в `spool=` должно совпадать с тем, что записано в `queue:` (если имя меняется при переносе в inflight, взять общее базовое имя).
- Контракт ответа handler (302, хвосты) не менять.

## U2. `forms-failover/server.py`
- Перед `index.handler(event, None)` (`:55`): сбросить `index.B24_OUTCOME.value = "-"`, если атрибут есть (`getattr`, без исключения).
- В строке `forms-backup lead …` (`:75`) добавить в конец ` b24={…}`; чтение — `getattr(getattr(index, "B24_OUTCOME", None), "value", "-")`, никогда не бросает.

## U3. Тесты (дополнить существующие, новых файлов нет)
- `forms-failover/server-test.py`: заглушка `index.py` (`:30`) получает `B24_OUTCOME` и задаёт `value` в одном пути; проверка строки `:57` — с `b24=`; отказ согласия → `b24=-`; два запроса подряд — значение не протекает; строка лога без имени/телефона из POST.
- `site78-releases/2026-07-29/backend-arwox-lead-form/test_lead.py`: `call_b24`-заглушка с result 123 → `B24_OUTCOME.value == "lead:123"`; transient + очередь → `queue:<файл>`; drain одного элемента с успехом → stdout содержит `spool-sent spool=<файл> b24=lead:<id>`.

## Угрозы и откат (prod §3, §5)
- Ошибка чтения после handler уронила бы 302 → чтение только через `getattr` с дефолтом.
- В лог — только id лида и имя файла очереди (случайный токен).
- Откат: `git revert`, `pm2 reload forms-backup` (делает оркестратор).

## Критерии
1. `python3 forms-failover/server-test.py` → `PASS`, rc 0.
2. `WEBHOOK_URL=x python3 site78-releases/2026-07-29/backend-arwox-lead-form/test_lead.py` → `PASS`, rc 0.
3. `python3 -m py_compile` для `index.py` и `server.py` → rc 0.
4. `git diff --stat` — только 4 файла выше и этот ТЗ.

## Паспорт источников
- CBM `get_code_snippet handler` (этот ход): `index.py:395-454`, ветка transient → `_enqueue_lead` → `#sent`.
- `grep -n` этого хода: `index.py:22,197,254,288,307,324,327,440,445`; `server.py:6,55,75,82`; `server-test.py:30,57,60,101,202`.
- Python `threading.local`: https://docs.python.org/3/library/threading.html#thread-local-data — «Thread-local data is data whose values are thread specific.»
