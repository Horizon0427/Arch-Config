#!/usr/bin/env bash

set -euo pipefail

CONFIG_DIR="$HOME/.config"
DOTFILES_DIR="$HOME/Projects/dotfiles"
PRELOCK_SOURCE="$HOME/.local/src/prelock"
PRELOCK_TARGET="$DOTFILES_DIR/prelock"
HOME_TARGET="$DOTFILES_DIR/home"
LOCAL_BIN_SOURCE="$HOME/.local/bin"
LOCAL_BIN_TARGET="$DOTFILES_DIR/local/bin"
PROJECT_SCRIPTS_SOURCE="$HOME/Projects/scripts"
PROJECT_SCRIPTS_TARGET="$DOTFILES_DIR/scripts"

DRY_RUN=false
RSYNC_ARGS=(-a --checksum --existing --itemize-changes)

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

refresh_entry() {
  local label=$1
  local source=$2
  local target=$3

  if [[ -d "$target" && -d "$source" ]]; then
    echo "Refreshing existing files: $label"
    rsync "${RSYNC_ARGS[@]}" "$source/" "$target/"
  elif [[ (-f "$target" || -L "$target") && (-f "$source" || -L "$source") ]]; then
    echo "Refreshing existing file: $label"
    rsync "${RSYNC_ARGS[@]}" "$source" "$target"
  else
    echo "Skipping: $label (no matching source: $source)"
  fi
}

refresh_root() {
  local label=$1
  local source_root=$2
  local target_root=$3
  local target item

  [[ -d "$target_root" ]] || return 0
  if [[ ! -d "$source_root" ]]; then
    echo "Skipping: $label (source directory not found: $source_root)"
    return 0
  fi

  for target in "$target_root"/* "$target_root"/.[!.]* "$target_root"/..?*; do
    [[ -e "$target" || -L "$target" ]] || continue
    item=${target#"$target_root"/}
    refresh_entry "$label/$item" "$source_root/$item" "$target"
  done
}

echo "Scanning..."

for target in "$DOTFILES_DIR"/*; do
  item=${target##*/}

  case "$item" in
    README.md|LICENSE|sync.sh|assets|showcase|prelock|home|local|scripts)
      continue
      ;;
  esac

  source="$CONFIG_DIR/$item"
  refresh_entry "$item" "$source" "$target"
done

refresh_root "home" "$HOME" "$HOME_TARGET"
refresh_root "local/bin" "$LOCAL_BIN_SOURCE" "$LOCAL_BIN_TARGET"
refresh_root "Projects/scripts" "$PROJECT_SCRIPTS_SOURCE" "$PROJECT_SCRIPTS_TARGET"

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

git -C "$DOTFILES_DIR" add -A -- .

if ! git -C "$DOTFILES_DIR" diff --cached --quiet; then
  git -C "$DOTFILES_DIR" diff --cached --check -- . \
    ':(exclude)prelock/patches/*.patch'
  commit_message="Auto-sync: $(date +'%Y-%m-%d %H:%M:%S %z')"
  echo "Committing: $commit_message"
  git -C "$DOTFILES_DIR" commit -m "$commit_message"
else
  echo "No new changes to commit."
fi

if ! upstream=$(git -C "$DOTFILES_DIR" rev-parse \
  --abbrev-ref --symbolic-full-name '@{upstream}' 2>/dev/null); then
  echo "Error: current branch has no configured upstream; commit remains local." >&2
  exit 1
fi

echo "Pushing to $upstream..."
git -C "$DOTFILES_DIR" push
echo "Cloud sync complete."
