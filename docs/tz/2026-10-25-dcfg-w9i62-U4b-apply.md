# TZ dcfg-w9i62 U4b — one-off script: replace exactly one literal fragment in a large file

Why: U4 (direct edit of landing/site78/362/block-9116.draft.html) was refused by sdk-agent: "file larger than 200 KB". The lead runs a small script written by you instead.

FILE: docs/tz/2026-10-25-dcfg-w9i62-U4b-apply.sh

## The script (new file, bash, at most 20 lines)
Usage: `bash docs/tz/2026-10-25-dcfg-w9i62-U4b-apply.sh <target-file> <old-fragment-file> <new-fragment-file>`
1. `set -euo pipefail`; `export LC_ALL=C` (byte-exact, the texts are UTF-8 Cyrillic).
2. Read target with `IFS= read -r -d '' content < "$1" || true` (keeps every byte including a trailing newline or its absence). Read old and new fragments the same way, then strip one trailing "\n" from each fragment if present.
3. Count literal (not glob) occurrences of old in content using quoted pattern expansion (`"${content#*"$old"}"`). Exactly 1 → continue. 0 or ≥2 → print `apply: old fragment found <N> times, nothing written` to stderr, exit 1, target untouched.
4. Write `prefix + new + rest` back to the target with `printf '%s'` (no added newline), then print `apply: replaced 1, bytes <before> -> <after>`.
No other behavior, no options, no comments beyond one usage line.

## Done-check (the lead runs it)
- First run on the target: exit 0, line `apply: replaced 1`; `git diff --stat` shows only the target, 1 line changed.
- Second run with the same arguments: exit 1, `found 0 times`, target unchanged.
- `bash -n` on the script: rc 0.
