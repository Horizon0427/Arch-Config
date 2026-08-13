#!/usr/bin/env bash

set -euo pipefail

CONFIG_DIR="$HOME/.config"
DOTFILES_DIR="$HOME/Projects/dotfiles"

DRY_RUN=false
RSYNC_ARGS=(-av --existing)

case "${1:-}" in
  "")
    ;;
  --dry-run)
    DRY_RUN=true
    RSYNC_ARGS+=(--dry-run --itemize-changes)
    ;;
  *)
    echo "Usage: $0 [--dry-run]" >&2
    exit 2
    ;;
esac

if [[ ! -d "$CONFIG_DIR" ]]; then
  echo "Error: config directory not found: $CONFIG_DIR" >&2
  exit 1
fi

if ! git -C "$DOTFILES_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Error: dotfiles Git repository not found: $DOTFILES_DIR" >&2
  exit 1
fi

if ! command -v rsync >/dev/null 2>&1; then
  echo "Error: rsync is not installed." >&2
  exit 1
fi

echo "Scanning..."

for target in "$DOTFILES_DIR"/*; do
  item=${target##*/}

  case "$item" in
    README.md|LICENSE|sync.sh|assets|showcase)
      continue
      ;;
  esac

  source="$CONFIG_DIR/$item"

  if [[ -d "$target" && -d "$source" ]]; then
    echo "Refreshing existing files: $item"
    rsync "${RSYNC_ARGS[@]}" "$source/" "$target/"
  elif [[ -f "$target" && -f "$source" ]]; then
    echo "Refreshing existing file: $item"
    rsync "${RSYNC_ARGS[@]}" "$source" "$target"
  else
    echo "Skipping: $item (no matching source in $CONFIG_DIR)"
  fi
done

if [[ "$DRY_RUN" == true ]]; then
  echo "Dry run complete. No files, commits, or remote branches were changed."
  exit 0
fi

echo "Successfully updated."

cd "$DOTFILES_DIR"

if [[ -n $(git status --short) ]]; then
  echo "Changes detected, packaging..."
  git add .
  COMMIT_MSG="Auto-sync: $(date +'%Y-%m-%d %H:%M:%S')"
  git commit -m "$COMMIT_MSG"
  echo "Sending to GitHub..."
  git push
  echo "GitHub updated."
else
  echo "No changes detected."
fi
