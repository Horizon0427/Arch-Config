#!/bin/bash

if pgrep -a waybar | grep -q "config-bottom"; then
  CURRENT_STATE="bottom"
else
  CURRENT_STATE="top"
fi

killall waybar 2>/dev/null
while pgrep -x waybar >/dev/null; do sleep 0.1; done

if [ "$CURRENT_STATE" = "bottom" ]; then
  waybar -c ~/.config/waybar/config-bottom.jsonc -s ~/.config/waybar/style-bottom.css &
else
  waybar -c ~/.config/waybar/config-top.jsonc -s ~/.config/waybar/style-top.css &
fi
