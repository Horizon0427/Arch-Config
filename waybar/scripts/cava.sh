#!/bin/bash

CHARS="▁▂▃▄▅▆▇█"
BARS=18
CONF="/tmp/waybar_cava_config"

len=$((${#CHARS} - 1))
idle_char="${CHARS:0:1}"
idle_output=$(printf "%0.s$idle_char" $(seq 1 $BARS))

cat >"$CONF" <<EOF
[general]
bars = $BARS
framerate = 60
autosens = 1
sensitivity = 135

[input]
method = pulse
source = auto

[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = $len
channels = stereo

[smoothing]
monstercat = 1
waves = 1
noise_reduction = 50
EOF

cleanup() {
  trap - EXIT INT TERM
  pkill -P $$ 2>/dev/null
  echo "$idle_output"
  exit 0
}
trap cleanup EXIT INT TERM

is_audio_active() {
  pactl list sink-inputs 2>/dev/null | grep -q "Corked: no"
}

echo "$idle_output"

while true; do
  if is_audio_active; then
    if ! pgrep -P $$ -x cava >/dev/null; then
      cava -p "$CONF" 2>/dev/null | awk -v chars="$CHARS" '
      BEGIN {
          FS=";";
          split(chars, map, "");
      }
      {
          out = "";
          for(i=1; i<=NF-1; i++) {
              out = out map[$i + 1];
          }
          print out;
          fflush();
      }' &
    fi
    sleep 1
  else
    if pgrep -P $$ -x cava >/dev/null; then
      pkill -P $$ -x cava 2>/dev/null
      wait 2>/dev/null
      echo "$idle_output"
    fi
    timeout 5s pactl subscribe 2>/dev/null | grep --line-buffered "sink-input" | head -n 1 >/dev/null
  fi
done
