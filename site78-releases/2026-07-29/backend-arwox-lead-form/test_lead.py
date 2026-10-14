"""Локальный self-check без сети: парсинг тела + гейт согласия + сборка полей + трейс.
Запуск: WEBHOOK_URL=x python3 test_lead.py"""
import os
import contextlib
import io
import tempfile
import urllib.error
import urllib.parse
from pathlib import Path

os.environ.setdefault("WEBHOOK_URL", "https://example/rest/1/x")
import index  # noqa: E402

calls = {}  # method -> последние переданные поля
def fake_call(method, fields, **kw):
    calls[method] = fields
    return {"result": 42}
index.call_b24 = fake_call

# Bitrix24 outcome: id is available to the reserve wrapper without changing 302.
index.call_b24 = lambda *_args, **_kw: {"result": 123}
assert index._lead_status({}, {}) == "success"
assert index.B24_OUTCOME.value == "lead:123"
index.call_b24 = fake_call


def act_fields():
    """PROVIDER_PARAMS.FIELDS дела-согласия как {caption: value[0]}."""
    a = calls["crm.activity.add"]["fields"]
    return {f["caption"]: f["value"][0] for f in a["PROVIDER_PARAMS"]["FIELDS"]}


def ev(pairs, headers=None):
    e = {"httpMethod": "POST", "body": urllib.parse.urlencode(pairs), "isBase64Encoded": False}
    if headers:
        e["headers"] = headers
    return e


_CANON = "__CANON_URLOPEN__"


def install_urlopen(fn):
    """Замена urlopen в urllib.request и её откат: у модуля urllib один словарь
    атрибутов (sys.modules["urllib.request"] is urllib.request), замена видна везде."""
    g = index._captcha_ok.__globals__["urllib"].request
    if not hasattr(g, _CANON):
        setattr(g, _CANON, g.urlopen)
    g.urlopen = fn


def restore_urlopen():
    """Возврат к каноническому urlopen, сохранённому install_urlopen."""
    g = index._captcha_ok.__globals__["urllib"].request
    if hasattr(g, _CANON):
        g.urlopen = getattr(g, _CANON)
        delattr(g, _CANON)


# U1: капча обязательна в проде → все позитивные сценарии идут через гейт.
# Ставим тестовую пару ключей и СИМУЛЯЦИЮ ответа validator (status=ok):
# заглушка доказывает работу гейта-кода, но НЕ то, что капчу решил человек.
_CAPTCHA_ENV = (("SMARTCAPTCHA_SITEKEY", "CAPTCHA_SITEKEY", "test-sitekey"),
                ("SMARTCAPTCHA_SECRET", "CAPTCHA_SECRET", "test-secret"))
_SAVED_CAPTCHA = (index.CAPTCHA_SITEKEY, index.CAPTCHA_SECRET)
_SAVED_URLOPEN = index._captcha_ok.__globals__["urllib"].request.urlopen
for _env, _attr, _val in _CAPTCHA_ENV:
    os.environ[_env] = _val
    setattr(index, _attr, _val)


class _Ok:
    """Минимальный контекст-менеджер ответа validate со status=ok."""

    def __enter__(self):
        return io.BytesIO(b'{"status": "ok"}')

    def __exit__(self, *exc):
        return False


def _ok_open(_req, **_kw):  # urlopen вызывается как urlopen(req, timeout=5)
    return _Ok()


install_urlopen(_ok_open)


with tempfile.TemporaryDirectory() as temp:
    os.environ["LEAD_SPOOL_DIR"] = temp
    index.call_b24 = lambda method, *_args, **_kw: ({}, "transient") if method == "crm.lead.add" else {"result": 42}
    response = index.handler(ev([("NAME", "Иван"), ("PHONE", "+79001112233"), ("CONSENT", "1"),
                                 ("smart-token", "tok")]), None)
    queued = next(Path(temp).glob("*.json"))
    assert response["headers"]["Location"].endswith("?ok=1#sent")
    assert index.B24_OUTCOME.value == f"queue:{queued.name}"
    index.call_b24 = lambda *_args, **_kw: {"result": 123}
    stdout = io.StringIO()
    with contextlib.redirect_stdout(stdout):
        index.drain_spool(temp)
    assert f"spool-sent spool={queued.name} b24=lead:123" in stdout.getvalue()
os.environ.pop("LEAD_SPOOL_DIR", None)
index.call_b24 = fake_call


# 1. Без согласия — лид не создаётся, редирект на ошибку согласия.
calls.clear()
r = index.handler(ev([("NAME", "Ivan"), ("PHONE", "+79001112233"), ("smart-token", "tok")]), None)
assert r["statusCode"] == 302 and "err=consent" in r["headers"]["Location"], r
assert not calls, "ничего не должно вызываться без согласия"

# 2. Полный квиз — квиз в UF, источник WEB, БЕЗ выдуманных UTM, + трейс сквозной аналитики.
calls.clear()
r = index.handler(ev([
    ("NAME", "Иван"), ("PHONE", "+79001112233"), ("CONSENT", "1"), ("AGREE", "1"),
    ("TEAM_SIZE", "от 5 до 50"), ("TOOLS", "Битрикс24"), ("TOOLS", "1С"),
    ("LAUNCH", "в этом месяце"), ("INDUSTRY", "продажи"),
    ("COMPANY", "ООО Ромашка"), ("COMMENTS", "Нужна CRM и телефония"),
    ("UTM_CONTENT", "full-quiz"), ("smart-token", "tok-full-quiz"),
], headers={"Referer": "https://arwox.ru/", "X-Forwarded-For": "203.0.113.5"}), None)
assert r["statusCode"] == 302 and r["headers"]["Location"].endswith("?ok=1#sent"), r
f = calls["crm.lead.add"]
assert f["fields[PHONE][0][VALUE]"] == "+79001112233"
assert f["fields[UF_CRM_LEAD_TEAM]"] == "от 5 до 50"
assert f["fields[UF_CRM_LEAD_TOOLS]"] == "Битрикс24, 1С"
assert f["fields[UF_CRM_LEAD_INDUSTRY]"] == "продажи"
assert f["fields[UF_CRM_LEAD_COMPANY]"] == "ООО Ромашка"
assert f["fields[COMMENTS]"] == "Нужна CRM и телефония"
assert f["fields[SOURCE_ID]"] == "WEB"
assert f["fields[SOURCE_DESCRIPTION]"] == "Форма: Полный квиз | Реферер: arwox.ru"
assert not any(k.startswith("fields[UTM") for k in f), "выдуманных UTM быть не должно"
assert "crm.tracking.trace.add" not in calls, "трейс не создаём (даёт «Прочий трафик»)"
# Дело-согласие формата штатной вебформы: все поля квиза + галочка ПДн.
a = calls["crm.activity.add"]["fields"]
assert a["PROVIDER_ID"] == "CRM_WEBFORM" and a["COMPLETED"] == "Y", a
af = act_fields()
assert af["Имя"] == "Иван" and af["Телефон"] == "+79001112233"
assert af["Компания"] == "ООО Ромашка" and af["Инструменты"] == "Битрикс24, 1С"
assert af["Комментарий"] == "Нужна CRM и телефония"
assert af["Даю согласие на обработку ПДн"] == "Да"
assert "Согласие на рассылку" not in af, "галочка не нажата — не показываем"
assert "E-mail" not in af
fm = a["PROVIDER_PARAMS"]["FORM"]
assert fm["AGREEMENTS"] == [index.CONSENT_AGREEMENT_ID] and fm["IP"] == "203.0.113.5"
assert fm["LINK"] == "https://arwox.ru/"
# Реестр согласий: связка с делом как у штатной формы.
c = calls["userconsent.consent.add"]
assert c["ORIGINATOR_ID"] == "crm/activity" and c["ORIGIN_ID"] == "42", c
assert c["URL"] == "https://arwox.ru"

# 2b. Серверная валидация контакта: мусор не создаёт лид (2-й уровень после pattern).
for bad in ("12345", "abc", "8-916", "user@", "@mail.ru", "a b@c",
            "+1 234 567 8901", "89991", "12323231231"):
    calls.clear()
    r = index.handler(ev([("NAME", "123"), ("PHONE", bad), ("CONSENT", "1"), ("smart-token", "tok")]), None)
    assert r["statusCode"] == 302 and r["headers"]["Location"].endswith("?err=contact#lead-form"), (bad, r)
    assert not calls, bad
for good in ("+7 (900) 111-22-33", "89001112233", "9991112233", "user@mail.ru"):
    calls.clear()
    index.handler(ev([("NAME", "Иван"), ("PHONE", good), ("CONSENT", "1"), ("smart-token", "tok")],
                     headers={"X-Forwarded-For": "203.0.113.9"}), None)
    assert "crm.lead.add" in calls, good

# 3. GET — не обрабатываем.
calls.clear()
r = index.handler({"httpMethod": "GET"}, None)
assert r["statusCode"] == 302 and not calls, r

# 4. Попап → успех #psent, маркер в источнике; галочка рассылки — в деле.
calls.clear()
r = index.handler(ev([
    ("NAME", "Пётр"), ("PHONE", "+79005553311"), ("CONSENT", "1"), ("AGREE", "1"),
    ("CONSENT_MAILING", "1"), ("smart-token", "tok"),
    ("UTM_CONTENT", "popup"), ("COMMENTS", "Быстрая заявка — попап"),
], headers={"X-Forwarded-For": "203.0.113.6"}), None)
assert r["statusCode"] == 302 and r["headers"]["Location"].endswith("?ok=1#psent"), r
assert calls["crm.lead.add"]["fields[SOURCE_DESCRIPTION]"] == \
    "Форма: Попап быстрой заявки | Быстрая заявка — попап | Согласие на рассылку: ДА"
af = act_fields()
assert af["Согласие на рассылку"] == "Да" and af["Форма"] == "Попап быстрой заявки"

# 5. Футер: e-mail в поле PHONE → в EMAIL лида и в E-mail дела, не в телефон.
calls.clear()
r = index.handler(ev([
    ("NAME", "Чек-лист (футер)"), ("PHONE", "user@mail.ru"), ("CONSENT", "1"),
    ("UTM_CONTENT", "checklist"), ("COMMENTS", "Запрос: чек-лист"), ("smart-token", "tok"),
], headers={"X-Forwarded-For": "203.0.113.7"}), None)
f = calls["crm.lead.add"]
assert f["fields[EMAIL][0][VALUE]"] == "user@mail.ru", f
assert "fields[PHONE][0][VALUE]" not in f
af = act_fields()
assert af["E-mail"] == "user@mail.ru" and "Телефон" not in af

# 6. Реферер сквозь капчу: заголовок со своего домена игнорируется, hidden REF_ORIGIN побеждает.
calls.clear()
r = index.handler(ev([
    ("NAME", "Ольга"), ("PHONE", "+79001110000"), ("CONSENT", "1"), ("smart-token", "tok"),
    ("UTM_CONTENT", "popup"), ("REF_ORIGIN", "arwox.ru"),
], headers={"Referer": "https://forms.arwox.ru/", "X-Forwarded-For": "203.0.113.8"}), None)
assert "Реферер: arwox.ru" in calls["crm.lead.add"]["fields[SOURCE_DESCRIPTION]"]
assert calls["crm.activity.add"]["fields"]["PROVIDER_PARAMS"]["FORM"]["LINK"] == "https://arwox.ru/"
assert calls["userconsent.consent.add"]["URL"] == "https://arwox.ru"

# 7. U1 fail-closed: нет sitekey ИЛИ нет secret → lead-путь закрыт: ни CRM, ни очереди.
#    (Раньше handler вообще не входил в гейт CAPTCHA_SECRET, а _captcha_ok
#    при пустом secret возвращала True — спам проходил без ключей.)
_SAVED = (index.CAPTCHA_SITEKEY, index.CAPTCHA_SECRET)
_runs_empty_secret = [0]


def _fake_validate():
    """Стаб urlopen для validate: «человек прошёл капчу» по требованию ТЗ."""
    def _open(_req, _timeout):
        _runs_empty_secret[0] += 1
        raise AssertionError("urlopen вызван без конфигурации капчи")
    return _open


for missing in ("CAPTCHA_SITEKEY", "CAPTCHA_SECRET"):
    calls.clear()
    setattr(index, missing, "")
    try:
        if missing == "CAPTCHA_SITEKEY":
            def _no_validate(_req, **_kw):  # validate не должен вызываться без конфига
                _runs_empty_secret[0] += 1
                raise AssertionError("urlopen вызван без конфигурации капчи")
            install_urlopen(_no_validate)
        r = index.handler(ev([("NAME", "Виктор"), ("PHONE", "+79001112233"), ("CONSENT", "1"),
                              ("smart-token", "test-token")]), None)
        assert r["statusCode"] == 302 and "?err=server" in r["headers"]["Location"], (missing, r)
        assert not calls, f"{missing}: лид/очередь прошли без конфига капчи"
    finally:
        setattr(index, missing, _SAVED[0] if missing == "CAPTCHA_SITEKEY" else _SAVED[1])
        if missing == "CAPTCHA_SITEKEY":
            restore_urlopen()

# 8. U1: пустой secret не пропускает токен через _captcha_ok (раньше → True).
index.CAPTCHA_SECRET = ""
try:
    assert index._captcha_ok("test-token", "203.0.113.5") == "fail", \
        "пустой SMARTCAPTCHA_SECRET не должен пропускать токен"
finally:
    index.CAPTCHA_SECRET = _SAVED[1]

# 9. U1 позитив: настроенная капча с validator status=ok — заявка проходит как раньше.
calls.clear()
for name, val in (("SMARTCAPTCHA_SITEKEY", "sitekey-x"), ("SMARTCAPTCHA_SECRET", "secret-x")):
    os.environ.setdefault(name, val)
    setattr(index, name, val)
saved_urlopen = index._captcha_ok.__globals__["urllib"].request.urlopen
index._captcha_ok.__globals__["urllib"].request.urlopen = _ok_open
try:
    r = index.handler(ev([("NAME", "С позитивом"), ("PHONE", "+79001112233"), ("CONSENT", "1"),
                          ("UTM_CONTENT", "popup"), ("REF_ORIGIN", "arwox.ru"),
                          ("smart-token", "tok")],
                         headers={"X-Forwarded-For": "203.0.113.5"}), None)
    assert r["statusCode"] == 302 and r["headers"]["Location"].endswith("?ok=1#psent"), r
    assert "crm.lead.add" in calls, "валидный токен должен доходить до CRM"
finally:
    index._captcha_ok.__globals__["urllib"].request.urlopen = saved_urlopen
    for name in ("SMARTCAPTCHA_SITEKEY", "SMARTCAPTCHA_SECRET"):
        os.environ.pop(name, None)

# 10. Validator недоступен (URLError) → лид всё равно создаётся, TITLE с префиксом.
calls.clear()


def _unavail_open(_req, **_kw):
    raise urllib.error.URLError("collector unreachable")


install_urlopen(_unavail_open)
try:
    r = index.handler(ev([("NAME", "Сбой Яндекса"), ("PHONE", "+79001112233"), ("CONSENT", "1"),
                          ("smart-token", "tok")],
                         headers={"X-Forwarded-For": "203.0.113.5"}), None)
    assert r["statusCode"] == 302 and r["headers"]["Location"].endswith("?ok=1#sent"), r
    assert len([k for k in calls if k == "crm.lead.add"]) == 1, calls
    assert calls["crm.lead.add"]["fields[TITLE]"].startswith("[captcha-unverified] "), calls
finally:
    restore_urlopen()

# 11. U1: HTTP 4xx от validator — отказ капчи (спам-токен), НЕ недоступность:
#     лид отклоняем — страница капчи с ошибкой, ни CRM, ни очереди.
#     Сеть/таймаут/HTTP 5xx остаются недоступностью → 'unavailable'.
calls.clear()


def _reject_open(_req, **_kw):
    raise urllib.error.HTTPError("https://smartcaptcha.yandexcloud.net/validate", 403,
                                 "Forbidden", {}, None)


install_urlopen(_reject_open)
try:
    r = index.handler(ev([("NAME", "Спам-токен"), ("PHONE", "+79001112233"), ("CONSENT", "1"),
                          ("smart-token", "fc14-invalid-token")],
                         headers={"X-Forwarded-For": "203.0.113.5"}), None)
    assert r["statusCode"] == 200 and not calls, (r, calls)
finally:
    restore_urlopen()


def _outage_open(_req, **_kw):
    raise urllib.error.HTTPError("https://smartcaptcha.yandexcloud.net/validate", 503,
                                 "Service Unavailable", {}, None)


install_urlopen(_outage_open)
try:
    assert index._captcha_ok("tok", "203.0.113.5") == "unavailable", "HTTP 503 — недоступность"
finally:
    restore_urlopen()


def _dns_outage_open(_req, **_kw):
    raise urllib.error.URLError("Name or service not known")


install_urlopen(_dns_outage_open)
try:
    stdout = io.StringIO()
    with contextlib.redirect_stdout(stdout):
        assert index._captcha_ok("tok", "203.0.113.5") == "unavailable", "URLError — недоступность"
    assert "captcha_error=URLError:" in stdout.getvalue(), stdout.getvalue()
finally:
    restore_urlopen()

# 12. Капча-страница постит токен обратно на URL, который её отдал: action="",
#     никакого functions.yandexcloud.net (резерв/API Gateway/прямой URL — любой хост).
calls.clear()
stdout = io.StringIO()
with contextlib.redirect_stdout(stdout):
    r = index.handler(ev([("NAME", "Мария"), ("PHONE", "+79001112233"), ("CONSENT", "1")]), None)
assert r["statusCode"] == 200 and 'action=""' in r["body"], r
assert "functions.yandexcloud.net" not in r["body"], r
assert "captcha=page" in stdout.getvalue(), stdout.getvalue()
print(stdout.getvalue(), end="")

print("PASS: все проверки прошли")
