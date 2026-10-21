#!/usr/bin/env bash
# Landing pages of a Bitrix24 site <-> files in git. Reads REST via the installed `b24` CLI.
#   snapshot <site> <dir>  save every page of the site into <dir>/<lid>/ (replaces <dir>)
#   verify   <site> <dir>  re-read the site and compare with <dir> byte by byte
# Files per page: block-<id>.draft.html, block-<id>.public.html (getlist content as returned),
# additional-fields.json (getadditionalfields as returned), cssblock.css (its CSSBLOCK_CODE).
set -euo pipefail

usage() {
  printf 'usage: %s snapshot|verify <site-id> <dir>\n' "$(basename "$0")"
}

# fetch_site <site> <dir>: writes all pages into an existing empty <dir>; returns 1 on any error.
# Explicit `|| return 1`: set -e is off inside a function called from `if`.
fetch_site() {
  local site=$1 dir=$2 lid mode tag id lids ids
  # shortcut: one getList call, no pagination; fine while a site has <= 50 pages (now 13 and 2).
  b24 landing.landing.getList "params[filter][SITE_ID]=$site" 'params[select][]=ID' 'params[order][ID]=ASC' > "$dir/.pages.json" || return 1
  lids=$(jq -r '.[].ID' "$dir/.pages.json") || return 1
  [ -n "$lids" ] || { printf 'site %s: no pages\n' "$site" >&2; return 1; }
  for lid in $lids; do
    mkdir "$dir/$lid" || return 1
    for mode in 1 0; do
      if [ "$mode" = 1 ]; then tag=draft; else tag=public; fi
      b24 landing.block.getlist "lid=$lid" "params[edit_mode]=$mode" 'params[get_content]=1' > "$dir/.blocks.json" || return 1
      ids=$(jq -r '.[].id' "$dir/.blocks.json") || return 1
      for id in $ids; do
        jq -j --argjson id "$id" '.[] | select(.id == $id) | .content' "$dir/.blocks.json" > "$dir/$lid/block-$id.$tag.html" || return 1
      done
    done
    b24 landing.landing.getadditionalfields "lid=$lid" > "$dir/$lid/additional-fields.json" || return 1
    jq -j '.CSSBLOCK_CODE // ""' "$dir/$lid/additional-fields.json" > "$dir/$lid/cssblock.css" || return 1
  done
  rm -f "$dir/.pages.json" "$dir/.blocks.json"
}

snapshot() {
  local site=$1 dir=${2%/} tmp
  mkdir -p "$(dirname "$dir")"
  tmp=$(mktemp -d "$dir.tmp.XXXXXX")
  if ! fetch_site "$site" "$tmp"; then
    rm -rf "$tmp"
    printf 'snapshot site %s: b24 failed, nothing written\n' "$site" >&2
    return 1
  fi
  rm -rf "$dir"
  mv "$tmp" "$dir"
  printf 'snapshot site %s -> %s: pages=%s\n' "$site" "$dir" "$(find "$dir" -mindepth 1 -maxdepth 1 -type d | wc -l)"
}

verify() {
  local site=$1 dir=${2%/} tmp f okn=0 failn=0
  [ -d "$dir" ] || { printf 'verify: no snapshot dir %s\n' "$dir" >&2; return 2; }
  tmp=$(mktemp -d /tmp/b24-landing-verify.XXXXXX)
  trap 'rm -rf "$tmp"' RETURN
  fetch_site "$site" "$tmp" || { printf 'verify site %s: b24 failed\n' "$site" >&2; return 1; }
  while IFS= read -r f; do
    if [ -f "$dir/$f" ] && [ -f "$tmp/$f" ] && cmp -s "$dir/$f" "$tmp/$f"; then
      okn=$((okn + 1))
    else
      failn=$((failn + 1))
      printf 'FAIL %s\n' "$f"
    fi
  done < <({ (cd "$dir" && find . -type f); (cd "$tmp" && find . -type f); } | sed 's|^\./||' | sort -u)
  printf 'ok=%d failed=%d\n' "$okn" "$failn"
  [ "$failn" -eq 0 ]
}

case "${1:-}" in
  snapshot|verify)
    [ $# -eq 3 ] || { usage >&2; exit 2; }
    "$1" "$2" "$3" ;;
  -h|--help) usage ;;
  *) usage >&2; exit 2 ;;
esac
