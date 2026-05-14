#!/bin/bash

if pgrep -a ironbar | grep -q "bottom"; then
  CURRENT_STATE="bottom"
else
  CURRENT_STATE="top"
fi

killall ironbar 2>/dev/null
while pgrep -x ironbar >/dev/null; do sleep 0.1; done

if [ "$CURRENT_STATE" = "bottom" ]; then
  ironbar -c ~/.config/ironbar/top/config.toml -t ~/.config/ironbar/top/style.css &
else
  ironbar -c ~/.config/ironbar/bottom/config.toml -t ~/.config/ironbar/bottom/style.css &
fi
