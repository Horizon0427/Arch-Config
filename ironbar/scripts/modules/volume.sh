#!/usr/bin/env bash

active_sink() {
    local sink

    sink=$(pactl list sinks short 2>/dev/null | awk '/RUNNING/ { print $2; exit }')
    if [[ -z "$sink" ]]; then
        sink=$(pactl info 2>/dev/null | awk -F': ' '/Default Sink:/ { print $2; exit }')
    fi

    printf '%s\n' "$sink"
}

sink_volume() {
    local sink=$1 volume

    volume=$(
        pactl get-sink-volume "$sink" 2>/dev/null \
            | grep -oE '[0-9]+%' \
            | head -n 1 \
            | tr -d '%'
    )
    [[ "$volume" =~ ^[0-9]+$ ]] || volume=0

    printf '%s\n' "$volume"
}

status_line() {
    local sink volume muted active_port
    local is_headphones=0

    sink=$(active_sink)
    if [[ -z "$sink" ]]; then
        printf '0%% 󰕿\n'
        return
    fi

    volume=$(sink_volume "$sink")

    if pactl get-sink-mute "$sink" 2>/dev/null | grep -q 'yes'; then
        muted=1
    else
        muted=0
    fi

    if [[ "$sink" == *bluez* ]]; then
        is_headphones=1
    else
        active_port=$(
            pactl list sinks 2>/dev/null \
                | awk -v sink="$sink" '
                    /Name: / { in_sink = ($2 == sink) }
                    in_sink && /Active Port:/ { print $3; exit }
                '
        )
        [[ "$active_port" =~ headphone|headset|earphone ]] && is_headphones=1
    fi

    if ((muted)); then
        printf '%s%% 󰝟\n' "$volume"
    elif ((is_headphones)); then
        printf '%s%% 󰋋\n' "$volume"
    elif ((volume >= 30)); then
        printf '%s%% 󰕾\n' "$volume"
    elif ((volume >= 10)); then
        printf '%s%% 󰖀\n' "$volume"
    else
        printf '%s%% 󰕿\n' "$volume"
    fi
}

watch_status() {
    local event

    status_line

    # pactl subscribe stays idle until PipeWire/PulseAudio reports a relevant
    # change. Reconnect if the audio server is restarted.
    while true; do
        while IFS= read -r event; do
            case "$event" in
                *" on sink "*|*" on server "*|*" on card "*)
                    # A single user action can emit several related events.
                    # Drain the short burst, then render the final state once.
                    while IFS= read -r -t 0.03 event; do :; done
                    status_line
                    ;;
            esac
        done < <(pactl subscribe 2>/dev/null)

        sleep 1
        status_line
    done
}

change_volume() {
    local sink current target lock_fd
    local step=${IRONBAR_VOLUME_STEP:-2}
    local maximum=${IRONBAR_VOLUME_MAX:-100}
    local lock_file="${XDG_RUNTIME_DIR:-/tmp}/ironbar-volume-${UID}.lock"

    [[ "$step" =~ ^[1-9][0-9]*$ ]] || step=2
    [[ "$maximum" =~ ^[1-9][0-9]*$ ]] || maximum=100

    # Scroll events can overlap. Serialize the read/modify/write section so
    # fast scrolling neither loses steps nor races past the cap.
    exec {lock_fd}>"$lock_file" || return 1
    flock "$lock_fd" || return 1

    sink=$(active_sink)
    [[ -n "$sink" ]] || return 1

    case "$1" in
        up|down)
            current=$(sink_volume "$sink")
            if [[ "$1" == up ]]; then
                target=$((current + step))
            else
                target=$((current - step))
            fi

            ((target > maximum)) && target=$maximum
            ((target < 0)) && target=0
            pactl set-sink-volume "$sink" "${target}%"
            ;;
        mute) pactl set-sink-mute "$sink" toggle ;;
    esac
}

case "${1:-status}" in
    status) status_line ;;
    watch) watch_status ;;
    up|down|mute) change_volume "$1" ;;
    open)
        pavucontrol >/dev/null 2>&1 &
        ;;
    *)
        printf 'Usage: %s {status|watch|up|down|mute|open}\n' "$0" >&2
        exit 2
        ;;
esac
