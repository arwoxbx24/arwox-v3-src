import json, os, re, urllib.parse
os.environ.setdefault("WEBHOOK_URL", "https://example/rest/1/x")
import index
calls = {}
def fake_call(m, f, **kw):
    calls[m] = f; return {"result": 42}
index.call_b24 = fake_call
_LINES = []
def cp(*a, **kw):
    _LINES.append(a[0] if a else "")
def ev(p, headers=None):
    return {"httpMethod": "POST", "body": urllib.parse.urlencode(p), "isBase64Encoded": False, "headers": headers or {}}
import builtins; rp = builtins.print; builtins.print = cp
_LINES.clear(); calls.clear()
index.handler(ev([("NAME", "Иван"), ("PHONE", "+79001112233"), ("EMAIL", "ivan@example.test"), ("COMMENTS", "свободный текст"), ("CONSENT", "1"), ("UTM_CONTENT", "full-quiz")]), None)
builtins.print = rp; evts = [json.loads(l) for l in _LINES if l.strip()]
assert len(evts) >= 3
rids = {e["request_id"] for e in evts}; assert len(rids) == 1
for pii in ("Иван", "+79001112233", "ivan@example.test", "свободный текст"):
    assert pii not in json.dumps(evts, ensure_ascii=False)
ss = [e["stage"] for e in evts]; assert ss[0] == "received"
assert ss[-1] in ("b24_lead_ok", "b24_consent_ok")
for e in evts:
    assert "timestamp" in e and "latency_ms" in e
e0 = evts[0]; assert e0["has_name"] and e0["has_phone"] and e0["has_consent"] and e0["has_email"]
assert "form" in e0; assert re.fullmatch(r"[a-f0-9-]{32,36}", next(iter(rids)))
_LINES.clear(); builtins.print = cp
index.handler(ev([("NAME", "Иван"), ("PHONE", "+79001112233"), ("CONSENT", "1"), ("UTM_CONTENT", "untrusted_form_leaked=True")]), None)
builtins.print = rp
assert json.loads(_LINES[0])["form"] == "unknown"
_LINES.clear(); builtins.print = cp
def broken_call(m, f, **kw):
    calls[m] = f; return {}
index.call_b24 = broken_call
index.handler(ev([("NAME", "Test"), ("PHONE", "+79001112233"), ("CONSENT", "1")]), None)
builtins.print = rp
fev = [json.loads(l) for l in _LINES if l.strip()]
assert any(e["stage"] == "b24_error" for e in fev)
for e in fev:
    if e["stage"] == "b24_error":
        assert "error" in e and "exception" not in json.dumps(e).lower()
_LINES.clear(); builtins.print = cp; index.call_b24 = fake_call
index.handler(ev([("NAME", "x"), ("PHONE", "123"), ("CONSENT", "1")]), None)
builtins.print = rp
rev = [json.loads(l) for l in _LINES if l.strip()]
assert any(e["stage"] == "rejected" for e in rev)
_LINES.clear(); builtins.print = cp
index.call_b24 = lambda m, f, **kw: {} if m == "userconsent.consent.add" else {"result": 42}
index.handler(ev([("NAME", "Иван"), ("PHONE", "+79001112233"), ("CONSENT", "1")], {"X-Forwarded-For": "203.0.113.1"}), None)
builtins.print = rp
cev = [json.loads(l) for l in _LINES if l.strip()]
assert not any(e["stage"] == "b24_consent_ok" for e in cev)
assert any(e.get("error") == "consent_add_failed" and e.get("message") == "Consent was not saved." for e in cev)
_LINES.clear(); builtins.print = cp; index.call_b24 = lambda m, f, **kw: {"result": 0} if m == "crm.lead.add" else {"result": 42}
r = index.handler(ev([("NAME", "Иван"), ("PHONE", "+79001112233"), ("CONSENT", "1")]), None); builtins.print = rp; zev = [json.loads(l) for l in _LINES if l.strip()]
assert r["headers"]["Location"].endswith("?err=server#contact"); assert not any(e["stage"] == "b24_lead_ok" for e in zev)
_LINES.clear(); builtins.print = cp; index.call_b24 = lambda m, f, **kw: {"result": 0} if m == "crm.activity.add" else {"result": 42}
index.handler(ev([("NAME", "Иван"), ("PHONE", "+79001112233"), ("CONSENT", "1")], {"X-Forwarded-For": "203.0.113.1"}), None); builtins.print = rp; zev = [json.loads(l) for l in _LINES if l.strip()]
assert not any(e["stage"] == "b24_consent_ok" for e in zev); assert any(e.get("error") == "consent_add_failed" for e in zev)
print("OK: журнал без ПДн прошёл")
