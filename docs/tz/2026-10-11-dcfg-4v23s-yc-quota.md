# ТЗ dcfg-4v23s — architecture.md: квоты Yandex Cloud и инцидент ru-central1-b

Уровень L1 (только MD). Атом bd `dcfg-4v23s`.

## U1. Раздел «Yandex Cloud: квоты и зоны» в architecture.md
- Цель: следующий агент видит, что ручное управление квотами Яндекса на ВМ и диски (письмо Яндекса 11.10.2026) схему заявок не задевает, и знает, где смотреть квоты и как подать запрос на увеличение.
- Файлы: `architecture.md`, этот ТЗ.
- Вне цели: код, сторож, DNS, pm2, вызовы Yandex API.
- Критерий: `grep -c -E 'quota-manager quota-limit|QuotaRequest|ru-central1-b|только serverless' architecture.md` → 4; `git diff --name-only origin/main` → только `architecture.md` и этот файл.

## Паспорт источников
- https://yandex.cloud/ru/docs/quota-manager/quickstart — «Воспользуйтесь методом REST API Create для ресурса QuotaRequest»; «Обратитесь в техническую поддержку и опишите, какие потребляемые квоты нужно увеличить и на сколько».
- https://yandex.cloud/ru/docs/cli/release-notes — «Добавлена группа команд `yc quota-manager quota-limit` для просмотра лимитов квот»; «Добавлена группа команд `yc quota-manager quota-request` для управления запросами квот».
- https://yandex.cloud/ru/docs/compute/concepts/limits — «Квоты — организационные ограничения, которые можно изменить по запросу в техническую поддержку. Лимиты — технические ограничения… Изменить лимиты невозможно».
- `architecture.md:11` — на Яндексе только API Gateway `arwox-forms-gw` и Cloud Function.
- Письмо Яндекса 11.10.2026 (вставлено владельцем): зона ru-central1-b недоступна; ручное управление квотами на вычислительные ресурсы и диски.
