#!/usr/bin/env bash

ironvar_key="spotify_running"
last_running=""
last_icon=""

status_icon() {
    case "$1" in
        Playing) printf ' \n' ;;
        *)       printf '󰎆 \n' ;;
    esac
}

status() {
    local status

    status=$(playerctl --player=spotify status 2>/dev/null) || status=""
    status_icon "$status"
}

set_running_ironvar() {
    local value=$1

    for _ in {1..5}; do
        if timeout 0.5s ironbar var set "$ironvar_key" "$value" \
            >/dev/null 2>&1; then
            return 0
        fi
        sleep 0.05
    done

    return 1
}

sync_state() {
    local player_status running icon

    if player_status=$(playerctl --player=spotify status 2>/dev/null); then
        running=true
    else
        player_status=""
        running=false
    fi

    if [[ "$running" != "$last_running" ]] \
        && set_running_ironvar "$running"; then
        last_running="$running"
    fi

    case "$player_status" in
        Playing) icon="" ;;
        *)       icon="󰎆" ;;
    esac

    if [[ "$icon" != "$last_icon" ]]; then
        printf '%s \n' "$icon"
        last_icon="$icon"
    fi
}

watch_status() {
    local event

    sync_state

    while true; do
        while IFS= read -r event; do
            case "$event" in
                *"PropertiesChanged"*|\
                *"The name org.mpris.MediaPlayer2.spotify is owned by"*|\
                *"The name org.mpris.MediaPlayer2.spotify does not have an owner"*)
                    while IFS= read -r -t 0.03 event; do :; done
                    sync_state
                    ;;
            esac
        done < <(
            gdbus monitor --session \
                --dest org.mpris.MediaPlayer2.spotify \
                --object-path /org/mpris/MediaPlayer2 \
                2>/dev/null
        )

        sleep 1
        sync_state
    done
}

metadata() {
    local title artist

    title=$(playerctl --player=spotify metadata title 2>/dev/null) || title=""
    artist=$(playerctl --player=spotify metadata artist 2>/dev/null) || artist=""

    if [[ -n "$title" && -n "$artist" ]]; then
        printf '%s — %s\n' "$title" "$artist"
    else
        printf '%s\n' "${title:-$artist}"
    fi
}

case "${1:-status}" in
    is-running) playerctl --player=spotify status >/dev/null 2>&1 ;;
    status)     status ;;
    watch)      watch_status ;;
    metadata)   metadata ;;
    previous)   playerctl --player=spotify previous ;;
    toggle)     playerctl --player=spotify play-pause ;;
    next)       playerctl --player=spotify next ;;
    *)
        printf 'Usage: %s {is-running|status|watch|metadata|previous|toggle|next}\n' "$0" >&2
        exit 2
        ;;
esac
