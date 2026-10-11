# ТЗ dcfg-ykikn — сторож форм: таймаут на вызовы yc

Разведка — repowise (индекс arwox-v3-src свежий, HEAD 16856bc); индекс: repowise/CBM проверен.
Worktree: `/root/workspaces/projects/arwox-v3-src/.worktrees/claude/dcfg-ykikn` (ветка `claude/dcfg-ykikn-yc-timeout`). Править только здесь.

## Проблема (факты, 11.10)
- `forms-failover/forms-gw-guard.sh:267` `yc serverless api-gateway get`, `:270` `yc serverless api-gateway resume`, `:334` `yc iam create-token` — без ограничения времени. `grep -nE 'timeout|max-time'` → только curl.
- Сторож: pm2 cron `* * * * *`, `flock -n` (`:258-262`). Зависший yc держит lock → следующий запуск пишет `already running` и не считает сбой. Прод-лог 11.10 после деплоя: 4 таких минуты (10:32, 13:04, 14:46, 14:52 UTC).

## U1. Таймаут (только `forms-failover/forms-gw-guard.sh`)
- Рядом с `GUARD_FALL_N`/`GUARD_RISE_N` (`:18-19`): `GUARD_YC_TIMEOUT="${GUARD_YC_TIMEOUT:-15}"`.
- Три вызова yc (`:267`, `:270`, `:334`) — префикс `timeout "$GUARD_YC_TIMEOUT"` (GNU coreutils 9.4 установлен). Больше ничего не менять: rc≠0 (в т.ч. 124) уже ведёт в существующие ветки `resume failed` / пустой `IAM` — сверить, что пустой IAM на `:335+` не ломает запуск.
- Добавить `timeout` в список проверки инструментов `:244` (`for tool in yc jq curl flock awk timeout`).

## U2. Тест (`forms-failover/forms-gw-guard-test.sh`, добавить кейс 40 к существующим 39)
- В заглушку yc (`:146-171`): если существует файл `$GUARD_TEST_TMP/yc-hang` — `sleep 30` перед ответом.
- case40: тело формы «is stopped and cannot be used» (как в существующих кейсах stopped), `touch yc-hang`, `GUARD_YC_TIMEOUT=1`, `DNS_SWITCH`-заглушка как в соседних кейсах. Запуск сторожа обёрнут в `timeout 20`. Проверки: rc сторожа ≠ 124 от внешнего timeout (запуск завершился сам, < 20 с), в логе `resume failed`, `fallback_failures` в state = 1.
- Итоговые строки `PASS %d/39` / `FAIL %d/39` (`:774`, `:777`) и цикл кейсов → 40.
- Тест-first: сначала кейс 40 без U1 — показать FAIL (вывод), затем U1 — PASS.

## Угрозы (prod §3) и откат (prod §5)
- Угрозы: новых входов, секретов, прав нет; env-переменная читается как число для `timeout` — значение задаёт только ecosystem (доверенный). Риск: слишком малый таймаут → ложный `resume failed` при живом Yandex → +1 к счётчику сбоев; 15 с > обычного ответа yc.
- Откат: `git revert` коммита атома; состояние сторожа не мигрирует.

## Запреты
Не трогать: `dns-switch.sh`, `index.py`, `server.py`, `/root/workspaces/tools/ecosystem.config.js`, `secrets/`, `.env`, pm2 (никаких restart), боевой DNS, реальные вызовы yc. Без коммита (коммит делает ship-post). Правки только в двух файлах выше.

## Готово, когда
1. `grep -nc 'timeout "$GUARD_YC_TIMEOUT" yc' forms-failover/forms-gw-guard.sh` → 3.
2. `bash -n forms-failover/forms-gw-guard.sh` rc 0.
3. `bash forms-failover/forms-gw-guard-test.sh | tail -1` → `PASS 40/40`.
4. `git -C <worktree> status --porcelain` → только два файла выше и этот ТЗ.
