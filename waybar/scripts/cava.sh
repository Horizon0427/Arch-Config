#!/bin/bash

CHARS="▂▃▄▅▆▇█"
BARS=15
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
channels = mono

[smoothing]
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
      sed_dict="s/;//g;"
      for ((i = 0; i <= ${len}; i++)); do
        sed_dict="${sed_dict}s/$i/${CHARS:$i:1}/g;"
      done
      cava -p "$CONF" 2>/dev/null | sed -u "$sed_dict" &
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
