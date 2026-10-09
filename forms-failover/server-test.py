import http.client
import contextlib
import io
import json
import os
import socket
import stat
import subprocess
import sys
import tempfile
import time
import threading
from pathlib import Path

ROOT = Path(__file__).parent


def request(port, method, path, body=None, headers=None):
    client = http.client.HTTPConnection("127.0.0.1", port, timeout=1)
    client.request(method, path, body, headers or {})
    response = client.getresponse()
    result = response.status, dict(response.getheaders()), response.read()
    client.close()
    return result


with tempfile.TemporaryDirectory() as temp:
    Path(temp, "index.py").write_text(
        "import json\n"
        "def handler(event, _):\n"
        " if event['path'] == '/boom': raise RuntimeError()\n"
        " return {'statusCode': 302, 'headers': {'Location': '/ok'}, 'body': json.dumps(event)}\n"
    )
    probe = socket.socket()
    probe.bind(("127.0.0.1", 0))
    port = probe.getsockname()[1]
    probe.close()
    env = os.environ | {"FORMS_HANDLER_DIR": temp, "FORMS_BACKUP_BIND": "127.0.0.1", "FORMS_BACKUP_PORT": str(port)}
    process = subprocess.Popen([sys.executable, ROOT / "server.py"], env=env, stderr=subprocess.DEVNULL)
    try:
        for _ in range(20):
            try:
                status, headers, body = request(port, "GET", "/?a=1")
                break
            except ConnectionRefusedError:
                time.sleep(.05)
        else:
            raise AssertionError("server did not start")
        event = json.loads(body)
        assert status == 302 and headers["Location"] == "/ok"
        assert event["httpMethod"] == "GET" and event["queryStringParameters"]["a"] == "1"
        status, _, body = request(port, "POST", "/", "NAME=x&PHONE=1", {"X-Real-IP": "9.9.9.9", "X-Real-Remote-Address": "6.6.6.6"})
        event = json.loads(body)
        assert status == 302 and "NAME=x" in event["body"]
        assert event["headers"]["X-Real-Remote-Address"] == "9.9.9.9"
        assert request(port, "GET", "/boom")[0] == 502
        print("PASS 3/3")
    finally:
        process.terminate()
        process.wait()


NOTE = "Форма была отправлена во время сбоя при резервном переключении"
os.environ["FORMS_HANDLER_DIR"] = str(ROOT.parent / "site78-releases/2026-07-29/backend-arwox-lead-form")
os.environ["WEBHOOK_URL"] = "https://example.invalid/rest/1/x"
os.environ.pop("LEAD_FAILOVER_NOTE", None)
os.environ.pop("LEAD_SPOOL_DIR", None)
import server  # noqa: E402

assert os.environ["LEAD_SPOOL_DIR"] == "/var/lib/forms-backup/spool"
spool_thread = next(t for t in threading.enumerate() if t.name == "lead-spool")
assert spool_thread.daemon

calls = {}


def fake_call(method, fields, **_):
    calls[method] = fields
    return {"result": 42}


server.index.call_b24 = fake_call


def submit():
    calls.clear()
    server.index.handler({
        "httpMethod": "POST",
        "body": "NAME=Ivan&PHONE=%2B79001112233&CONSENT=1&COMMENTS=%D0%9C%D0%B0%D1%80%D0%BA%D0%B5%D1%80+%D1%84%D0%BE%D1%80%D0%BC%D1%8B",
        "isBase64Encoded": False,
    }, None)
    return calls["crm.lead.add"]["fields[COMMENTS]"]


assert submit() == f"{NOTE}\nМаркер формы"
os.environ.pop("LEAD_FAILOVER_NOTE", None)
assert submit() == "Маркер формы"
print("PASS 6/6")


PHONE = "+79001112233"


def lead_event():
    return {
        "httpMethod": "POST",
        "headers": {"X-Real-Remote-Address": "203.0.113.9", "User-Agent": "spool-test"},
        "body": "NAME=Ivan&PHONE=%2B79001112233&CONSENT=1&COMMENTS=queue-test",
        "isBase64Encoded": False,
    }


def spool_item(created=None, attempts=0):
    return {
        "fields": {"fields[TITLE]": "queue test", "fields[COMMENTS]": f"{NOTE}\nqueue-test"},
        "ctx": {
            "ip": "203.0.113.9", "user_agent": "spool-test", "created_at": "2026-10-09T12:00:00",
            "ref_origin": "arwox.ru", "form_content": "full-quiz", "name": "Ivan", "contact": PHONE,
            "company": "", "industry": "", "team_size": "", "tools": [], "launch": "",
            "comments": "queue-test", "consent_mailing": False,
        },
        "attempts": attempts,
        "created": time.time() if created is None else created,
    }


with tempfile.TemporaryDirectory() as temp:
    spool = Path(temp, "spool")
    os.environ["LEAD_SPOOL_DIR"] = str(spool)
    os.environ["LEAD_FAILOVER_NOTE"] = NOTE
    calls.clear()

    def transient_call(method, fields, **_):
        calls[method] = fields
        return ({}, "transient") if method == "crm.lead.add" else {"result": 42}

    server.index.call_b24 = transient_call
    stderr = io.StringIO()
    with contextlib.redirect_stderr(stderr):
        response = server.index.handler(lead_event(), None)
    queued = list(spool.glob("*.json"))
    assert response["headers"]["Location"].endswith("?ok=1#sent")
    assert len(queued) == 1 and stat.S_IMODE(queued[0].stat().st_mode) == 0o600
    assert stat.S_IMODE(spool.stat().st_mode) == 0o700
    assert PHONE not in stderr.getvalue()

    def content_call(method, fields, **_):
        return ({}, "content") if method == "crm.lead.add" else {"result": 42}

    server.index.call_b24 = content_call
    response = server.index.handler(lead_event(), None)
    assert response["headers"]["Location"].endswith("?err=server#contact")
    assert len(list(spool.glob("*.json"))) == 1

    queued[0].unlink()
    delivered = spool_item()
    queued_path = spool / "delivered.json"
    queued_path.write_text(json.dumps(delivered))
    calls.clear()
    server.index.call_b24 = fake_call
    server.index.drain_spool(str(spool))
    assert not queued_path.exists()
    assert calls["crm.lead.add"]["fields[COMMENTS]"].startswith(NOTE)
    assert calls["crm.activity.add"]["fields"]["START_TIME"] == "2026-10-09T12:00:00"
    assert calls["userconsent.consent.add"]["IP"] == "203.0.113.9"

    retry_path = spool / "retry.json"
    retry_path.write_text(json.dumps(spool_item()))
    server.index.call_b24 = transient_call
    server.index.drain_spool(str(spool))
    assert json.loads(retry_path.read_text())["attempts"] == 1
    assert not list(spool.glob("*.inflight"))

    old_path = spool / "old.json"
    old_path.write_text(json.dumps(spool_item(created=time.time() - 86401)))
    server.index.drain_spool(str(spool), now=time.time())
    assert (spool / "failed" / "old.json").exists()

    bad_path = spool / "broken.json"
    valid_path = spool / "valid.json"
    bad_path.write_text("{")
    valid_path.write_text(json.dumps(spool_item()))
    server.index.call_b24 = fake_call
    server.index.drain_spool(str(spool))
    assert (spool / "failed" / "broken.json").exists() and not valid_path.exists()

    for n in range(500):
        Path(spool, f"full-{n}.json").write_text("{}")
    server.index.call_b24 = transient_call
    response = server.index.handler(lead_event(), None)
    assert response["headers"]["Location"].endswith("?err=server#contact")
    assert len(list(spool.glob("*.json"))) == 500

    os.environ.pop("LEAD_SPOOL_DIR", None)
    response = server.index.handler(lead_event(), None)
    assert response["headers"]["Location"].endswith("?err=server#contact")
    assert len(list(spool.glob("*.json"))) == 500

print("PASS 15/15")
