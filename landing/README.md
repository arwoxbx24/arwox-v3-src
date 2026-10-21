# Лендинг arwox.ru в файлах

Код страниц Битрикс24 хранится здесь и выкладывается отсюда на сайт. Источник правды — эти файлы, не редактор Битрикс24.

| Каталог | Сайт Битрикс24 | Адрес | Страницы |
|---|---|---|---|
| `site78/` | 78, prod | https://arwox.ru | 13: lid 362 (главная), 374–396 |
| `site80/` | 80, dev (noindex) | https://b24-w7skc9.bitrix24site.ru | lid 368 (dev-главная), 372 (только снимок) |

Файлы страницы `site<SITE>/<lid>/`:
- `block-<id>.draft.html` — черновой блок (`landing.block.getlist`, `edit_mode=1`), как вернул Битрикс24, вместе с обёрткой `<div id="b<id>" …>`;
- `block-<id>.public.html` — опубликованный блок (`edit_mode=0`), id у него свой;
- `additional-fields.json` — `landing.landing.getadditionalfields` целиком;
- `cssblock.css` — поле `CSSBLOCK_CODE` из него (CSS страницы), для правок и диффа.

## Команды

```bash
bash landing/b24-landing.sh snapshot 78 landing/site78   # снять сайт в файлы (заменяет каталог)
bash landing/b24-landing.sh verify 78 landing/site78     # сверить живой сайт с файлами: ok=N failed=M
bash landing/b24-landing-test.sh                         # тесты скрипта (заглушка b24, без сети)
```

Правило: до любой записи в Битрикс24 живое состояние снято сюда и `verify` даёт `failed=0`. Правка в редакторе Битрикс24 мимо репозитория обнаруживается `verify` и сначала снимается в git.

Снимок 21.10.2026: `verify 78` → `ok=64 failed=0`, `verify 80` → `ok=8 failed=0`; CSS lid 362 — 64 723 символа.
