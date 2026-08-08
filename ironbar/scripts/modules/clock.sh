#!/usr/bin/env bash

watch_time() {
    local now wait_seconds

    while true; do
        date +'%H:%M'

        # Wake on the next minute boundary instead of polling twice a second.
        now=$(date +%s)
        wait_seconds=$((60 - now % 60))
        sleep "$wait_seconds"
    done
}

case "${1:-time}" in
    time) date +'%H:%M' ;;
    watch) watch_time ;;
    date) date +'%Y-%m-%d %A' ;;
    *)
        printf 'Usage: %s {time|watch|date}\n' "$0" >&2
        exit 2
        ;;
esac
