"""Локальный self-check без сети: парсинг тела + гейт согласия + сборка полей + трейс.
Запуск: WEBHOOK_URL=x python3 test_lead.py"""
import os
import contextlib
import io
import tempfile
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


with tempfile.TemporaryDirectory() as temp:
    os.environ["LEAD_SPOOL_DIR"] = temp
    index.call_b24 = lambda method, *_args, **_kw: ({}, "transient") if method == "crm.lead.add" else {"result": 42}
    response = index.handler(ev([("NAME", "Ivan"), ("PHONE", "+79001112233"), ("CONSENT", "1")]), None)
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
r = index.handler(ev([("NAME", "Ivan"), ("PHONE", "+79001112233")]), None)
assert r["statusCode"] == 302 and "err=consent" in r["headers"]["Location"], r
assert not calls, "ничего не должно вызываться без согласия"

# 2. Полный квиз — квиз в UF, источник WEB, БЕЗ выдуманных UTM, + трейс сквозной аналитики.
calls.clear()
r = index.handler(ev([
    ("NAME", "Иван"), ("PHONE", "+79001112233"), ("CONSENT", "1"), ("AGREE", "1"),
    ("TEAM_SIZE", "от 5 до 50"), ("TOOLS", "Битрикс24"), ("TOOLS", "1С"),
    ("LAUNCH", "в этом месяце"), ("INDUSTRY", "продажи"),
    ("COMPANY", "ООО Ромашка"), ("COMMENTS", "Нужна CRM и телефония"),
    ("UTM_CONTENT", "full-quiz"),
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
    r = index.handler(ev([("NAME", "123"), ("PHONE", bad), ("CONSENT", "1")]), None)
    assert r["statusCode"] == 302 and r["headers"]["Location"].endswith("?err=contact#lead-form"), (bad, r)
    assert not calls, bad
for good in ("+7 (900) 111-22-33", "89001112233", "9991112233", "user@mail.ru"):
    calls.clear()
    index.handler(ev([("NAME", "Иван"), ("PHONE", good), ("CONSENT", "1")],
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
    ("CONSENT_MAILING", "1"),
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
    ("UTM_CONTENT", "checklist"), ("COMMENTS", "Запрос: чек-лист"),
], headers={"X-Forwarded-For": "203.0.113.7"}), None)
f = calls["crm.lead.add"]
assert f["fields[EMAIL][0][VALUE]"] == "user@mail.ru", f
assert "fields[PHONE][0][VALUE]" not in f
af = act_fields()
assert af["E-mail"] == "user@mail.ru" and "Телефон" not in af

# 6. Реферер сквозь капчу: заголовок со своего домена игнорируется, hidden REF_ORIGIN побеждает.
calls.clear()
r = index.handler(ev([
    ("NAME", "Ольга"), ("PHONE", "+79001110000"), ("CONSENT", "1"),
    ("UTM_CONTENT", "popup"), ("REF_ORIGIN", "arwox.ru"),
], headers={"Referer": "https://forms.arwox.ru/", "X-Forwarded-For": "203.0.113.8"}), None)
assert "Реферер: arwox.ru" in calls["crm.lead.add"]["fields[SOURCE_DESCRIPTION]"]
assert calls["crm.activity.add"]["fields"]["PROVIDER_PARAMS"]["FORM"]["LINK"] == "https://arwox.ru/"
assert calls["userconsent.consent.add"]["URL"] == "https://arwox.ru"

print("PASS: все проверки прошли")
