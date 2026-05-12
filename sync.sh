#!/usr/bin/env bash
#
# Push design tokens and shared components to all consuming projects.
# Run this whenever you edit /home/seo/txid-ui/styles/* or /home/seo/txid-ui/components/*.

set -euo pipefail

UI_ROOT="/home/seo/txid-ui"

# project_root:dest_style_path:dest_component_path
TARGETS=(
  "/home/seo/lib.txid.uk-next:src/app/tokens.css:src/components/ui"
  "/home/seo/learn.txid.uk:src/styles/tokens.css:src/components/ui"
  "/home/seo/apps.txid.uk-astro:src/styles/tokens.css:src/components/ui"
  "/home/seo/dev.txid.uk-astro:src/styles/tokens.css:src/components/ui"
  "/home/seo/id.txid.uk-astro:src/styles/tokens.css:src/components/ui"
  "/home/seo/map.txid.uk-astro:src/styles/tokens.css:src/components/ui"
  "/home/seo/portfolio.txid.uk-astro:src/styles/tokens.css:src/components/ui"
  "/home/seo/sim.txid.uk-astro:src/styles/tokens.css:src/components/ui"
  "/home/seo/tools.txid.uk-astro:src/styles/tokens.css:src/components/ui"
  "/home/seo/tx.txid.uk-astro:src/styles/tokens.css:src/components/ui"
  "/home/seo/txid.uk-astro:src/styles/tokens.css:src/components/ui"
)

for entry in "${TARGETS[@]}"; do
  IFS=':' read -r root style_dest comp_dest <<< "$entry"
  
  if [[ ! -d "$root" ]]; then
    echo "  · skip (project missing): $root"
    continue
  fi

  # Sync Tokens
  mkdir -p "$(dirname "$root/$style_dest")"
  cp "$UI_ROOT/styles/tokens.css" "$root/$style_dest"
  
  # Sync Components
  mkdir -p "$root/$comp_dest"
  cp -r "$UI_ROOT/components/"* "$root/$comp_dest/"
  
  echo "  ✓ $root (tokens + components)"
done

echo "Done. All projects synchronized with txid-ui."
