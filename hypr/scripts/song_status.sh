#!/bin/bash

STATUS=$(playerctl -p spotify status 2>/dev/null)
if [[ "$STATUS" == "Playing" || "$STATUS" == "Paused" ]]; then
  playerctl -p spotify metadata --format '󰎆 {{title}} - {{artist}}' | cut -c 1-100
else
  echo " "
fi
