#!/bin/bash

PID_FILE="/tmp/ironbar_cava.pid"
if [ -f "$PID_FILE" ]; then
    old_pid=$(cat "$PID_FILE")
    pkill -P "$old_pid" 2>/dev/null
    kill -9 "$old_pid" 2>/dev/null
fi
echo "$$" > "$PID_FILE"

pkill -x cava 2>/dev/null

CHARS="▁▂▃▄▅▆▇█"
BARS=18
CONF="/tmp/waybar_cava_config"

len=$((${#CHARS} - 1))
idle_char="${CHARS:0:1}"
idle_output=$(printf "%0.s$idle_char" $(seq 1 $BARS))

sed_dict="s/;//g;"
for ((i=0; i<=${len}; i++)); do
    sed_dict="${sed_dict}s/$i/${CHARS:$i:1}/g;"
done

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
bg_pid=""

while true; do
    if ! echo -n "" >/dev/stdout 2>/dev/null; then
        pkill -P $$ 2>/dev/null
        exit 0
    fi

    if is_audio_active; then
        if [ -z "$bg_pid" ] || ! kill -0 "$bg_pid" 2>/dev/null; then
            pkill -P $$ -x cava 2>/dev/null
            _sink=$(pactl list sinks short 2>/dev/null | awk '/RUNNING/{print $2; exit}')
            [ -z "$_sink" ] && _sink=$(pactl info 2>/dev/null | awk '/Default Sink/{print $3}')
            cat >"$CONF" <<CAVACONF
[general]
bars = $BARS
framerate = 60
autosens = 1
sensitivity = 135

[input]
method = pulse
source = ${_sink}.monitor

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
CAVACONF
            cava -p "$CONF" 2>/dev/null | sed -u "$sed_dict" &
            bg_pid=$!
        fi
        sleep 1
    else
        if [ -n "$bg_pid" ]; then
            kill "$bg_pid" 2>/dev/null
            pkill -P $$ -x cava 2>/dev/null
            wait "$bg_pid" 2>/dev/null
            bg_pid=""
            echo "$idle_output"
        fi
        timeout 5s pactl subscribe 2>/dev/null | grep --line-buffered "sink-input" | head -n 1 >/dev/null
    fi
done
