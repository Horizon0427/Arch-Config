#!/bin/bash

SAVE_DIR="$HOME/Pictures/Screenshots"
mkdir -p "$SAVE_DIR"
FILE_PATH="$SAVE_DIR/scr_$(date +%Y%m%d_%H%M%S).png"
if grim -g "$(XCURSOR_SIZE="${HYPRCURSOR_SIZE:-30}" slurp)" "$FILE_PATH"; then
  wl-copy -t image/png <"$FILE_PATH"
  ACTION=$(notify-send -a "Screenshot" -i "$FILE_PATH" \
    --action="default=edit" \
    "截图已复制到剪贴板   点击以编辑")
  if [ "$ACTION" = "default" ]; then
    satty --filename "$FILE_PATH" \
      --app-id org.satty.satty \
      --copy-command wl-copy \
      --output-filename "$FILE_PATH"
  fi
fi
