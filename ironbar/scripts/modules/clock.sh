#!/usr/bin/env bash

watch_format() {
    local format="$1"
    local now wait_seconds

    while true; do
        date +"$format"

        now=$(date +%s)
        wait_seconds=$((60 - now % 60))
        sleep "$wait_seconds"
    done
}

watch_time() {
    watch_format '%H:%M'
}

case "${1:-time}" in
    time)         date +'%H:%M' ;;
    hour)         date +'%H' ;;
    minute)       date +'%M' ;;
    watch)        watch_time ;;
    watch-hour)   watch_format '%H' ;;
    watch-minute) watch_format '%M' ;;
    date)         date +'%Y-%m-%d %A' ;;
    *)
        printf 'Usage: %s {time|hour|minute|watch|watch-hour|watch-minute|date}\n' "$0" >&2
        exit 2
        ;;
esac
