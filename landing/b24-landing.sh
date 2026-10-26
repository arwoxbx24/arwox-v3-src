#!/usr/bin/env bash
# Landing pages of a Bitrix24 site <-> files in git. Reads and writes REST via the installed `b24` CLI.
#   snapshot <site> <dir>  save every page of the site into <dir>/<lid>/ (replaces <dir>)
#   verify   <site> <dir>  re-read the site and compare with <dir> byte by byte
#   deploy dev             main page files at HEAD -> dev page 368 (METAROBOTS_INDEX=N), forms -> forms-test
#   deploy prod            main page files at origin/main -> prod page 362, then a new landing-prod-* tag
#   rollback <tag>         main page files of a landing-prod-* tag -> prod page 362, then a new tag
#   copy-dev <lid>         legal page <lid> of site 78 -> its copy on site 80 (METAROBOTS_INDEX=N), "<lid> <copy>" in landing/dev-lids.txt
#   deploy-page dev <lid>  legal page files at HEAD -> its dev copy (landing/dev-lids.txt), forms -> forms-test
#   deploy-page prod <lid> legal page files at origin/main -> page <lid> on site 78, then a new landing-prod-* tag
#   check <url>            live page: 15 sections, 3/3 forms, CSS size, test page noindex, prod page index
# Files per page: block-<id>.draft.html, block-<id>.public.html (getlist content as returned),
# additional-fields.json (getadditionalfields as returned), cssblock.css (its CSSBLOCK_CODE).
set -euo pipefail

usage() {
  printf 'usage: %s snapshot|verify <site-id> <dir> | deploy dev|prod | deploy-page dev|prod <lid> | copy-dev <lid> | rollback <landing-prod-tag> | check <url>\n' "$(basename "$0")"
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
  tmp=$(mktemp -d "$dir.tmp.XXXXXX") || { printf 'snapshot site %s: mktemp failed, nothing written\n' "$site" >&2; return 1; }
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
  local site=$1 dir=${2%/} tmp f files okn=0 failn=0
  [ -d "$dir" ] || { printf 'verify: no snapshot dir %s\n' "$dir" >&2; return 2; }
  tmp=$(mktemp -d /tmp/b24-landing-verify.XXXXXX) || { printf 'verify site %s: mktemp failed\n' "$site" >&2; return 1; }
  trap 'rm -rf "$tmp"' RETURN
  fetch_site "$site" "$tmp" || { printf 'verify site %s: b24 failed\n' "$site" >&2; return 1; }
  files=$({ (cd "$dir" && find . -type f); (cd "$tmp" && find . -type f); } | sed 's|^\./||' | sort -u) || { printf 'verify site %s: cannot list files\n' "$site" >&2; return 1; }
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    if [ -f "$dir/$f" ] && [ -f "$tmp/$f" ] && cmp -s "$dir/$f" "$tmp/$f"; then
      okn=$((okn + 1))
    else
      failn=$((failn + 1))
      printf 'FAIL %s\n' "$f"
    fi
  done <<<"$files"
  [ $((okn + failn)) -gt 0 ] || { printf 'verify site %s: nothing compared\n' "$site" >&2; return 1; }
  printf 'ok=%d failed=%d\n' "$okn" "$failn"
  [ "$failn" -eq 0 ]
}

# --- Upload from files. Only the main page has an upload route: landing/site78/362 -> prod 362, dev 368. ---
# Bitrix24 (measured 21.10, landing/README.md): REST writes only the draft, landing.landing.publication publishes
# it; CSSBLOCK_CODE keeps at most 65535 bytes and cuts longer CSS silently with result true.
LIMIT=65535
PROD_FORMS='https://forms.arwox.ru/'
TEST_FORMS='https://forms-test.arwox.ru/'
SRC=landing/site78/362
PROD_LID=362
DEV_SITE=80
DEV_LID=368
DEV_DIR=landing/site80
DEV_LIDS=landing/dev-lids.txt
SECTIONS='hero results demo case why-us process packages integrations partners certificates bitrixgpt tariffs faq websites contact'
# getlist content = <div id="b<id>" class="...">inside</div>; updatecontent takes the inside.
UNWRAP='if test("\\A<div id=\"b[0-9]+\" class=\"[^\"]*\">") and endswith("</div>") then sub("\\A<div id=\"b[0-9]+\" class=\"[^\"]*\">"; "") | .[:-6] else error("no block wrapper") end'

fail() { printf '%s\n' "$*" >&2; exit 1; }

to_top() {  # every path below is relative to the repo root
  local top
  top=$(git rev-parse --show-toplevel) || fail 'not inside the git repo'
  cd "$top"
}

files_at() {  # <rev> <dir>: the main page at <rev> -> <dir>/content.html (block inside), <dir>/style.css
  local rev=$1 dir=$2 blocks
  blocks=$(git ls-tree --name-only "$rev" "$SRC/" | grep -E '/block-[0-9]+\.draft\.html$') || fail "$rev: no draft block in $SRC"
  [ "$(printf '%s\n' "$blocks" | wc -l)" -eq 1 ] || fail "$rev: more than one draft block in $SRC"
  mkdir -p "$dir"
  git cat-file blob "$rev:$blocks" | jq -n -j --rawfile s /dev/stdin '$s | '"$UNWRAP" > "$dir/content.html" || return 1
  git cat-file blob "$rev:$SRC/cssblock.css" > "$dir/style.css" || return 1
}

page_files_at() {  # <rev> <lid> <dir>: draft blocks of legal page <lid> at <rev>, ascending id -> <dir>/<k>.html (block inside), public blocks -> <dir>/pub/<k>.html, <dir>/style.css
  local rev=$1 lid=$2 dir=$3 blocks pub f k=0
  blocks=$(git ls-tree --name-only "$rev" "landing/site78/$lid/" | grep -E '/block-[0-9]+\.draft\.html$' | sort -t- -k2,2n) || fail "$rev: no draft block in landing/site78/$lid"
  pub=$(git ls-tree --name-only "$rev" "landing/site78/$lid/" | grep -E '/block-[0-9]+\.public\.html$' | sort -t- -k2,2n) || fail "$rev: no public block in landing/site78/$lid"
  mkdir -p "$dir/pub"
  while IFS= read -r f; do
    k=$((k + 1))
    git cat-file blob "$rev:$f" | jq -n -j --rawfile s /dev/stdin '$s | '"$UNWRAP" > "$dir/$k.html" || return 1
  done <<<"$blocks"
  k=0
  while IFS= read -r f; do
    k=$((k + 1))
    git cat-file blob "$rev:$f" | jq -n -j --rawfile s /dev/stdin '$s | '"$UNWRAP" > "$dir/pub/$k.html" || return 1
  done <<<"$pub"
  git cat-file blob "$rev:landing/site78/$lid/cssblock.css" > "$dir/style.css" || return 1
}

live_page_is() {  # <lid> <dir>: live draft blocks equal <dir>/<k>.html, live published blocks equal <dir>/pub/<k>.html, CSS equal <dir>/style.css
  local lid=$1 dir=$2 mode k n sub
  for mode in 1 0; do
    if [ "$mode" = 1 ]; then sub=$dir; else sub=$dir/pub; fi
    b24 landing.block.getlist "lid=$lid" "params[edit_mode]=$mode" 'params[get_content]=1' > "$WORK/blocks.json" || return 1
    n=$(jq length "$WORK/blocks.json") || return 1
    [ "$n" -eq "$(ls "$sub" | grep -c '\.html$')" ] || return 1
    for k in $(seq 1 "$n"); do
      jq -j ".[$((k - 1))].content | $UNWRAP" "$WORK/blocks.json" > "$WORK/live.$k" || return 1
      cmp -s "$WORK/live.$k" "$sub/$k.html" || return 1
    done
  done
  b24 landing.landing.getadditionalfields "lid=$lid" | jq -j '.CSSBLOCK_CODE // ""' > "$WORK/live.css" || return 1
  cmp -s "$WORK/live.css" "$dir/style.css"
}

live_block() {  # <lid> <edit_mode> <out>: the page's only block, inside -> <out>; prints the block id
  local lid=$1 mode=$2 out=$3 n
  b24 landing.block.getlist "lid=$lid" "params[edit_mode]=$mode" 'params[get_content]=1' > "$WORK/blocks.json" || return 1
  n=$(jq length "$WORK/blocks.json") || return 1
  [ "$n" -eq 1 ] || { printf 'lid %s edit_mode %s: %s blocks, expected 1\n' "$lid" "$mode" "$n" >&2; return 1; }
  jq -j ".[0].content | $UNWRAP" "$WORK/blocks.json" > "$out" || return 1
  jq -r '.[0].id' "$WORK/blocks.json"
}

live_matches() {  # <lid> <dir>...: live draft, published block and CSS each equal the files of one <dir>
  local lid=$1 part dir hit bad=0
  shift
  live_block "$lid" 1 "$WORK/live.draft" > /dev/null || return 1
  live_block "$lid" 0 "$WORK/live.public" > /dev/null || return 1
  b24 landing.landing.getadditionalfields "lid=$lid" | jq -j '.CSSBLOCK_CODE // ""' > "$WORK/live.css" || return 1
  for part in draft:content.html public:content.html css:style.css; do
    hit=0
    for dir in "$@"; do
      if cmp -s "$WORK/live.${part%%:*}" "$dir/${part#*:}"; then hit=1; fi
    done
    [ "$hit" -eq 1 ] || { printf 'lid %s: live %s differs\n' "$lid" "${part%%:*}" >&2; bad=1; }
  done
  [ "$bad" -eq 0 ]
}

ready() {  # <dir> <forms url> [empty ok]: refuse before any write
  local dir=$1 url=$2 total good bytes
  total=$({ cat "$dir"/*.html | grep -o 'action=' || true; } | wc -l)
  good=$({ cat "$dir"/*.html | grep -o -F "action=\"$url\"" || true; } | wc -l)
  { [ "$total" -gt 0 ] || [ -n "${3:-}" ]; } && [ "$total" -eq "$good" ] || { printf 'refused: %s of %s form actions post to %s; nothing written\n' "$good" "$total" "$url" >&2; return 1; }
  bytes=$(wc -c < "$dir/style.css")
  [ "$bytes" -le "$LIMIT" ] || { printf 'refused: CSS is %s bytes, the field keeps %s; nothing written\n' "$bytes" "$LIMIT" >&2; return 1; }
}

upload() {  # <lid> <dir>: draft and CSS <- files, publish, re-read: live = files
  local lid=$1 dir=$2 block
  block=$(live_block "$lid" 1 "$WORK/live.draft") || return 1
  jq -n --argjson lid "$lid" --argjson block "$block" --rawfile c "$dir/content.html" '{lid:$lid,block:$block,content:$c}' > "$WORK/content.json" || return 1
  jq -n --argjson lid "$lid" --rawfile c "$dir/style.css" '{lid:$lid,fields:{ADDITIONAL_FIELDS:{CSSBLOCK_CODE:$c}}}' > "$WORK/css.json" || return 1
  b24 landing.block.updatecontent --json-file "$WORK/content.json" > /dev/null || return 1
  b24 landing.landing.update --json-file "$WORK/css.json" > /dev/null || return 1
  b24 landing.landing.publication "lid=$lid" > /dev/null || return 1
  live_matches "$lid" "$dir"
}

upload_page() {  # <lid> <dir>: draft blocks and CSS <- files (paired by position), publish, re-read: live = files
  local lid=$1 dir=$2 n k id files
  b24 landing.block.getlist "lid=$lid" "params[edit_mode]=1" 'params[get_content]=1' > "$WORK/blocks.json" || return 1
  n=$(jq length "$WORK/blocks.json") || return 1
  files=$(ls "$dir" | grep -c '\.html$')
  [ "$n" -eq "$files" ] || { printf 'lid %s: %s draft blocks, files have %s; nothing written\n' "$lid" "$n" "$files" >&2; return 1; }
  for k in $(seq 1 "$n"); do
    id=$(jq -r ".[$((k - 1))].id" "$WORK/blocks.json") || return 1
    jq -n --argjson lid "$lid" --argjson block "$id" --rawfile c "$dir/$k.html" '{lid:$lid,block:$block,content:$c}' > "$WORK/content.json" || return 1
    b24 landing.block.updatecontent --json-file "$WORK/content.json" > /dev/null || return 1
  done
  jq -n --argjson lid "$lid" --rawfile c "$dir/style.css" '{lid:$lid,fields:{ADDITIONAL_FIELDS:{CSSBLOCK_CODE:$c}}}' > "$WORK/css.json" || return 1
  b24 landing.landing.update --json-file "$WORK/css.json" > /dev/null || return 1
  b24 landing.landing.publication "lid=$lid" > /dev/null || return 1
  live_page_is "$lid" "$dir"
}

tag_prod() {  # <rev> <lid>: a new landing-prod-* tag on <rev> in origin, after page <lid> = <rev>
  local rev=$1 lid=$2 new
  new="landing-prod-$(date -u +%Y%m%d-%H%M%S)-$(git rev-parse --short "$rev^{commit}")"
  git tag "$new" "$rev^{commit}" || fail "page $lid = $rev, but git tag $new failed"
  git push -q origin "refs/tags/$new" || fail "page $lid = $rev, tag not pushed: git push origin refs/tags/$new"
  printf 'prod: page %s = %s, tag %s\n' "$lid" "$rev" "$new"
}

to_prod() {  # <rev>: prod page 362 <- the main page at <rev>, then a new landing-prod-* tag on <rev> in origin
  local rev=$1 tags last
  tags=$(git tag -l 'landing-prod-*' --sort=-refname)
  last=${tags%%$'\n'*}
  [ -n "$last" ] || fail 'refused: no landing-prod-* tag (landing/README.md: base tag); nothing written'
  files_at "$last" "$WORK/old" || exit 1
  files_at "$rev" "$WORK/new" || exit 1
  # A part equal to <rev> is left by an earlier failed run of this command; both versions are in git.
  live_matches "$PROD_LID" "$WORK/old" "$WORK/new" || fail "refused: live page $PROD_LID differs from $last and from $rev; nothing written"
  ready "$WORK/new" "$PROD_FORMS" || exit 1
  if ! upload "$PROD_LID" "$WORK/new"; then
    upload "$PROD_LID" "$WORK/old" || fail "write failed, restore failed: page $PROD_LID is part $rev, part $last; when Bitrix24 answers, run the same command again"
    fail "write failed, restored: page $PROD_LID = $last"
  fi
  tag_prod "$rev" "$PROD_LID"
}

deploy_dev() {
  local dirty robots
  dirty=$(git status --porcelain -- "$SRC" "$DEV_DIR")
  [ -z "$dirty" ] || fail "refused: uncommitted changes in $SRC or $DEV_DIR (repo first); nothing written"
  ( verify "$DEV_SITE" "$DEV_DIR" ) || fail "refused: live site $DEV_SITE differs from $DEV_DIR; snapshot $DEV_SITE $DEV_DIR, commit, then deploy dev; nothing written"
  robots=$(b24 landing.landing.getadditionalfields "lid=$DEV_LID" | jq -r '.METAROBOTS_INDEX // "?"') || fail "refused: cannot read dev page $DEV_LID additional fields; nothing written"
  [ "$robots" = N ] || fail "refused: dev page $DEV_LID METAROBOTS_INDEX=$robots, must be N (closed from search); nothing written"
  files_at HEAD "$WORK/new" || exit 1
  jq -n -j --rawfile s "$WORK/new/content.html" '$s | split("forms.arwox.ru") | join("forms-test.arwox.ru")' > "$WORK/dev.html" || exit 1
  mv "$WORK/dev.html" "$WORK/new/content.html" || exit 1
  ready "$WORK/new" "$TEST_FORMS" || exit 1
  upload "$DEV_LID" "$WORK/new" || fail "dev page $DEV_LID: write failed; snapshot $DEV_SITE $DEV_DIR, commit, then deploy dev again"
  printf 'dev: page %s = %s; next: snapshot %s %s and commit\n' "$DEV_LID" "$(git rev-parse --short HEAD)" "$DEV_SITE" "$DEV_DIR"
}

copy_dev() {  # <lid>: legal page <lid> of site 78 -> its copy on site 80 with METAROBOTS_INDEX=N, "<lid> <copy>" appended to landing/dev-lids.txt
  local lid=$1 newlid
  [[ $lid =~ ^[0-9]+$ ]] && [ "$lid" != "$PROD_LID" ] && [ -d "landing/site78/$lid" ] || fail "refused: $lid is not a legal page of site 78 (landing/site78/<lid>); nothing written"
  if [ -f "$DEV_LIDS" ] && grep -q "^$lid " "$DEV_LIDS"; then fail "refused: $lid already has a dev copy in $DEV_LIDS; nothing written"; fi
  newlid=$(b24 landing.landing.copy "lid=$lid" "toSiteId=$DEV_SITE") || fail "copy $lid to site $DEV_SITE failed; nothing written"
  jq -n --argjson lid "$newlid" '{lid:$lid,fields:{ADDITIONAL_FIELDS:{METAROBOTS_INDEX:"N"}}}' > "$WORK/robots.json" || exit 1
  b24 landing.landing.update --json-file "$WORK/robots.json" > /dev/null || fail "page $newlid: METAROBOTS_INDEX write failed; copy not in $DEV_LIDS"
  printf '%s %s\n' "$lid" "$newlid" >> "$DEV_LIDS"
  printf 'dev copy: %s -> %s\n' "$lid" "$newlid"
}

deploy_page() {  # dev|prod <lid>: legal page <lid> of site 78, files at HEAD -> its dev copy (dev) or page <lid> (prod)
  local env=$1 lid=$2 target dirty robots tags last f
  [[ $lid =~ ^[0-9]+$ ]] && [ "$lid" != "$PROD_LID" ] && [ -d "landing/site78/$lid" ] || fail "refused: $lid is not a legal page of site 78; nothing written"
  if [ "$env" = dev ]; then
    [ -f "$DEV_LIDS" ] || fail "refused: no $DEV_LIDS; copy-dev $lid first; nothing written"
    target=$(awk -v l="$lid" '$1 == l { print $2 }' "$DEV_LIDS") || exit 1
    [ -n "$target" ] || fail "refused: $lid has no dev copy in $DEV_LIDS; copy-dev $lid first; nothing written"
    dirty=$(git status --porcelain -- "landing/site78/$lid" "$DEV_LIDS")
    [ -z "$dirty" ] || fail "refused: uncommitted changes in landing/site78/$lid or $DEV_LIDS (repo first); nothing written"
    robots=$(b24 landing.landing.getadditionalfields "lid=$target" | jq -r '.METAROBOTS_INDEX // "?"') || fail "refused: cannot read dev page $target additional fields; nothing written"
    [ "$robots" = N ] || fail "refused: dev page $target METAROBOTS_INDEX=$robots, must be N (closed from search); nothing written"
    page_files_at HEAD "$lid" "$WORK/new" || exit 1
    for f in "$WORK/new"/*.html "$WORK/new/pub"/*.html; do
      jq -n -j --rawfile s "$f" '$s | split("forms.arwox.ru") | join("forms-test.arwox.ru")' > "$WORK/dev.html" && mv "$WORK/dev.html" "$f" || exit 1
    done
    ready "$WORK/new" "$TEST_FORMS" zero-ok || exit 1
    upload_page "$target" "$WORK/new" || fail "dev page $target: write failed; nothing more written"
    printf 'dev: page %s (copy of %s) = %s\n' "$target" "$lid" "$(git rev-parse --short HEAD)"
  else
    git fetch -q --tags origin || fail 'git fetch origin failed; nothing written'
    [ "$(git rev-parse HEAD)" = "$(git rev-parse origin/main)" ] || fail 'refused: deploy-page prod runs only at origin/main; nothing written'
    tags=$(git tag -l 'landing-prod-*' --sort=-refname)
    last=${tags%%$'\n'*}
    [ -n "$last" ] || fail 'refused: no landing-prod-* tag (landing/README.md: base tag); nothing written'
    page_files_at "$last" "$lid" "$WORK/old" || exit 1
    page_files_at HEAD "$lid" "$WORK/new" || exit 1
    live_page_is "$lid" "$WORK/old" || live_page_is "$lid" "$WORK/new" || fail "refused: live page $lid differs from $last and from HEAD; nothing written"
    ready "$WORK/new" "$PROD_FORMS" zero-ok || exit 1
    if ! upload_page "$lid" "$WORK/new"; then
      upload_page "$lid" "$WORK/old" || fail "write failed, restore failed: page $lid is partly HEAD, partly $last; when Bitrix24 answers, run the same command again"
      fail "write failed, restored: page $lid = $last"
    fi
    tag_prod HEAD "$lid"
  fi
}

deploy_prod() {
  git fetch -q --tags origin || fail 'git fetch origin failed; nothing written'
  [ "$(git rev-parse HEAD)" = "$(git rev-parse origin/main)" ] || fail 'refused: deploy prod runs only at origin/main; nothing written'
  to_prod HEAD
}

rollback() {  # <tag>: prod page 362 <- the main page of a landing-prod-* tag
  local tag=$1
  [[ $tag =~ ^landing-prod-[0-9]{8}-[0-9]{6}-[0-9a-f]+$ ]] || fail "refused: $tag is not a landing-prod-* tag"
  git fetch -q --tags origin || fail 'git fetch origin failed; nothing written'
  git show-ref --verify -q "refs/tags/$tag" || fail "refused: no tag $tag"
  to_prod "$tag"
}

check() {  # <url>: 15 sections in order, 3/3 forms on the address of its environment, CSS within the field, robots
  local url=$1 forms got total good bytes=0 bad=0 env robots
  case "$url" in
    http*://arwox.ru*|http*://www.arwox.ru*) forms=$PROD_FORMS; env=prod ;;
    *) forms=$TEST_FORMS; env=test ;;
  esac
  curl -fsSL "$url" > "$WORK/page.html" || fail "check: cannot fetch $url"
  got=$({ grep -o -E " id=\"(${SECTIONS// /|})\"" "$WORK/page.html" || true; } | cut -d'"' -f2 | tr '\n' ' ')
  [ "${got% }" = "$SECTIONS" ] || { printf 'FAIL sections: want %s; got %s\n' "$SECTIONS" "${got% }"; bad=1; }
  total=$({ grep -o 'action=' "$WORK/page.html" || true; } | wc -l)
  good=$({ grep -o -F "action=\"$forms\"" "$WORK/page.html" || true; } | wc -l)
  [ "$total" -eq 3 ] && [ "$good" -eq 3 ] || { printf 'FAIL forms=%s/3 post to %s (action= on the page: %s)\n' "$good" "$forms" "$total"; bad=1; }
  if grep -q -F '<style type="text/css">' "$WORK/page.html"; then
    bytes=$(jq -n -j --rawfile s "$WORK/page.html" '$s | split("<style type=\"text/css\">") | last | split("</style>") | first' | wc -c)
    [ "$bytes" -le "$LIMIT" ] || { printf 'FAIL css=%s bytes, the field keeps %s\n' "$bytes" "$LIMIT"; bad=1; }
  else
    printf 'FAIL css: no <style type="text/css"> on the page\n'
    bad=1
  fi
  if [ "$env" = test ]; then
    robots=noindex
    grep -q -F '<meta name="robots" content="noindex"' "$WORK/page.html" || { printf 'FAIL robots: no noindex meta on the test page\n'; bad=1; }
  else
    robots=index
    grep -q -E '<meta[^>]*name="robots"[^>]*noindex' "$WORK/page.html" && { printf 'FAIL robots: noindex on the prod page\n'; bad=1; }
  fi
  [ "$bad" -eq 0 ] || return 1
  printf 'ok sections=15 forms=3/3 css=%s robots=%s\n' "$bytes" "$robots"
}

case "${1:-}" in
  snapshot|verify)
    [ $# -eq 3 ] || { usage >&2; exit 2; }
    "$1" "$2" "$3" ;;
  deploy|rollback|check|copy-dev|deploy-page)
    case "$1:$#" in
      deploy:2|rollback:2|check:2|copy-dev:2|deploy-page:3) ;;
      *) usage >&2; exit 2 ;;
    esac
    WORK=$(mktemp -d /tmp/b24-landing.XXXXXX)
    trap 'rm -rf "$WORK"' EXIT
    case "$1:$2" in
      deploy:dev) to_top; deploy_dev ;;
      deploy:prod) to_top; deploy_prod ;;
      deploy-page:dev|deploy-page:prod) to_top; deploy_page "$2" "$3" ;;
      copy-dev:*) to_top; copy_dev "$2" ;;
      rollback:*) to_top; rollback "$2" ;;
      check:*) check "$2" ;;
      *) usage >&2; exit 2 ;;
    esac ;;
  -h|--help) usage ;;
  *) usage >&2; exit 2 ;;
esac
