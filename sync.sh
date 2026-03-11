#!/bin/bash

CONFIG_DIR="$HOME/.config"
DOTFILES_DIR="$HOME/dotfiles"

echo "Scanning..."

for target in "$DOTFILES_DIR"/*; do
  item=$(basename "$target")
  if [[ "$item" == ".git" || "$item" == "README.md" || "$item" == "assets" || "$item" == "sync.sh" ]]; then
    continue
  fi

  if [ -e "$CONFIG_DIR/$item" ]; then
    echo "Refreshing: $item"
    rsync -av --delete "$CONFIG_DIR/$item/" "$DOTFILES_DIR/$item/"
  else
    echo "Error: cannot find $item ,aborting..."
  fi
done

echo "Successfully updated. "

cd "$DOTFILES_DIR" || exit

if [[ -n $(git status -s) ]]; then
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
