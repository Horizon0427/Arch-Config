#!/bin/bash

STATE_FILE="/tmp/waybar_position"

killall waybar 2>/dev/null

while pgrep -x waybar >/dev/null; do sleep 0.1; done

if [ ! -f "$STATE_FILE" ] || [ "$(cat "$STATE_FILE")" = "bottom" ]; then
  waybar -c ~/.config/waybar/config-top.jsonc -s ~/.config/waybar/style-top.css &
  echo "top" >"$STATE_FILE"
else
  waybar -c ~/.config/waybar/config-bottom.jsonc -s ~/.config/waybar/style-bottom.css &
  echo "bottom" >"$STATE_FILE"
fi
