"""arwox-lead-form — приём POST от форм лендинга ARWOX (B24 сайт 78)
и создание лида в CRM через входящий вебхук. JS на B24-лендинге невозможен,
поэтому форма шлёт нативный POST (urlencoded), функция отвечает 302-редиректом
обратно на лендинг: успех → #sent (попап → #psent), отказ по согласию → ?err=consent#contact.

Лид заполняется максимально (квиз → UF-поля, скрытая атрибуция → SOURCE/UTM),
чтобы владелец вручную конвертировал его в сделку воронки квалификации.
"""
import base64
import html
import json
import os
import re
import secrets
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from datetime import datetime, timezone
from pathlib import Path
import threading
from threading import Lock

import consent  # реестр доказуемого согласия (M9.4), тот же каталог

B24_OUTCOME = threading.local()
WEBHOOK = os.environ["WEBHOOK_URL"].rstrip("/")
LANDING = os.environ.get("LANDING_URL", "https://b24-qf21tb.bitrix24site.ru/")
# Документ согласия (живая страница сайта) + папка Диска реестра.
CONSENT_DOC_URL = os.environ.get(
    "CONSENT_DOC_URL", "https://arwox.ru/legal/soglasie-na-obrabotku-personalnyh-dannyh/")
CONSENT_DISK_FOLDER_ID = int(os.environ.get("CONSENT_DISK_FOLDER_ID", "56848"))
# Нативная система B24 «Согласия пользователей» (userconsent). AGREEMENT_ID из agreement.list.
CONSENT_AGREEMENT_ID = int(os.environ.get("CONSENT_AGREEMENT_ID", "16"))
# SmartCaptcha (анти-спам, Вариант C: капча на странице, которую отдаёт функция).
CAPTCHA_SITEKEY = os.environ.get("SMARTCAPTCHA_SITEKEY", "")
CAPTCHA_SECRET = os.environ.get("SMARTCAPTCHA_SECRET", "")
SELF_URL = os.environ.get("SELF_URL", "https://functions.yandexcloud.net/d4eb92qbfgt3ac0udlmm")

_CAPTCHA_HTML = """<!doctype html><html lang="ru"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Отправка заявки — ARWOX</title>
<script src="https://smartcaptcha.yandexcloud.net/captcha.js?render=onload&onload=__capInit" defer></script>
<style>body{margin:0;font-family:-apple-system,Segoe UI,Roboto,Arial,sans-serif;background:#f4f7fb;
display:flex;min-height:100vh;align-items:center;justify-content:center}
.card{background:#fff;padding:32px 28px;border-radius:16px;box-shadow:0 8px 40px rgba(0,60,150,.12);
max-width:380px;width:90%;text-align:center}
h2{margin:0 0 6px;font-size:19px;color:#0b1f3a}p{margin:0 0 18px;color:#5b6b82;font-size:14px}
.sp{width:34px;height:34px;margin:0 auto 16px;border:3px solid #d9e6ff;border-top-color:#006DFF;
border-radius:50%;animation:r 0.8s linear infinite}@keyframes r{to{transform:rotate(360deg)}}
button{background:#006DFF;color:#fff;border:0;border-radius:10px;padding:13px 20px;font-size:15px;
width:100%;cursor:pointer}.e{color:#d33;font-size:13px;margin-bottom:12px}
#manual{display:none}</style></head>
<body><div class="card">
<div id="wait"><div class="sp"></div><h2>Отправляем заявку…</h2>
<p>Секундная проверка безопасности, ничего нажимать не нужно.</p></div>
<div id="manual"><h2>Не удалось проверить автоматически</h2>
<p>Нажмите кнопку — и заявка уйдёт менеджеру.</p></div>[[ERR]]
<form method="POST" action="[[ACTION]]" id="f">[[HIDDEN]]
<div id="cap"></div>
<button type="button" id="retry" style="display:none" onclick="__capGo()">Отправить заявку</button></form></div>
<script>
/* Невидимая SmartCaptcha (офиц. дока invisible-captcha): чистый пользователь проезжает
   без единого клика, challenge всплывает только подозрительным. */
var __wid=null,__sent=false;
function __fail(){document.getElementById('wait').style.display='none';
document.getElementById('manual').style.display='block';
document.getElementById('retry').style.display='block';}
function __capGo(){if(window.smartCaptcha&&__wid!==null){smartCaptcha.execute(__wid);}else{__fail();}}
function __capInit(){
 if(!window.smartCaptcha){__fail();return;}
 __wid=smartCaptcha.render('cap',{sitekey:'[[SITEKEY]]',invisible:true,
  shieldPosition:'bottom-right',hl:'ru',
  callback:function(t){if(__sent)return;__sent=true;
   var i=document.createElement('input');i.type='hidden';i.name='smart-token';i.value=t;
   var f=document.getElementById('f');f.appendChild(i);f.submit();}});
 smartCaptcha.subscribe(__wid,'network-error',__fail);
 smartCaptcha.subscribe(__wid,'javascript-error',__fail);
 smartCaptcha.execute(__wid);
}
/* Скрипт капчи не загрузился/завис — не держим клиента на спиннере дольше 8 сек. */
setTimeout(function(){if(!__sent){__fail();}},8000);
</script></body></html>"""


def _captcha_page(params, error=False):
    """HTML-страница с виджетом SmartCaptcha; поля заявки — в скрытых input (переносятся на 2-й POST)."""
    hidden = []
    for k, vals in params.items():
        if k == "smart-token":
            continue
        for v in vals:
            hidden.append('<input type="hidden" name="%s" value="%s">'
                          % (html.escape(k, True), html.escape(v, True)))
    err = '<div class="e">Проверка не пройдена, попробуйте ещё раз.</div>' if error else ''
    body = (_CAPTCHA_HTML.replace("[[HIDDEN]]", "\n".join(hidden))
            .replace("[[ACTION]]", html.escape(SELF_URL, True))
            .replace("[[SITEKEY]]", html.escape(CAPTCHA_SITEKEY, True))
            .replace("[[ERR]]", err))
    return {"statusCode": 200,
            "headers": {"Content-Type": "text/html; charset=utf-8", "Cache-Control": "no-store"},
            "body": body}


def _captcha_ok(token, ip):
    """Серверная проверка токена SmartCaptcha. Нет секрета → капча выключена (пропускаем).
    Сервис недоступен → не терять валидного клиента (пропускаем); ботов ловим на этапе «нет токена»."""
    if not CAPTCHA_SECRET:
        return True
    try:
        data = urllib.parse.urlencode({"secret": CAPTCHA_SECRET, "token": token, "ip": ip}).encode()
        req = urllib.request.Request("https://smartcaptcha.yandexcloud.net/validate", data=data)
        with urllib.request.urlopen(req, timeout=5) as r:
            return json.loads(r.read()).get("status") == "ok"
    except Exception:
        return True

_TRANSIENT = ("QUERY_LIMIT_EXCEEDED", "OPERATION_TIME_LIMIT", "ERROR_CORE", "ACTION_FAILED")

# Человекочитаемые метки форм (по UTM_CONTENT) для «Дополнительно об источнике».
_FORM_LABELS = {
    "popup": "Попап быстрой заявки",
    "full-quiz": "Полный квиз",
    "checklist": "Чек-лист (футер)",
}


def call_b24(method, params, _retries=3, _backoff=2.0, as_json=False, with_status=False):
    """POST в Bitrix24 REST через вебхук. Ретраи на сетевых и transient-ошибках.
    Возвращает распарсенный dict; на полном отказе — {} (никогда не бросает).
    as_json — для вложенных структур (PROVIDER_PARAMS); плоские вызовы остаются urlencode."""
    if as_json:
        data = json.dumps(params).encode()
        headers = {"Content-Type": "application/json"}
    else:
        data = urllib.parse.urlencode(params, doseq=True).encode()
        headers = {}
    def result(value, status):
        return (value, status) if with_status else value

    url = f"{WEBHOOK}/{method}"
    for attempt in range(_retries):
        try:
            req = urllib.request.Request(url, data=data, headers=headers)
            with urllib.request.urlopen(req, timeout=30) as r:
                parsed = json.loads(r.read())
            if parsed.get("error", "") in _TRANSIENT:
                raise RuntimeError("bitrix transient")
            return result(parsed, "content:json" if parsed.get("error") else "success")
        except urllib.error.HTTPError as exc:
            if (exc.code == 429 or exc.code >= 500) and attempt < _retries - 1:
                time.sleep(_backoff ** attempt)
                continue
            return result({}, f"{'transient' if exc.code == 429 or exc.code >= 500 else 'content'}:{exc.code}")
        except (urllib.error.URLError, RuntimeError, TimeoutError):
            if attempt < _retries - 1:
                time.sleep(_backoff ** attempt)
                continue
            return result({}, "transient:network")
    return result({}, "transient:network")


def _redirect(fragment):
    """302 обратно на лендинг с указанным хвостом (#sent / ?err=...#contact)."""
    sep = "" if fragment.startswith(("#", "?")) else "#"
    return {"statusCode": 302, "headers": {"Location": f"{LANDING}{sep}{fragment}"}, "body": ""}


def _valid_contact(c):
    """Телефон РФ: 11 цифр с 7/8 либо 10 цифр с 9 (скобки/дефисы/пробелы/+ игнорируем).
    E-mail: базовая форма. Зеркалит pattern контакт-полей лендинга."""
    if "@" in c:
        return re.fullmatch(r"[^@\s]+@[^@\s]+\.[^@\s]+", c) is not None
    d = re.sub(r"\D", "", c)
    return (len(d) == 11 and d[0] in "78") or (len(d) == 10 and d[0] == "9")


def _body_params(event):
    """Распаковать urlencoded-тело POST в dict со списками (multi-value)."""
    body = event.get("body") or ""
    if event.get("isBase64Encoded"):
        body = base64.b64decode(body).decode("utf-8", "replace")
    return urllib.parse.parse_qs(body, keep_blank_values=True)


def _header(event, name):
    """Регистронезависимый доступ к HTTP-заголовку запроса."""
    for k, v in (event.get("headers") or {}).items():
        if k.lower() == name.lower():
            return (v or "").strip()
    return ""


_SPOOL_LIMIT = 500
_SPOOL_LOCK = Lock()


def _lead_status(fields, ctx):
    outcome = call_b24("crm.lead.add", fields, with_status=True)
    if isinstance(outcome, tuple):
        res, status = outcome
    else:  # совместимо с существующими тестовыми заглушками call_b24
        res, status = outcome, "success" if outcome.get("result") else "content:empty"
    if status != "success" or not res.get("result"):
        return status if status.startswith("transient") else "content:lead"

    try:
        ip = ctx.get("ip", "")
        if ip:
            form_content = ctx.get("form_content", "")
            form_label = _FORM_LABELS.get(form_content, form_content or "Форма сайта")
            contact = ctx.get("contact", "")
            raw_fields = [
                ("string", "FORM", "Форма", form_label),
                ("string", "NAME", "Имя", ctx.get("name", "")),
                ("phone", "PHONE", "Телефон", "" if "@" in contact else contact),
                ("email", "EMAIL", "E-mail", contact if "@" in contact else ""),
                ("string", "COMPANY", "Компания", ctx.get("company", "")),
                ("string", "INDUSTRY", "Отрасль", ctx.get("industry", "")),
                ("string", "TEAM_SIZE", "Размер команды", ctx.get("team_size", "")),
                ("list", "TOOLS", "Инструменты", ", ".join(ctx.get("tools", []))),
                ("string", "LAUNCH", "Запуск", ctx.get("launch", "")),
                ("text", "COMMENTS", "Комментарий", ctx.get("comments", "")),
                ("list", "CONSENT", "Даю согласие на обработку ПДн", "Да"),
                ("list", "CONSENT_MAILING", "Согласие на рассылку",
                 "Да" if ctx.get("consent_mailing") else ""),
                ("string", "CONSENT_DOC", "Документ согласия", CONSENT_DOC_URL),
            ]
            ref_origin = ctx.get("ref_origin", "")
            act = call_b24("crm.activity.add", {"fields": {
                "OWNER_TYPE_ID": 1, "OWNER_ID": res["result"], "TYPE_ID": 6,
                "PROVIDER_ID": "CRM_WEBFORM", "PROVIDER_TYPE_ID": "4",
                "SUBJECT": f"Согласие ПДн получено — {form_label}",
                "COMPLETED": "Y",
                "RESPONSIBLE_ID": os.environ.get("ASSIGNED_BY_ID", "1"),
                "DESCRIPTION": "", "DESCRIPTION_TYPE": "1",
                "START_TIME": ctx.get("created_at", ""), "END_TIME": ctx.get("created_at", ""),
                "PROVIDER_PARAMS": {
                    "FIELDS": [{"type": t, "code": c, "caption": cap, "value": [v]}
                               for t, c, cap, v in raw_fields if v],
                    "FORM": {"IS_USED_USER_CONSENT": True,
                             "AGREEMENTS": [CONSENT_AGREEMENT_ID],
                             "IP": ip, "LINK": f"https://{ref_origin}/" if ref_origin else LANDING},
                },
            }}, as_json=True)
            act_id = act.get("result") if isinstance(act.get("result"), int) else None
            call_b24("userconsent.consent.add", {
                "AGREEMENT_ID": CONSENT_AGREEMENT_ID, "IP": ip,
                "URL": f"https://{ref_origin}" if ref_origin else LANDING,
                "ORIGINATOR_ID": "crm/activity" if act_id else (contact or ctx.get("name", "")),
                "ORIGIN_ID": str(act_id) if act_id else f"arwox-lead-form:{form_content or 'form'}",
            })
    except Exception:
        pass  # ponytail: согласие best-effort, лид уже создан — ответ не рушим
    B24_OUTCOME.value = f"lead:{res['result']}"
    return "success"


def create_lead(fields, ctx):
    return _lead_status(fields, ctx)


def _spool_log(name, action, status):
    print(f"lead-spool id={name} action={action} status={status}", file=sys.stderr)


def _ensure_spool(spool_dir):
    old_umask = os.umask(0o077)
    try:
        Path(spool_dir).mkdir(mode=0o700, parents=True, exist_ok=True)
    finally:
        os.umask(old_umask)
    os.chmod(spool_dir, 0o700)


def _write_spool(spool_dir, name, item):
    _ensure_spool(spool_dir)
    target = Path(spool_dir, name)
    temporary = target.with_name(target.name + ".tmp")
    old_umask = os.umask(0o077)
    try:
        with open(temporary, "x", encoding="utf-8") as f:
            json.dump(item, f, ensure_ascii=False, separators=(",", ":"))
        os.chmod(temporary, 0o600)
        os.replace(temporary, target)
    finally:
        os.umask(old_umask)


def _enqueue_lead(spool_dir, fields, ctx):
    with _SPOOL_LOCK:
        _ensure_spool(spool_dir)
        spool = Path(spool_dir)
        if sum(1 for _ in spool.glob("*.json")) + sum(1 for _ in spool.glob("*.inflight")) >= _SPOOL_LIMIT:
            return False
        name = f"{secrets.token_hex(8)}.json"
        _write_spool(spool_dir, name, {
            "fields": fields, "ctx": ctx, "attempts": 0, "created": time.time(),
        })
        B24_OUTCOME.value = f"queue:{name}"
    return True


def _move_failed(path, spool_dir, status):
    failed = Path(spool_dir, "failed")
    _ensure_spool(failed)
    os.replace(path, failed / path.with_suffix(".json").name)
    _spool_log(path.name, "failed", status)


def drain_spool(spool_dir, now=None):
    """Дослать очередь. Одна запись не останавливает обработку соседних."""
    now = time.time() if now is None else now
    _ensure_spool(spool_dir)
    spool = Path(spool_dir)
    for inflight in list(spool.glob("*.inflight")):
        os.replace(inflight, inflight.with_suffix(".json"))
    for queued in list(spool.glob("*.json")):
        inflight = queued.with_suffix(".inflight")
        try:
            os.replace(queued, inflight)
            item = json.loads(inflight.read_text(encoding="utf-8"))
            if not isinstance(item, dict) or not isinstance(item.get("fields"), dict) or not isinstance(item.get("ctx"), dict):
                raise ValueError("json")
            if item.get("created", now) < now - 86400 or item.get("attempts", 0) >= 100:
                _move_failed(inflight, spool_dir, "expired")
                continue
            status = create_lead(item["fields"], item["ctx"])
            if status == "success":
                inflight.unlink()
                _spool_log(inflight.name, "sent", "success")
                print(f"forms-backup spool-sent spool={queued.name} b24={getattr(B24_OUTCOME, 'value', '-')}", flush=True)
            elif status.startswith("transient"):
                item["attempts"] = item.get("attempts", 0) + 1
                _write_spool(spool_dir, queued.name, item)
                inflight.unlink()
                _spool_log(queued.name, "retry", status)
            else:
                _move_failed(inflight, spool_dir, status)
        except Exception:
            if inflight.exists():
                _move_failed(inflight, spool_dir, "invalid")


def handler(event, context):
    if (event.get("httpMethod") or "").upper() != "POST":
        return _redirect("#contact")

    p = _body_params(event)
    get = lambda k: (p.get(k, [""])[0] or "").strip()

    # Согласие на обработку ПД обязательно — сервер отвергает без него.
    if not get("CONSENT"):
        return _redirect("?err=consent#contact")

    name = get("NAME")
    contact = get("PHONE") or get("EMAIL")  # контактное поле: телефон ИЛИ e-mail
    if not contact and not name:
        return _redirect("?err=empty#contact")
    # Серверная валидация контакта (2-й уровень после pattern в браузере —
    # работает даже при закэшированной старой разметке): e-mail по форме,
    # телефон = 10-15 цифр после чистки. Мусор («12323») лид не создаёт.
    if contact and not _valid_contact(contact):
        # инлайн-строка ошибки в форме (#lead-form:target .srv-err), без попапов
        return _redirect("?err=contact#lead-form")

    # Реферер считаем ДО шага капчи: второй POST приходит уже со страницы капчи (forms.arwox.ru),
    # поэтому исходный домен (arwox.ru) переносим скрытым полем REF_ORIGIN; свой домен — не источник.
    ref_origin = get("REF_ORIGIN") or urllib.parse.urlsplit(_header(event, "Referer")).netloc
    if ref_origin == urllib.parse.urlsplit(SELF_URL).netloc:
        ref_origin = ""

    # SCAP-1 анти-спам: нет валидного токена капчи → отдаём капча-страницу (бот дальше не пройдёт,
    # прямой POST на функцию без токена тоже упирается сюда). Токен есть → проверяем на сервере Яндекса.
    if CAPTCHA_SECRET:
        token = get("smart-token")
        if not token:
            p["REF_ORIGIN"] = [ref_origin]
            return _captcha_page(p)
        if not _captcha_ok(token, consent.extract_request_context(event)["ip"]):
            p["REF_ORIGIN"] = [ref_origin]
            return _captcha_page(p, error=True)

    tools = [t.strip() for t in p.get("TOOLS", []) if t.strip()]
    company = get("COMPANY")
    industry = get("INDUSTRY")
    # COMMENTS: текст задачи (квиз) ИЛИ маркер формы (попап/футер).
    marker = get("COMMENTS")
    if get("CONSENT_MAILING"):
        marker = (marker + " | " if marker else "") + "Согласие на рассылку: ДА"
    failover_note = os.environ.get("LEAD_FAILOVER_NOTE")
    if failover_note:
        marker = f"{failover_note}\n{marker}" if marker else failover_note

    # --- Скрытая атрибуция (сквозная аналитика), невидима пользователю ---
    form_content = get("UTM_CONTENT")  # метка формы + драйвер редиректа
    form_label = _FORM_LABELS.get(form_content, form_content or "Форма сайта")
    src_parts = [f"Форма: {form_label}"]
    if ref_origin:
        src_parts.append(f"Реферер: {ref_origin}")
    # Маркер-подсказка попапа/футера — в источник (у квиза здесь текст задачи).
    if marker and form_content in ("popup", "checklist"):
        src_parts.append(marker)
    source_description = " | ".join(src_parts)

    fields = {
        "fields[TITLE]": f"Заявка с лендинга ARWOX — {name or contact}",
        "fields[NAME]": name,
        "fields[SOURCE_ID]": "WEB",  # заявка с веб-сайта (для аналитики «сколько с сайта»)
        "fields[SOURCE_DESCRIPTION]": source_description,
        "fields[STATUS_ID]": "NEW",
        "fields[ASSIGNED_BY_ID]": os.environ.get("ASSIGNED_BY_ID", "1"),
    }
    if marker:
        fields["fields[COMMENTS]"] = marker
    # Контакт: e-mail (по «@») → EMAIL лида, иначе → PHONE. Чинит футер (email в phone).
    if contact:
        multi = "EMAIL" if "@" in contact else "PHONE"
        fields[f"fields[{multi}][0][VALUE]"] = contact
        fields[f"fields[{multi}][0][VALUE_TYPE]"] = "WORK"
    # Квиз → отдельные UF-поля лида.
    if get("TEAM_SIZE"):
        fields["fields[UF_CRM_LEAD_TEAM]"] = get("TEAM_SIZE")
    if tools:
        fields["fields[UF_CRM_LEAD_TOOLS]"] = ", ".join(tools)
    if get("LAUNCH"):
        fields["fields[UF_CRM_LEAD_LAUNCH]"] = get("LAUNCH")
    if industry:
        fields["fields[UF_CRM_LEAD_INDUSTRY]"] = industry
    if company:
        # В своё UF-поле — COMPANY_TITLE затирает робот портала.
        fields["fields[UF_CRM_LEAD_COMPANY]"] = company
    # Никаких выдуманных меток: источник несёт SOURCE_ID=WEB («Веб-сайт») + SOURCE_DESCRIPTION.
    # Метки трафика — только реальные с рекламных площадок (сейчас их нет), поэтому не пишем.

    request_context = consent.extract_request_context(event)
    lead_context = {
        "ip": request_context["ip"], "user_agent": request_context["user_agent"],
        "created_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%S"),
        "ref_origin": ref_origin, "form_content": form_content, "name": name, "contact": contact,
        "company": company, "industry": industry, "team_size": get("TEAM_SIZE"), "tools": tools,
        "launch": get("LAUNCH"), "comments": get("COMMENTS"),
        "consent_mailing": bool(get("CONSENT_MAILING")),
    }
    status = create_lead(fields, lead_context)
    if status.startswith("transient"):
        spool_dir = os.environ.get("LEAD_SPOOL_DIR")
        if spool_dir:
            try:
                if _enqueue_lead(spool_dir, fields, lead_context):
                    frag = "?ok=1#psent" if form_content == "popup" else "?ok=1#sent"
                    return _redirect(frag)
            except Exception:
                pass
        return _redirect("?err=server#contact")
    if status != "success":
        return _redirect("?err=server#contact")
    frag = "?ok=1#psent" if form_content == "popup" else "?ok=1#sent"
    return _redirect(frag)
