"""consent.py — ядро реестра доказуемого согласия ПДн (152-ФЗ).

Чистая логика: собрать квитанцию, подписать HMAC, сериализовать для реестра
(смарт-процесс 1094) и для файла-копии на Диск. БЕЗ сетевых вызовов —
всё детерминировано и тестируемо офлайн. Подключение к обработчику формы и
запись в B24/Диск — отдельными шагами (M6/M7), после подтверждения сайта.

Архитектура: см. /root/workspaces/projects/CONSENT-REGISTRY-ARCHITECTURE.md (v2).
Ключевые решения:
- HMAC на каждую квитанцию БЕЗ хеш-цепочки (§3.1) — нет гонок в stateless-функции.
- IP берёт обработчик из доверенного хопа шлюза и передаёт сюда (§4) — тут не парсим сырой XFF.
- ПД-минимизация: только то, что нужно для доказательства факта согласия.
"""
import base64
import hashlib
import hmac
import json
import os
import urllib.parse
import urllib.request
import uuid

SCHEMA_VERSION = "1"
REGISTRY_ENTITY_TYPE_ID = 1094  # смарт-процесс «Реестр согласий ПДн»


def sha256_hex(text):
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def build_receipt(*, lead_id, contact_value, server_time_utc, ip, user_agent,
                  page_url, consent_doc_url, consent_doc_version, consent_text,
                  submitted_data, fn_version, request_id, xff_chain=""):
    """Собрать квитанцию согласия. server_time_utc/ip — из доверенного контекста обработчика.
    submitted_data — dict отправленных полей (для хеша, сами ПД в квитанцию не дублируем)."""
    receipt = {
        "receipt_id": str(uuid.uuid4()),
        "schema_version": SCHEMA_VERSION,
        "lead_id": str(lead_id) if lead_id else "",
        "contact_id": "",  # дозаполняется после конвертации (§5.1)
        "consent": True,
        "consent_doc_url": consent_doc_url,
        "consent_doc_version": consent_doc_version,
        "consent_text_sha256": sha256_hex(consent_text),
        "server_time_utc": server_time_utc,  # ISO8601 c мс, из обработчика
        "ip": ip,                            # доверенный хоп (§4)
        "x_forwarded_for": xff_chain,        # контекст, НЕ доказательный IP
        "user_agent": user_agent,
        "page_url": page_url,
        "contact_value_sha256": sha256_hex(contact_value or ""),
        "submitted_data_sha256": sha256_hex(json.dumps(submitted_data, sort_keys=True, ensure_ascii=False)),
        "fn_version": fn_version,
        "request_id": request_id,
    }
    receipt["hmac_sha256"] = _sign(receipt, _hmac_key())
    return receipt


def _hmac_key():
    key = os.environ.get("CONSENT_HMAC_KEY", "")
    if not key:
        raise RuntimeError("CONSENT_HMAC_KEY не задан (secrets, не в git)")
    return key.encode("utf-8")


def _canonical(receipt):
    """Каноничная сериализация БЕЗ поля подписи — стабильна между вызовами."""
    body = {k: v for k, v in receipt.items() if k != "hmac_sha256"}
    return json.dumps(body, sort_keys=True, ensure_ascii=False, separators=(",", ":"))


def _sign(receipt, key):
    return hmac.new(key, _canonical(receipt).encode("utf-8"), hashlib.sha256).hexdigest()


def verify(receipt, key=None):
    """True если подпись цела. Любая правка полей → False."""
    key = key or _hmac_key()
    expected = _sign(receipt, key)
    return hmac.compare_digest(expected, receipt.get("hmac_sha256", ""))


def to_registry_fields(receipt):
    """Поля для crm.item.add в реестр 1094. xmlId=receipt_id (индекс/дедуп),
    title=человекочитаемая сводка. Полный JSON — копией на Диск (M7)."""
    title = "Согласие %s | лид %s | %s" % (
        receipt["receipt_id"][:8], receipt["lead_id"] or "—", receipt["server_time_utc"])
    return {"fields[title]": title[:250], "fields[xmlId]": receipt["receipt_id"]}


def to_json_bytes(receipt):
    """Полная квитанция для файла на Диск (авторитетная копия)."""
    return json.dumps(receipt, ensure_ascii=False, indent=2).encode("utf-8")


def _norm_ip(s):
    """Нормализовать адрес: убрать порт/скобки формата YC ([ip]:port, ipv4:port)."""
    s = (s or "").strip()
    if s.startswith("["):        # [ipv6]:port или [ipv4]:port
        return s[1:].split("]")[0]
    if s.count(":") == 1:        # ipv4:port
        return s.split(":")[0]
    return s                     # голый ipv4/ipv6


def extract_request_context(event):
    """Достать доверенный IP/UA/цепочку из HTTP-события (M4, §4).
    Доверенный IP = правый край X-Forwarded-For (ближайший хоп, добавленный шлюзом),
    а не левый (его подделывает клиент). Всю цепочку храним как контекст."""
    headers = {k.lower(): v for k, v in (event.get("headers") or {}).items()}
    xff = headers.get("x-forwarded-for", "")
    ip = xff.split(",")[-1].strip() if xff else ""
    ip = headers.get("x-real-remote-address", "") or ip  # YC отдаёт реальный адрес
    return {"ip": _norm_ip(ip), "user_agent": headers.get("user-agent", ""), "xff_chain": xff}


def backfill_contact_id(receipt, contact_id, key=None):
    """M8: после конвертации лид→контакт дозаписать contact_id и переподписать квитанцию."""
    r = dict(receipt)
    r["contact_id"] = str(contact_id)
    k = (key.encode("utf-8") if isinstance(key, str) else key) or _hmac_key()
    r["hmac_sha256"] = _sign(r, k)
    return r


def http_transport(webhook):
    """Транспорт к B24 через вебхук (urllib, без внешних зависимостей).
    В проде обработчик передаёт его в record_consent; в тестах — фейковый."""
    base = webhook.rstrip("/")

    def _call(method, params):
        data = urllib.parse.urlencode(params, doseq=True).encode()
        req = urllib.request.Request(base + "/" + method, data=data)
        with urllib.request.urlopen(req, timeout=30) as r:
            return json.loads(r.read())

    return _call


def record_consent(receipt, folder_id, transport):
    """Fail-open (§8.1): пишем квитанцию в реестр (СПА 1094) + копией на Диск.
    НИКОГДА не бросает — ошибки собираем в errors, чтобы сбой реестра не ронял лид.
    Возвращает {registry_id, file_id, errors}. errors!=[] → в очередь дозаписи."""
    out = {"registry_id": None, "file_id": None, "errors": []}
    try:
        params = {"entityTypeId": REGISTRY_ENTITY_TYPE_ID}
        params.update(to_registry_fields(receipt))
        resp = transport("crm.item.add", params)
        out["registry_id"] = ((resp.get("result") or {}).get("item") or {}).get("id")
        if not out["registry_id"]:
            out["errors"].append("registry:" + str(resp.get("error_description")))
    except Exception as e:  # сеть/таймаут/парсинг — не роняем
        out["errors"].append("registry:" + repr(e))
    try:
        name = "receipt-%s.json" % receipt["receipt_id"][:8]
        b64 = base64.b64encode(to_json_bytes(receipt)).decode()
        resp = transport("disk.folder.uploadfile",
                         {"id": folder_id, "data[NAME]": name,
                          "fileContent[0]": name, "fileContent[1]": b64})
        out["file_id"] = (resp.get("result") or {}).get("ID")
        if not out["file_id"]:
            out["errors"].append("disk:" + str(resp.get("error_description")))
    except Exception as e:
        out["errors"].append("disk:" + repr(e))
    return out


def _demo():
    os.environ.setdefault("CONSENT_HMAC_KEY", "test-key-not-for-prod")
    r = build_receipt(
        lead_id=2874, contact_value="+79261234500",
        server_time_utc="2026-07-22T16:30:00.123Z", ip="193.42.122.55",
        user_agent="Mozilla/5.0", page_url="https://arwox.ru/#contact",
        consent_doc_url="https://arwox.ru/docs/consent-v1", consent_doc_version="v1",
        consent_text="Я даю согласие на обработку персональных данных...",
        submitted_data={"NAME": "Демо", "PHONE": "+79261234500"},
        fn_version="abc1234", request_id="req-1", xff_chain="1.2.3.4, 193.42.122.55")
    # подпись валидна
    assert verify(r), "свежая квитанция должна проходить проверку"
    # подмена ловится
    tampered = dict(r); tampered["ip"] = "8.8.8.8"
    assert not verify(tampered), "подмена IP должна ломать подпись"
    tampered2 = dict(r); tampered2["consent"] = False
    assert not verify(tampered2), "подмена согласия должна ломать подпись"
    # индекс и файл
    rf = to_registry_fields(r)
    assert rf["fields[xmlId]"] == r["receipt_id"]
    assert to_json_bytes(r).startswith(b"{")
    # хеши детерминированы, но данные не хранятся в открытом виде
    assert "submitted_data_sha256" in r and len(r["submitted_data_sha256"]) == 64

    # M4: извлечение доверенного IP (правый край XFF), не левого-подделанного
    ctx = extract_request_context({"headers": {"X-Forwarded-For": "1.2.3.4, 5.6.7.8",
                                               "User-Agent": "UA/1"}})
    assert ctx["ip"] == "5.6.7.8", "доверенный IP = правый край XFF"
    assert ctx["user_agent"] == "UA/1"

    # M6/M7 fail-open: happy / сбой реестра / сбой транспорта — ни один не бросает
    calls = {"n": 0}
    def ok_transport(method, params):
        if method == "crm.item.add":
            return {"result": {"item": {"id": 777}}}
        return {"result": {"ID": 888}}
    res = record_consent(r, 56848, ok_transport)
    assert res["registry_id"] == 777 and res["file_id"] == 888 and not res["errors"]

    def reg_fail(method, params):
        if method == "crm.item.add":
            return {"error": "x", "error_description": "denied"}
        return {"result": {"ID": 999}}
    res2 = record_consent(r, 56848, reg_fail)
    assert res2["registry_id"] is None and res2["file_id"] == 999
    assert any("registry" in e for e in res2["errors"]), "сбой реестра фиксируется, но не роняет"

    def boom(method, params):
        raise RuntimeError("network down")
    res3 = record_consent(r, 56848, boom)  # НЕ должно бросить
    assert res3["registry_id"] is None and res3["file_id"] is None and len(res3["errors"]) == 2

    print("consent.py self-test OK:", r["receipt_id"])


if __name__ == "__main__":
    _demo()
