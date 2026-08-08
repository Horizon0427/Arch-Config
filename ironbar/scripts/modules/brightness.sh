#!/usr/bin/env bash

backlight_device="${IRONBAR_BACKLIGHT_DEVICE:-intel_backlight}"
brightness_cmd=(brightnessctl)

if brightnessctl -d "$backlight_device" -m >/dev/null 2>&1; then
    brightness_cmd+=(-d "$backlight_device")
fi

current_percent() {
    "${brightness_cmd[@]}" -m 2>/dev/null \
        | awk -F, 'NR == 1 { gsub(/%/, "", $4); print $4 }'
}

status_icon() {
    local brightness

    brightness=$(current_percent)
    [[ "$brightness" =~ ^[0-9]+$ ]] || brightness=100

    if ((brightness >= 88)); then printf '\n'
    elif ((brightness >= 77)); then printf '\n'
    elif ((brightness >= 66)); then printf '\n'
    elif ((brightness >= 55)); then printf '\n'
    elif ((brightness >= 44)); then printf '\n'
    elif ((brightness >= 33)); then printf '\n'
    elif ((brightness >= 22)); then printf '\n'
    elif ((brightness >= 11)); then printf '\n'
    else printf '\n'
    fi
}

case "${1:-status}" in
    status) status_icon ;;
    up)     "${brightness_cmd[@]}" set +5% >/dev/null ;;
    down)   "${brightness_cmd[@]}" set 5%- >/dev/null ;;
    *)
        printf 'Usage: %s {status|up|down}\n' "$0" >&2
        exit 2
        ;;
esac
