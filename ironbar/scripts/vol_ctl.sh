#!/bin/bash
sink=$(pactl list sinks short 2>/dev/null | awk '/RUNNING/{print $2; exit}')
[ -z "$sink" ] && sink=$(pactl info 2>/dev/null | awk '/Default Sink:/{print $3}')
case "$1" in
    up)   pactl set-sink-volume "$sink" +2% ;;
    down) pactl set-sink-volume "$sink" -2% ;;
    mute) pactl set-sink-mute   "$sink" toggle ;;
esac
