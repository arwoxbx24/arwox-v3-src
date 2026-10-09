---
title: "Beget DNS API: METHOD_FAILED для поддомена, заведённого только записью зоны"
module: forms-failover
date: 2026-10-09
problem_type: integration_issue
component: infrastructure
severity: high
symptoms:
  - "forms-failover/dns-switch.sh status → api_error METHOD_FAILED для forms.arwox.ru, для forms-test.arwox.ru → normal"
  - "dns/getData {fqdn: forms.arwox.ru} → answer.errors METHOD_FAILED 'Failed to get DNS records', хотя dig @ns1.beget.ru отдаёт CNAME"
root_cause: incomplete_setup
resolution_type: environment_setup
tags: [beget, dns, method-failed, addsubdomainvirtual, failover]
---

## Problem
Автопереключение боевого `forms.arwox.ru` на резерв не могло сработать: Beget API не читал и не менял запись поддомена. Тестовый `forms-test.arwox.ru` при этом работал.

## Root cause
`forms.arwox.ru` существовал только как запись в зоне, без объекта поддомена: `domain/getSubdomainList` его не содержал, а `forms-test` был заведён объектом через `addSubdomainVirtual`. По наблюдению этой сессии, `dns/getData` и `dns/changeRecords` работают только с объектами поддоменов. Документация Beget этого не описывает ([функции доменов](https://beget.com/ru/kb/api/funkczii-dlya-raboty-s-domenami), [функции DNS](https://beget.com/ru/kb/api/funkczii-upravleniya-dns)).

## Solution
Снимок → создание объекта → немедленный возврат прежней записи → проверка:

```bash
tools/bin/beget-api dns/getData '{"fqdn":"arwox.ru"}'          # снимок зоны
tools/bin/beget-api domain/getSubdomainList '{}'                # снимок поддоменов
tools/bin/beget-api domain/addSubdomainVirtual '{"subdomain":"forms","domain_id":14289239}'
tools/bin/beget-api dns/changeRecords '{"fqdn":"forms.arwox.ru","records":{"CNAME":[{"priority":10,"value":"<прежний CNAME>."}]}}'
dig +short forms.arwox.ru @ns1.beget.ru                         # прежний CNAME
forms-failover/dns-switch.sh status                             # normal
```

Результат 09.10: объект id 14762860, `status` → `normal`, форма → 302. Сторож с `DNS_SWITCH` включён в PR arwoxbx24/tools#143.

## Prevention
- Новый поддомен, которым будет управлять API, заводить через `addSubdomainVirtual`, а не записью в панели зоны.
- Между `addSubdomainVirtual` и `changeRecords` не делать пауз: что новый объект пишет в DNS по умолчанию, не задокументировано.
- Сертификат резерва проверять командой `curl --resolve <fqdn>:443:<ip>`; rc 35 значит, что сертификата нет. `openssl s_client` без `-verify_hostname` возвращает `Verify return code: 0 (ok)` и на сертификате другого имени — в этой сессии он так и ввёл в заблуждение.
