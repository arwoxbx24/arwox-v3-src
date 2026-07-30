# Снапшот сайта arwox.ru (site78) — полная рабочая версия 2026-07-29

Зафиксировано после приёмки владельцем: формы ×3 (квиз/попап/футер) с валидацией
(pattern v-flag-safe + :user-invalid подсказки + подсветка галочек квиза),
невидимая SmartCaptcha, попап успеха без перезагрузки (checkbox-hack ok1),
дело-согласие CRM_WEBFORM + кликабельная запись в реестре согласий.

## Состав
- `block9116-content.html` — контент блока (снят с публичного 9120, С ОБЁРТКОЙ
  `<div id="b9116" …>` — перед восстановлением обёртку СНЯТЬ, пишется в ЧЕРНОВИК 9116)
- `cssblock-lid362.css` — CSSBLOCK страницы lid=362 (лимит 65535, тут 64819)
- `additional-fields-lid362.json` — все additional fields страницы (полный слепок)

## Откат на эту версию
```bash
cd "$(git rev-parse --show-toplevel)/site78-releases/2026-07-29"
python3 - <<'EOF'
import json, pathlib
BASE = pathlib.Path.cwd()  # equals dir set by cd above; valid in python3 - <<'EOF' heredoc (no __file__)
h = open(BASE / 'block9116-content.html').read()
w = '<div id="b9116" class="block-wrapper block-26-2-separator">'
n = 0
while h.startswith(w): h = h[len(w):]; n += 1
if n: h = h[:-6*n]
json.dump({'lid':362,'block':9116,'content':h}, open('/tmp/restore-block.json','w'), ensure_ascii=False)
json.dump({'lid':362,'fields':{'ADDITIONAL_FIELDS':{'CSSBLOCK_CODE':open(BASE / 'cssblock-lid362.css').read()}}},
          open('/tmp/restore-css.json','w'), ensure_ascii=False)
EOF
b24 landing.block.updatecontent --json-file /tmp/restore-block.json
b24 landing.landing.update --json-file /tmp/restore-css.json
b24 landing.landing.publication lid=362
```

Серверная часть этой версии — функция arwox-lead-form в этом же коммите
(`yc-serverless/functions/arwox-lead-form/`), деплой: `bash deploy.sh`.
