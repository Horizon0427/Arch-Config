#!/usr/bin/env bash

shopt -s nullglob

batteries=(/sys/class/power_supply/BAT*)
if ((${#batteries[@]} == 0)); then
    printf 'N/A \n'
    exit 0
fi

capacity_file="${batteries[0]}/capacity"
status_file="${batteries[0]}/status"

read -r capacity <"$capacity_file" 2>/dev/null || capacity=0
read -r status <"$status_file" 2>/dev/null || status="Unknown"

[[ "$capacity" =~ ^[0-9]+$ ]] || capacity=0

if [[ "$status" == "Charging" ]]; then
    icon=""
elif ((capacity >= 90)); then
    icon=""
elif ((capacity >= 60)); then
    icon=""
elif ((capacity >= 30)); then
    icon=""
elif ((capacity >= 15)); then
    icon=""
else
    icon=""
fi

printf '%s%% %s\n' "$capacity" "$icon"
