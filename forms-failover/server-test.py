import http.client
import json
import os
import socket
import subprocess
import sys
import tempfile
import time
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
import server  # noqa: E402

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
print("PASS 5/5")
