# TZ dcfg-gured U1 — резерв заявки, когда Bitrix24 её не принял

## Goal

Если лид в Bitrix24 не создан (ответ с ошибкой содержимого, либо сеть/5xx после ретраев) и заявка не поставлена в локальную очередь `LEAD_SPOOL_DIR`, функция `arwox-lead-form` сохраняет полную заявку одним JSON-объектом в бакет `arwox-forms-reserve-b1g7fof71b9b632o3a4r` по ключу `reserve/<request_id>.json`, пишет этап `reserved` и отвечает посетителю успехом (R5, R8 плана). Если запись в резерв не удалась — этап `reserve_error` и прежний ответ `?err=server#contact` (AE4).

U1 даёт источник алерта: этапы `reserved` / `reserve_error` с `request_id` читает сторож (R7, вариант B решения R029; сам сторож — отдельная часть U3). Повторную отправку (U2) U1 не делает, но фиксирует формат объекта, который она будет читать. Алерт и повтор в U1 не реализуются.

## Facts

- `bd show dcfg-gured` DESCRIPTION, ADR-053-CR1 п.3: «Сбой Bitrix24 → полная заявка в бакет Object Storage RU (dead-letter, шифрование, срок 30 дней) + алерт; повтор — штатной командой».
- `bd show dcfg-gured` COMMENTS: бакет `arwox-forms-reserve-b1g7fof71b9b632o3a4r` создан, max_size 1 GB, versioning выключен, анонимные флаги false; SSE aws:kms ключ `abjadmbvvfbm4os08b5a`; expiration 30 дней; runtime read/write НЕ проверен. Решение R7 = вариант B: функция не получает токен Telegram, алерт шлёт сторож по Cloud Logging. Контекст: `context.token` содержит `access_token` (цитата из атома, не проверена мной).
- `site78-releases/2026-07-29/backend-arwox-lead-form/index.py:19` — `import urllib.request` уже есть; `requirements.txt:1` — «stdlib only», новых зависимостей нет.
- `index.py:28-40` — env-конфиг (`WEBHOOK_URL`, `LANDING_URL`, `CAPTCHA_*`, `SELF_URL`); переменной резерва нет.
- `index.py:141-144` — `_journal(rid, t0_ns, stage, **kw)`: одна JSON-строка; допустимые ключи kw: form, has_name, has_phone, has_email, has_consent, lead_id, error, message, rejection.
- `index.py:213-214` — `_SPOOL_LIMIT = 500`, `_SPOOL_LOCK`; `index.py:316-327` — `_enqueue_lead` (очередь при transient-ошибке); `index.py:330-334` — `_move_failed`.
- `index.py:217-226` — `_lead_status`: при не-success пишет `b24_error` (`error=crm_lead_add_failed`) и возвращает `status` (`transient:*` или `content:lead`).
- `index.py:285-286` — `create_lead` делегирует `_lead_status`.
- `index.py:371` — `def handler(event, context):`; `context` сейчас не используется.
- `index.py:476-485` — `lead_context` содержит `rid` и `t0` (строка 484); `t0` — монотонные наносекунды, между запусками не имеют смысла.
- `index.py:486-498` — после `create_lead`: transient + спул → `?ok=1#sent` (487-496); любой другой не-success → `?err=server#contact` (497-498). Здесь заявка теряется при отказе CRM по содержанию (`content:*`): R5 не выполнен.
- `test_journal.py:39-41` — `broken_call` возвращает `{}` для `crm.lead.add` → статус `content:empty`; `test_journal.py:63` ожидает `?err=server#contact` и отсутствие `b24_lead_ok`.
- `test_lead.py:88-103` — тест спула (transient → `?ok=1#sent`, `drain_spool` → `spool-sent`); `test_lead.py:230` — при отсутствии ключей капчи ожидается `?err=server` до ветки лида.
- `consent.py:106-114` — `extract_request_context(event)` возвращает ip/user_agent/xff_chain.
- `docs/plans/2026-10-08-1410-feat-forms-request-journal-plan.md` (worktree `.worktrees/claude/dcfg-gured`) — R1–R8, AE1–AE4; секции `### U1…U6` нет (grep пуст), HOW в плане не записан.
- Спека: `/root/workspaces/projects/specs/053-forms-gateway-recovery/spec.md:109` (обработчик заявки), `:127` (вебхук и ключ согласия не меняются). Путь `arwox-v3-src/specs` из атома не существует.
- Журнал-порт уже в main: merge `61dba56` (PR #49, `b6606d4`); дерево `arwox-v3-src` на `main` чистое.

## Change

Файлы (exact):

1. `site78-releases/2026-07-29/backend-arwox-lead-form/index.py` — не более 100 изменённых строк:
   - a. После `index.py:40`: `RESERVE_BUCKET = os.environ.get("RESERVE_BUCKET", "")`. Пусто = резерв выключен (тесты без сети).
   - b. Новая функция `_reserve(fields, ctx)` после `_enqueue_lead` (после строки 327):
     - ключ `reserve/{ctx["rid"]}.json`; тело (UTF-8, `ensure_ascii=False`): `{"request_id", "created", "fields", "ctx"}`, где `ctx` — `lead_context` без `rid` и `t0`. Формат совпадает с элементом спула (`fields`/`ctx`) — повтор (U2) читает его же.
     - токен: `(getattr(context, "token", None) or {}).get("access_token", "")` — передаётся аргументом из `handler`.
     - нет `RESERVE_BUCKET` → `_journal(..., "reserve_error", error="reserve_disabled", message="Request was not saved to reserve.")`, `return False`. Нет токена → `error="no_iam_token"`, `return False`.
     - запрос: `urllib.request.Request(f"https://storage.yandexcloud.net/{RESERVE_BUCKET}/{key}", data=body, method="PUT", headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"})`; `urllib.request.urlopen(req, timeout=5)`; один вызов, без ретраев. Успех (нет исключения) → `_journal(..., "reserved")`, `return True`.
     - исключение → `_journal(..., "reserve_error", error=type(exc).__name__, message="Request was not saved to reserve.")`, `return False`. Текст исключения, URL, заголовки и тело НЕ печатаются.
   - c. В `handler`, вместо строк 486-498 (спул-ветка сохраняется дословно):
     ```
     status = create_lead(fields, lead_context)
     if status == "success": return _redirect(frag)
     if status.startswith("transient") and <спул ok>: return _redirect(frag)
     if _reserve(fields, lead_context): return _redirect(frag)
     return _redirect("?err=server#contact")
     ```
     `frag` — существующее выражение `?ok=1#psent` / `?ok=1#sent` по `form_content`. Вынести его в одну переменную (DRY).
   - d. Не менять: журнальные этапы, капчу, согласие, `call_b24`, `_lead_status`, `drain_spool`, тексты ответов.
2. `site78-releases/2026-07-29/backend-arwox-lead-form/test_reserve.py` — новый файл, stdlib, не более 90 строк. Стабит `index.call_b24` и `index.urllib.request.urlopen`; любой вызов `urlopen` вне стаба → `AssertionError`. Сценарии:
   - R-a: `RESERVE_BUCKET=bkt-test`, `call_b24` для `crm.lead.add` → `{}`, капча `ok`, `context.token={"access_token":"TEST-IAM-XYZ"}`. Ожидается 302 `?ok=1#sent`; ровно один PUT; URL `https://storage.yandexcloud.net/bkt-test/reserve/<rid>.json`; `Authorization == "Bearer TEST-IAM-XYZ"`; тело JSON содержит `request_id, created, fields, ctx`; в `ctx` нет `t0`; в stdout есть `"stage": "reserved"`; в stdout нет `TEST-IAM-XYZ`, имени, телефона, email, текста комментария.
   - R-b: PUT отвечает HTTP 500 → 302 `?err=server#contact`; этап `reserve_error`, `error == "HTTPError"`; токен и URL не в stdout.
   - R-c: `context=None` → urlopen не вызван; `reserve_error` с `error=no_iam_token`; `?err=server#contact`.
   - R-d: `RESERVE_BUCKET` пуст → urlopen не вызван; `error=reserve_disabled`.
   - R-e: `LEAD_SPOOL_DIR` задан, lead `transient` → `?ok=1#sent`, ноль PUT (заявка не пишется дважды).
   - Вывод: `PASS: reserve`.
3. Без изменений: `test_journal.py`, `test_lead.py`, `consent.py`, `requirements.txt`, `gateway-spec.yaml`, документы.

Вне U1 (отдельные части): алерт-сторож (U3, читает `reserved`/`reserve_error` из Cloud Logging); повтор `resend` (U2, проверка «лид уже есть» по R6); резерв для `failed/` в `drain_spool`; `RESERVE_BUCKET` в конфиге деплоя; выкладка в боевую функцию (только после ноты «принято к выкладке»); CR-документ и ship-post (AC4); 30-дневная лог-группа.

## Acceptance

Все команды — из корня собственной worktree (не из боевого контура, без записи в боевую Bitrix24):

1. `env WEBHOOK_URL=https://example/rest/1/x PYTHONDONTWRITEBYTECODE=1 python3 site78-releases/2026-07-29/backend-arwox-lead-form/test_journal.py` → rc 0, последняя строка `OK: журнал без ПДн прошёл`.
2. `env WEBHOOK_URL=https://example/rest/1/x python3 -B site78-releases/2026-07-29/backend-arwox-lead-form/test_lead.py` → `PASS: все проверки прошли`.
3. `env WEBHOOK_URL=https://example/rest/1/x python3 -B site78-releases/2026-07-29/backend-arwox-lead-form/test_reserve.py` → rc 0, `PASS: reserve` (сценарии R-a…R-e).
4. `python3 -B forms-failover/server-test.py` → 0 FAIL (регрессия, файл не меняется).
5. `git diff --check` → rc 0.
6. `git diff --numstat origin/main -- site78-releases/2026-07-29/backend-arwox-lead-form/index.py` → added + deleted ≤ 100.
7. `git diff origin/main -- site78-releases/2026-07-29/backend-arwox-lead-form/index.py | grep '^+' | grep -c 'print('` → 0 (новые print не добавлены; вывод идёт через `_journal`).
8. `git diff origin/main -- site78-releases/2026-07-29/backend-arwox-lead-form/index.py | grep '^+' | grep -c -i 'exc)\|str(e\|headers\|body=' ` → 0 (исключения и тело не логируются). Проверка ручная по диффу.
9. `git status --short` показывает только `index.py` и `test_reserve.py`; `git log -1` без коммита (правило: не коммитить).

Облачная приёмка (AE2, AE4) — только на тестовой функции `arwox-lead-form-gured-test` (`d4efartcso6d0eoihdq3`) с fake CRM-адресом, после PASS тестов 1–4. Проверка: `yc serverless function invoke` с недоступным CRM → объект `reserve/<rid>.json` в бакете, этап `reserved` в журнале, ответ 302 `?ok=1#sent`. Конкретная команда чтения объектов исполнитель выбирает по `yc` help и фиксирует в ноте; отсутствие ПДн в журнале проверяется `grep -c` по телефону/email/имени тестовой заявки = 0.

## Threats

- ПДн в логах: этапы пишут только stage, error-класс и has_* признаки; тест R-a проверяет отсутствие имени/телефона/email/комментария в stdout.
- Утечка IAM-токена: токен берётся из `context.token`, не пишется в журнал, объект, сообщение исключения и файлы; тест R-a/R-b проверяет stdout; в тестах только фейковый токен.
- Утечка через исключения: печатается только `type(exc).__name__`; `HTTPError.__str__` содержит URL — не выводим.
- Публичный доступ к резерву: бакет с анонимными флагами false; объект шифруется SSE-KMS (атом, readback); доступ — только SA функции (ключ KMS ограничен SA — атом).
- Двойная запись (спул + резерв): спул-ветка возвращает редирект раньше; тест R-e.
- Дубль лида при повторе: U1 не повторяет отправку; защита R6 — в U2.
- Bearer IAM на S3-эндпоинте: атом утверждает поддержку, я не проверял; если эндпоинт отклонит токен, PUT даст HTTPError → `reserve_error`, U1 не закрывается (см. open_points).
- Заявка потеряна, если и CRM, и бакет недоступны: остаточный риск, виден по `reserve_error` (AE4).
- Таймаут 5 с на PUT добавляет задержку ответу посетителю; общий бюджет функции не измерен.
- Пустой `RESERVE_BUCKET` в проде молча отключает резерв: видно как `reserve_error reserve_disabled` — требуется проверка env при выкладке.

## Rollback

- До коммита: `git checkout -- site78-releases/2026-07-29/backend-arwox-lead-form/index.py` и удалить `test_reserve.py`.
- После коммита (собственная ветка): `git revert <sha-U1>`; push не делать без разрешения.
- Тестовая функция: вернуть предыдущую версию тестовой функции (id записать до выкладки); функцию не удалять.
- Боевая функция: U1 не выкладывается. При будущей выкладке — команда отката на записанный id текущей версии (на 16.10 атом указывает `d4egc5urnmocbb7t720n`, свежий id перепроверить).
- Объекты в бакете и сам бакет, KMS-ключ, лог-группа не удаляются (срок хранения 30 дней).

## Rules

- SOLID / DRY: переиспользуются `_journal`, формат спула, `_redirect`; одна функция `_reserve` с одной ответственностью; `frag` вынесен один раз.
- KISS / YAGNI: один PUT без ретраев; без новой очереди, БД, модуля, зависимостей; алерт и повтор — отдельные части.
- Minimal diff: `index.py` ≤ 100 строк; тесты существующие не правятся.
- No PII in logs; no secrets in code, tests, logs, diff; токен только из `context.token` в памяти.
- Не коммитить, не пушить, не трогать боевую Bitrix24 (write-пробы запрещены), не менять вебхук и ключ согласия.

## U2 (v2, 16.10 — U1 diff already in the worktree and accepted 9/9; keep it)
1. `index.py` ~530-531: token extraction `(getattr(context, "token", None) or {}).get("access_token", "")` raises if `context.token` is not a dict and kills the handler before the visitor redirect (invariant: visitor gets a redirect, never 5xx). Make it safe: non-dict → empty token → existing `no_iam_token` path. Add one case to `test_reserve.py` (context.token = "x" → `?err=server#contact`, no exception).
2. `forms-failover/fn-deploy.sh`: today `readonly FN_ID=d4eb92qbfgt3ac0udlmm` (line 7) is both the source of settings (`$latest` runtime/entrypoint/memory/timeout/SA/env, lines 57-85) and the deploy target. Add two optional flags for test deploys, defaults unchanged:
   - `--target <function-id>`: create the new version on this function instead of FN_ID (settings and env are still read from FN_ID `$latest`; `--rollback` unchanged).
   - `--env KEY=VALUE` (repeatable): replaces/adds that key in the copied env; `--dry-run` shows the key with `***` like the others.
   - Safety: if `--target` differs from FN_ID and no `--env WEBHOOK_URL=…` is given → `die` (a test function must never send to the production CRM).
   - `--help` documents both. Values never printed.
3. `forms-failover/fn-deploy-test.sh` (stub yc, existing style): add cases — `--target X --env WEBHOOK_URL=https://crm.invalid/rest/1/x --dry-run` shows `--function-id X` and `WEBHOOK_URL=***`; `--target X` without WEBHOOK_URL override → non-zero exit; default run still targets FN_ID. Existing cases stay green.
Acceptance U2: Acceptance 1–9 above still pass (item 9 now also allows `forms-failover/fn-deploy.sh` and `forms-failover/fn-deploy-test.sh`); `bash -n forms-failover/fn-deploy.sh` rc 0; `bash forms-failover/fn-deploy-test.sh` → all PASS. Real yc never called in tests.

## Decisions (architect, 16.10 — binding for the executor)
Points 5, 6, 7, 8, 9, 11, 12, 14, 15 are decided: as proposed in the TZ (non-success not spooled → reserve; response `?ok=1#sent`/`#psent`; U1 writes events only, alert/resend/`failed/` are separate units; PUT 5 s, no retry; test CRM URL `https://crm.invalid`). Point 3: prod function SA = `ajesk8iqatt8pn0ahtuk` (yc read-only, 16.10): `storage.editor` yes, KMS role no — affects only cloud AE2, not this code. Points 1, 2, 4, 10, 13 are cloud facts outside the executor's code task; the executor does only Change + Acceptance 1–9 (no cloud calls).

## Open points (history)

1. Принимает ли Object Storage (`storage.yandexcloud.net`) `Authorization: Bearer <IAM>` для PUT — атом утверждает по документации, я не проверял; подтверждается реальным PUT в тестовой функции (AE2). Если нет — решение владельца (статический ключ или другой путь); U1 не закрывается до этого.
2. Форма `context.token` в Python-рантайме: атом цитирует `access_token`; подтвердить на тестовой функции (логировать только имена ключей, не значения).
3. Сервисный аккаунт runtime-функции и его роли на бакет и KMS-ключ `abjadmbvvfbm4os08b5a` не указаны в данных (`ajesk8iqatt8pn0ahtuk` — SA API Gateway, не функции).
4. Лог-группа 30 дней не создана (таймаут `e23j891lukj50jeb65aq`, повтор `e2364c5jba2h0gt2kgc7` не завершён) — R4 и облачный AE1 не подтверждены.
5. Какие исходы уходят в резерв: предлагаю все не-success, не попавшие в спул (включая transient без спула). Подтвердить владельцем.
6. Ответ посетителю при успешном резерве: предлагаю `?ok=1#sent`/`#psent` (R8). Подтвердить.
7. Алерт: U1 только пишет события; фактическая отправка — сторож (U3). До U3 критерий «алерт» (AC3) не выполнен. Владелец подтверждает разделение.
8. Повтор (U2): способ определить «лид уже создан» для R6 (поле заявки или поиск в CRM) не решён (план: Deferred to Planning). Формат объекта задан U1.
9. Записи `failed/` из `drain_spool` (отказ CRM по содержанию в спуле) в U1 не резервируются — решить в U2 или отдельно.
10. Как и где выставляется `RESERVE_BUCKET` в деплое функции: `fn-deploy.sh` и путь README не найдены (атом), каноничность исходника относительно версии `d4egc5urnmocbb7t720n` не проверена.
11. Таймаут PUT 5 с и повтор без ретраев: достаточно ли для 503-окон Object Storage — решение владельца по бюджету задержки.
12. Атом ссылается на `arwox-v3-src/specs/053*` — каталога там нет; спека лежит в `/root/workspaces/projects/specs/053-forms-gateway-recovery/`. Где писать CR (AC4) — не решено.
13. Лимит и цена операций Object Storage (хранение ≤1 GB бесплатно — из атома; операции не сверены).
14. Фейковый CRM-адрес для тестовой функции не выбран (нужен недоступный хост, не боевой Bitrix24).
15. Подтвердить, что «оставшаяся часть» = резерв (журнал-порт уже в main, PR #49), а U2–U6 нумерация плана не записана.

## Sources

- `bd -C /root/workspaces/projects show dcfg-gured` (описание, ADR-053-CR1, NOTES, ACCEPTANCE, CHILDREN)
- `bd -C /root/workspaces/projects comments dcfg-gured` (комментарии 08.10–16.10: R7 решён вариантом B, допуск, бакет/KMS, лог-группа, context.token)
- `/root/workspaces/projects/arwox-v3-src/docs/tz/2026-10-16-dcfg-gured.3-journal-port.md` (формат TZ, строки 1–21)
- `/root/workspaces/projects/arwox-v3-src/site78-releases/2026-07-29/backend-arwox-lead-form/index.py` (строки 1–501, ключевые: 19, 26–40, 141–144, 213–227, 285–327, 371, 476–498)
- `/root/workspaces/projects/arwox-v3-src/site78-releases/2026-07-29/backend-arwox-lead-form/test_journal.py` (39–41, 63 и общий стиль стабов)
- `/root/workspaces/projects/arwox-v3-src/site78-releases/2026-07-29/backend-arwox-lead-form/test_lead.py` (1–60, 84–104, 218–234)
- `/root/workspaces/projects/arwox-v3-src/site78-releases/2026-07-29/backend-arwox-lead-form/consent.py` (106–114)
- `/root/workspaces/projects/arwox-v3-src/site78-releases/2026-07-29/backend-arwox-lead-form/requirements.txt`, `gateway-spec.yaml`
- `/root/workspaces/projects/.worktrees/claude/dcfg-gured/docs/plans/2026-10-08-1410-feat-forms-request-journal-plan.md` (R1–R8, AE1–AE4, Deferred to Planning)
- `/root/workspaces/projects/specs/053-forms-gateway-recovery/spec.md` (109, 127; FR-008)
- `git log` / `git status` / `git worktree list` в `/root/workspaces/projects/arwox-v3-src` (main 61dba56, PR #49)
- Не читались и не проверены: официальная документация Yandex Object Storage и Functions (атом цитирует их; я не сверял); forms-gw-guard.sh; fn-deploy.sh.
