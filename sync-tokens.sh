#!/usr/bin/env bash
#
# Push the canonical design tokens out to every consuming project.
# Run this whenever you edit /home/seo/txid-ui/styles/tokens.css.
#
# Add a new project to TARGETS once it starts importing the tokens.

set -euo pipefail

SOURCE="/home/seo/txid-ui/styles/tokens.css"

# project_root:dest_relative_path
TARGETS=(
  "/home/seo/lib.txid.uk-next:src/app/tokens.css"
  "/home/seo/learn.txid.uk:src/styles/tokens.css"
)

if [[ ! -f "$SOURCE" ]]; then
  echo "✗ Canonical tokens.css missing: $SOURCE" >&2
  exit 1
fi

for entry in "${TARGETS[@]}"; do
  root="${entry%%:*}"
  rel="${entry#*:}"
  dest="$root/$rel"
  if [[ ! -d "$root" ]]; then
    echo "  · skip (project missing): $root"
    continue
  fi
  cp "$SOURCE" "$dest"
  echo "  ✓ $dest"
done

echo "Done. Each project's next build picks up the new tokens."
