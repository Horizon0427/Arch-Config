#!/usr/bin/env bash

set -u

chars="▁▂▃▄▅▆▇█"
bars=${IRONBAR_CAVA_BARS:-18}
framerate=${IRONBAR_CAVA_FRAMERATE:-60}
check_interval=${IRONBAR_CAVA_CHECK_INTERVAL:-1}
runtime_dir="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/ironbar-cava"
config_file="$runtime_dir/cava.conf"

[[ "$bars" =~ ^[1-9][0-9]*$ ]] || bars=18
[[ "$framerate" =~ ^[1-9][0-9]*$ ]] || framerate=60
[[ "$check_interval" =~ ^[1-9][0-9]*$ ]] || check_interval=1

mkdir -p -m 700 "$runtime_dir"

last_index=$((${#chars} - 1))
idle_char=${chars:0:1}
idle_output=$(printf "%0.s$idle_char" $(seq 1 "$bars"))

sed_dict="s/;//g;"
for ((i = 0; i <= last_index; i++)); do
    sed_dict="${sed_dict}s/$i/${chars:$i:1}/g;"
done

cava_pipeline_pid=""

stop_cava() {
    if [[ -n "$cava_pipeline_pid" ]]; then
        kill "$cava_pipeline_pid" 2>/dev/null || true
        pkill -P $$ -x cava 2>/dev/null || true
        wait "$cava_pipeline_pid" 2>/dev/null || true
        cava_pipeline_pid=""
    fi
}

cleanup() {
    trap - EXIT INT TERM
    stop_cava
}
trap cleanup EXIT INT TERM

is_audio_active() {
    pactl list sink-inputs 2>/dev/null | grep -q "Corked: no"
}

active_sink() {
    local sink

    sink=$(pactl list sinks short 2>/dev/null | awk '/RUNNING/ { print $2; exit }')
    if [[ -z "$sink" ]]; then
        sink=$(pactl info 2>/dev/null | awk -F': ' '/Default Sink:/ { print $2; exit }')
    fi

    printf '%s\n' "$sink"
}

write_config() {
    local sink=$1

    printf '%s\n' \
        '[general]' \
        "bars = $bars" \
        "framerate = $framerate" \
        'autosens = 1' \
        'sensitivity = 135' \
        '' \
        '[input]' \
        'method = pulse' \
        "source = ${sink}.monitor" \
        '' \
        '[output]' \
        'method = raw' \
        'raw_target = /dev/stdout' \
        'data_format = ascii' \
        "ascii_max_range = $last_index" \
        'channels = stereo' \
        '' \
        '[smoothing]' \
        'monstercat = 1' \
        'waves = 1' \
        'noise_reduction = 50' \
        >"$config_file"
}

start_cava() {
    local sink

    sink=$(active_sink)
    [[ -n "$sink" ]] || return 1

    write_config "$sink"
    cava -p "$config_file" 2>/dev/null | sed -u "$sed_dict" &
    cava_pipeline_pid=$!
}

printf '%s\n' "$idle_output"

while true; do
    if is_audio_active; then
        if [[ -z "$cava_pipeline_pid" ]] || ! kill -0 "$cava_pipeline_pid" 2>/dev/null; then
            stop_cava
            start_cava || true
        fi
        sleep "$check_interval"
    else
        if [[ -n "$cava_pipeline_pid" ]]; then
            stop_cava
            printf '%s\n' "$idle_output"
        fi

        timeout --foreground 5s pactl subscribe 2>/dev/null \
            | grep --line-buffered "sink-input" \
            | head -n 1 >/dev/null || true
    fi
done
