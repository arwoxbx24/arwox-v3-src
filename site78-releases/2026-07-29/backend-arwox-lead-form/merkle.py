"""merkle.py — суточный Merkle-анкер реестра согласий (M10, §3.1).

Раз в сутки берём HMAC-подписи всех квитанций за день → строим Merkle-корень →
пишем «якорную» запись (в реестр + на Диск). Подделка ЛЮБОЙ квитанции задним
числом меняет корень дня → якорь перестаёт сходиться. Якоря связаны по дням
(prev_anchor_hash) — последовательная суточная задача, гонок нет.

Только stdlib (hashlib/json) — без внешних зависимостей.
Шифрование реплики (AES-256-GCM) — отдельный под-шаг M10b: требует решения о
библиотеке (cryptography/PyNaCl) и цели РФ-хранилища; здесь только анкеринг.
"""
import hashlib
import json


def _sha(b):
    return hashlib.sha256(b).hexdigest()


def merkle_root(leaf_hexes):
    """Merkle-корень из списка hex-хешей (HMAC квитанций). Нечётный уровень —
    последний элемент дублируется (классическая схема). Пустой день → хеш пустоты."""
    if not leaf_hexes:
        return _sha(b"")
    level = [bytes.fromhex(x) for x in leaf_hexes]
    while len(level) > 1:
        nxt = []
        for i in range(0, len(level), 2):
            a = level[i]
            b = level[i + 1] if i + 1 < len(level) else level[i]  # дублируем последний
            nxt.append(hashlib.sha256(a + b).digest())
        level = nxt
    return level[0].hex()


def build_daily_anchor(day, receipt_hmacs, prev_anchor_hash=""):
    """Якорь дня. day — 'YYYY-MM-DD'. receipt_hmacs — hmac_sha256 всех квитанций дня.
    Сортируем для детерминизма (порядок прихода заявок роли не играет)."""
    leaves = sorted(receipt_hmacs)
    anchor = {
        "type": "daily_anchor",
        "day": day,
        "count": len(leaves),
        "merkle_root": merkle_root(leaves),
        "prev_anchor_hash": prev_anchor_hash,
    }
    anchor["anchor_hash"] = _sha(json.dumps(anchor, sort_keys=True, ensure_ascii=False).encode())
    return anchor


def verify_anchor(anchor, receipt_hmacs):
    """True, если корень и хеш якоря сходятся с набором квитанций. Любая правка → False."""
    body = {k: v for k, v in anchor.items() if k != "anchor_hash"}
    if body.get("merkle_root") != merkle_root(sorted(receipt_hmacs)):
        return False
    recomputed = _sha(json.dumps(body, sort_keys=True, ensure_ascii=False).encode())
    return recomputed == anchor.get("anchor_hash")


def _demo():
    hmacs = [_sha(b"r%d" % i) for i in range(5)]  # 5 «квитанций»
    a1 = build_daily_anchor("2026-07-22", hmacs, prev_anchor_hash="")
    assert verify_anchor(a1, hmacs), "свежий якорь должен сходиться"
    # порядок квитанций не влияет
    assert verify_anchor(a1, list(reversed(hmacs))), "корень не зависит от порядка"
    # подмена одной квитанции ломает якорь
    bad = list(hmacs); bad[2] = _sha(b"TAMPERED")
    assert not verify_anchor(a1, bad), "подделка квитанции должна ломать якорь"
    # цепочка дней
    a2 = build_daily_anchor("2026-07-23", [_sha(b"x")], prev_anchor_hash=a1["anchor_hash"])
    assert a2["prev_anchor_hash"] == a1["anchor_hash"], "якоря связаны по дням"
    assert verify_anchor(a2, [_sha(b"x")])
    # пустой день не падает
    a0 = build_daily_anchor("2026-07-21", [])
    assert a0["count"] == 0 and verify_anchor(a0, [])
    print("merkle.py self-test OK: root=%s..." % a1["merkle_root"][:16])


if __name__ == "__main__":
    _demo()
