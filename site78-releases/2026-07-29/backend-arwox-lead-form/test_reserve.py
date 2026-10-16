# -*- coding: utf-8 -*-
"""Резерв (U1): не принятая CRM заявка (и не в спуле) → полный объект в бакет-резерв. Запуск: env WEBHOOK_URL=https://example/rest/1/x python3 -B test_reserve.py"""
import contextlib, io, json, os, tempfile
import urllib.error, urllib.parse

os.environ.setdefault("WEBHOOK_URL", "https://example/rest/1/x")
import index  # noqa: E402

RESP = {"crm.lead.add": {}}  # содержательный отказ CRM (безключевой ответ)
calls = {}
def fake_call(m, f, **kw): calls[m] = f; return RESP[m] if m in RESP else {"result": 42}
index.call_b24 = fake_call
index._captcha_ok = lambda token, ip: "ok"  # капча вне сценария (как в test_journal.py)
for _env, _attr in (("SMARTCAPTCHA_SITEKEY", "CAPTCHA_SITEKEY"), ("SMARTCAPTCHA_SECRET", "CAPTCHA_SECRET")):
    os.environ[_env] = "test"
    setattr(index, _attr, "test")

REQS = []
def stub_open(req, **kw):
    REQS.append(req)
    return io.BytesIO(b"")
_CANON = "__CANON_URLOPEN__"
g = index.urllib.request  # один общий модуль — замена видна index.py (приём из test_lead.py)
setattr(g, _CANON, g.urlopen)
g.urlopen = stub_open

def run(params, context):
    out = io.StringIO()
    with contextlib.redirect_stdout(out):
        r = index.handler({"httpMethod": "POST", "body": urllib.parse.urlencode(params),
                           "isBase64Encoded": False}, context)
    evts = [json.loads(l) for l in out.getvalue().splitlines() if l.strip().startswith("{")]
    return r, evts, out.getvalue()

_BASE = [("NAME", "Иван Резерв"), ("PHONE", "+79001110999"), ("CONSENT", "1"),
         ("COMMENTS", "резервный комментарий"), ("smart-token", "t")]

class _IContext: token = {"access_token": "TEST-IAM-XYZ"}  # имитация context.token рантайма

index.RESERVE_BUCKET = os.environ["RESERVE_BUCKET"] = "bkt-test"
# R-a: контентный отказ CRM → ровно один PUT, 302 успеха, этап reserved, без ПДн и токена.
r, evts, out = run(_BASE, _IContext)
rid = next(e["request_id"] for e in evts)
assert r["statusCode"] == 302 and r["headers"]["Location"].endswith("?ok=1#sent"), r
assert len(REQS) == 1, len(REQS)
u = REQS[0]
assert u.full_url == f"https://storage.yandexcloud.net/bkt-test/reserve/{rid}.json", u.full_url
assert u.get_header("Authorization") == "Bearer TEST-IAM-XYZ", dict(u.headers)
body = json.loads(u.data.decode("utf-8"))
assert set(body) == {"request_id", "created", "fields", "ctx"} and body["request_id"] == rid, body
assert body["fields"] == calls["crm.lead.add"] and "t0" not in body["ctx"] and "rid" not in body["ctx"], body
assert '"stage": "reserved"' in out and "Иван Резерв" not in out and "+79001110999" not in out, out
assert "резервный комментарий" not in out and "TEST-IAM-XYZ" not in out, out
# R-b: PUT отвечает HTTP 500 → этап reserve_error (только класс ошибки), прежний 302 ошибки.
def failing_open(req, **kw):
    REQS.append(req)
    raise urllib.error.HTTPError(req.full_url, 500, "boom", {}, None)
g.urlopen = failing_open
base = len(REQS)
r, evts, out = run(_BASE, _IContext)
assert r["statusCode"] == 302 and r["headers"]["Location"].endswith("?err=server#contact"), r
assert len(REQS) - base == 1, len(REQS)
sev = [e for e in evts if e["stage"] == "reserve_error"][0]
assert sev["error"] == "HTTPError" and sev["message"] == "Request was not saved to reserve.", sev
assert "TEST-IAM-XYZ" not in out and "storage.yandexcloud.net" not in out
g.urlopen = stub_open
# R-c: context=None → токена нет, urlopen не вызывается; R-d: пустой RESERVE_BUCKET → reserve_disabled.
for token_ctx, expect in ((None, "no_iam_token"), ("no-bucket", "reserve_disabled")):
    if token_ctx == "no-bucket":
        index.RESERVE_BUCKET = os.environ["RESERVE_BUCKET"] = ""
    base = len(REQS)
    r, evts, _ = run(_BASE, _IContext if token_ctx == "no-bucket" else None)
    index.RESERVE_BUCKET = os.environ["RESERVE_BUCKET"] = "bkt-test"
    assert len(REQS) - base == 0 and any(
        e["stage"] == "reserve_error" and e["error"] == expect for e in evts), expect
    assert r["statusCode"] == 302 and r["headers"]["Location"].endswith("?err=server#contact"), r
# R-e: transient-ошибка при заданном спуле → заявка уходит только в спул, ноль PUT (нет двойной записи).
RESP["crm.lead.add"] = ({}, "transient")
with tempfile.TemporaryDirectory() as tmp:
    os.environ["LEAD_SPOOL_DIR"] = tmp; base = len(REQS)
    r, evts, _ = run(_BASE, _IContext)
    spooled = bool(list(__import__("pathlib").Path(tmp).glob("*.json")))
os.environ.pop("LEAD_SPOOL_DIR", None)
RESP["crm.lead.add"] = {}
g.urlopen = getattr(g, _CANON)
delattr(g, _CANON)
assert r["statusCode"] == 302 and r["headers"]["Location"].endswith("?ok=1#sent"), r
assert len(REQS) - base == 0 and spooled, (len(REQS), base, spooled)
assert not any(e["stage"] == "reserved" for e in evts), evts
# R-f: context.token — не dict (строка «x») → пустой токен → no_iam_token; urlopen не вызывается, редирект ошибки.
g.urlopen = stub_open
base = len(REQS)
r, evts, _ = run(_BASE, type("StrCtx", (), {"token": "x"}))
assert r["statusCode"] == 302 and r["headers"]["Location"].endswith("?err=server#contact"), r
assert len(REQS) - base == 0 and any(
    e["stage"] == "reserve_error" and e["error"] == "no_iam_token" for e in evts), evts
# CR-T-FR6: страница капчи с ошибкой — запасной контакт (телефон сайта).
page = index._captcha_page({"NAME": ["Иван"], "PHONE": ["+79001112233"]}, error=True)["body"]
assert "tel:+79287051199" in page and "+7 928 705-11-99" in page, page
# CR-T-FR5 (a): проба резерва — WEBHOOK=crm.invalid + smart-token=probe-reserve.
# _captcha_ok пропускается, отказ CRM → reserve (один PUT), ответ 200 JSON с журналом без ПДн.
_saved_webhook = index.WEBHOOK
index.WEBHOOK = "https://crm.invalid"
_captcha_calls = []
index._captcha_ok = lambda token, ip: _captcha_calls.append(token)
index.call_b24 = fake_call  # crm.lead.add → {} (содержательный отказ CRM)
index.RESERVE_BUCKET = os.environ["RESERVE_BUCKET"] = "bkt-test"
base = len(REQS)
r, evts, out = run([("NAME", "Иван Проба"), ("PHONE", "+79001110999"), ("CONSENT", "1"),
                    ("smart-token", "probe-reserve")], _IContext)
assert r["statusCode"] == 200 and r["headers"]["Content-Type"] == "application/json", r
body = json.loads(r["body"])
assert set(body) == {"request_id", "journal"}, body
assert len(body["journal"]) == len(evts) and len({e["request_id"] for e in body["journal"]}) == 1, body
assert body["request_id"] == body["journal"][0]["request_id"], body
assert any(e["stage"] == "reserved" for e in body["journal"]), body["journal"]
assert "captcha=probe" in out and not _captcha_calls, (_captcha_calls, out)
assert "Иван Проба" not in r["body"] and "+79001110999" not in r["body"], r["body"]
assert len(REQS) - base == 1, len(REQS)
# CR-T-FR5 (b): реальный WEBHOOK — маркер probe-reserve не срабатывает, токен идёт через _captcha_ok.
index.WEBHOOK = "https://example/rest/1/x"
_captcha_calls = []
index._captcha_ok = lambda token, ip: _captcha_calls.append(token) or "ok"
index.call_b24 = lambda m, f, **kw: {"result": 42}
base = len(REQS)
r, _, _ = run([("NAME", "Иван Норма"), ("PHONE", "+79001110999"), ("CONSENT", "1"),
               ("smart-token", "probe-reserve")], _IContext)
assert r["statusCode"] == 302 and r["headers"]["Location"].endswith("?ok=1#sent"), r
assert _captcha_calls == ["probe-reserve"], _captcha_calls
assert len(REQS) - base == 0, len(REQS)
index.WEBHOOK = _saved_webhook
print("PASS: reserve")
