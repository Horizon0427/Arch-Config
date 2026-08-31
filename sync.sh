#!/usr/bin/env bash

set -euo pipefail

CONFIG_DIR="$HOME/.config"
DOTFILES_DIR="$HOME/Projects/dotfiles"
PRELOCK_SOURCE="$HOME/.local/src/prelock"
PRELOCK_TARGET="$DOTFILES_DIR/prelock"

DRY_RUN=false
RSYNC_ARGS=(-a --existing)

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
    README.md|LICENSE|sync.sh|assets|showcase|prelock)
      continue
      ;;
  esac

  source="$CONFIG_DIR/$item"

  if [[ -d "$target" && -d "$source" ]]; then
    echo "Refreshing existing files: $item"
    rsync "${RSYNC_ARGS[@]}" "$source/" "$target/"
  elif [[ (-f "$target" || -L "$target") && (-f "$source" || -L "$source") ]]; then
    echo "Refreshing existing file: $item"
    rsync "${RSYNC_ARGS[@]}" "$source" "$target"
  else
    echo "Skipping: $item (no matching source: $source)"
  fi
done

if [[ -d "$PRELOCK_TARGET" && -d "$PRELOCK_SOURCE" ]]; then
  echo "Refreshing existing files: prelock (~/.local/src)"
  rsync "${RSYNC_ARGS[@]}" --exclude=/prelock \
    "$PRELOCK_SOURCE/" "$PRELOCK_TARGET/"
elif [[ -d "$PRELOCK_TARGET" ]]; then
  echo "Skipping: prelock (no matching source in $PRELOCK_SOURCE)"
fi

if [[ "$DRY_RUN" == true ]]; then
  echo "Dry run complete. No files or Git state were changed."
  exit 0
fi

echo "Refresh complete."

if [[ -z $(git -C "$DOTFILES_DIR" status --porcelain --untracked-files=normal) ]]; then
  echo "No changes detected; skipping commit and push."
  exit 0
fi

git -C "$DOTFILES_DIR" add -A -- .

if git -C "$DOTFILES_DIR" diff --cached --quiet; then
  echo "No staged changes detected; skipping commit and push."
  exit 0
fi

git -C "$DOTFILES_DIR" diff --cached --check -- . \
  ':(exclude)prelock/patches/*.patch'

commit_message="Auto-sync: $(date +'%Y-%m-%d %H:%M:%S %z')"
echo "Committing: $commit_message"
git -C "$DOTFILES_DIR" commit -m "$commit_message"

if ! upstream=$(git -C "$DOTFILES_DIR" rev-parse \
  --abbrev-ref --symbolic-full-name '@{upstream}' 2>/dev/null); then
  echo "Error: current branch has no configured upstream; commit remains local." >&2
  exit 1
fi

echo "Pushing to $upstream..."
git -C "$DOTFILES_DIR" push
echo "Cloud sync complete."
