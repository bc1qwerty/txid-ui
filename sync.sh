#!/usr/bin/env bash
#
# @txid/ui 동기화 스크립트
# 소스: /home/seo/txid-ui/
# 대상: 9개 Astro 프로젝트의 packages/txid-ui/
#

set -euo pipefail

SOURCE_DIR="/home/seo/txid-ui"
SYNC_ITEMS=("components" "data" "package.json")

PROJECTS=(
  "/home/seo/txid.uk-astro"
  "/home/seo/apps.txid.uk-astro"
  "/home/seo/tools.txid.uk-astro"
  "/home/seo/tx.txid.uk-astro"
  "/home/seo/viz.txid.uk-astro"
  "/home/seo/stats.txid.uk-astro"
  "/home/seo/nodes.txid.uk-astro"
  "/home/seo/map.txid.uk-astro"
  "/home/seo/portfolio.txid.uk-astro"
  "/home/seo/sim.txid.uk-astro"
  "/home/seo/glossary.txid.uk-astro"
)

updated=()
skipped=()

echo "=== @txid/ui 동기화 ==="
echo "소스: ${SOURCE_DIR}"
echo ""

for project in "${PROJECTS[@]}"; do
  target="${project}/packages/txid-ui"
  name=$(basename "$project")

  if [[ ! -d "$project" ]]; then
    echo "  [건너뜀] ${name} — 프로젝트 디렉토리 없음"
    skipped+=("$name")
    continue
  fi

  # 대상 디렉토리 생성
  mkdir -p "$target"

  has_changes=false

  for item in "${SYNC_ITEMS[@]}"; do
    src="${SOURCE_DIR}/${item}"
    dst="${target}/${item}"

    if [[ ! -e "$src" ]]; then
      continue
    fi

    # diff 확인
    if [[ -d "$src" ]]; then
      if diff -rq "$src" "$dst" &>/dev/null; then
        continue
      fi
      has_changes=true
      echo "  [변경] ${name}/packages/txid-ui/${item}/"
      diff -rq "$src" "$dst" 2>/dev/null | sed 's/^/         /' || true
      rm -rf "$dst"
      cp -r "$src" "$dst"
    else
      if diff -q "$src" "$dst" &>/dev/null; then
        continue
      fi
      has_changes=true
      echo "  [변경] ${name}/packages/txid-ui/${item}"
      diff --brief "$src" "$dst" 2>/dev/null | sed 's/^/         /' || true
      cp "$src" "$dst"
    fi
  done

  if $has_changes; then
    updated+=("$name")
  fi
done

echo ""
echo "=== 동기화 결과 ==="
echo "  업데이트: ${#updated[@]}개 프로젝트"
if [[ ${#updated[@]} -gt 0 ]]; then
  for u in "${updated[@]}"; do
    echo "    - ${u}"
  done
fi
if [[ ${#skipped[@]} -gt 0 ]]; then
  echo "  건너뜀: ${#skipped[@]}개 프로젝트"
  for s in "${skipped[@]}"; do
    echo "    - ${s}"
  done
fi
if [[ ${#updated[@]} -eq 0 && ${#skipped[@]} -eq 0 ]]; then
  echo "  모든 프로젝트가 이미 최신 상태입니다."
fi
echo ""
echo "=== 공유 스크립트 동기화 (SPOF 제거) ==="
SHARED_SCRIPTS_SRC="/home/seo/apps.txid.uk-astro/public"
SHARED_FILES=("global-nav-v2.js" "global-nav-v2.css" "gtag-init.js")

# apps.txid.uk/learn.txid.uk/txid.uk 제외 (자체 설정 사용)
SCRIPT_TARGETS=(
  "/home/seo/tools.txid.uk-astro"
  "/home/seo/tx.txid.uk-astro"
  "/home/seo/viz.txid.uk-astro"
  "/home/seo/stats.txid.uk-astro"
  "/home/seo/nodes.txid.uk-astro"
  "/home/seo/map.txid.uk-astro"
  "/home/seo/portfolio.txid.uk-astro"
  "/home/seo/sim.txid.uk-astro"
  "/home/seo/glossary.txid.uk-astro"
)

script_updated=()

for project in "${SCRIPT_TARGETS[@]}"; do
  target="${project}/public"
  name=$(basename "$project")

  if [[ ! -d "$target" ]]; then
    echo "  [건너뜀] ${name} — public 디렉토리 없음"
    continue
  fi

  has_script_changes=false

  for file in "${SHARED_FILES[@]}"; do
    src="${SHARED_SCRIPTS_SRC}/${file}"
    dst="${target}/${file}"

    if [[ ! -e "$src" ]]; then
      continue
    fi

    # global-nav-v2.js는 CSS 경로를 로컬로 변환하여 복사
    if [[ "$file" == "global-nav-v2.js" ]]; then
      tmpfile=$(mktemp)
      sed "s|link.href = 'https://apps.txid.uk/global-nav-v2.css';|link.href = '/global-nav-v2.css';|" "$src" > "$tmpfile"
      if diff -q "$tmpfile" "$dst" &>/dev/null; then
        rm -f "$tmpfile"
        continue
      fi
      has_script_changes=true
      echo "  [변경] ${name}/public/${file}"
      cp "$tmpfile" "$dst"
      rm -f "$tmpfile"
    else
      if diff -q "$src" "$dst" &>/dev/null; then
        continue
      fi
      has_script_changes=true
      echo "  [변경] ${name}/public/${file}"
      cp "$src" "$dst"
    fi
  done

  if $has_script_changes; then
    script_updated+=("$name")
  fi
done

echo ""
echo "=== 공유 스크립트 결과 ==="
if [[ ${#script_updated[@]} -gt 0 ]]; then
  echo "  업데이트: ${#script_updated[@]}개 프로젝트"
  for u in "${script_updated[@]}"; do
    echo "    - ${u}"
  done
else
  echo "  모든 프로젝트의 공유 스크립트가 최신 상태입니다."
fi
echo ""
echo "완료!"
