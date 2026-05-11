#!/bin/bash
# 通过 hyprctl eval 运行时切换布局（兼容新版 Lua 解析器，hyprctl keyword 已废弃）

CURRENT=$(hyprctl getoption general:layout | awk '/^str:/ { print $2 }')

case "$CURRENT" in
    scrolling)
        hyprctl eval 'hl.config({general = {layout = "dwindle"}})'
        notify-send -a "Hyprland" -t 2000 "布局已切换" "当前布局: Dwindle"
        ;;
    dwindle)
        hyprctl eval 'hl.config({general = {layout = "scrolling"}})'
        notify-send -a "Hyprland" -t 2000 "布局已切换" "当前布局: Scrolling"
        ;;
    *)
        notify-send -u critical -a "Hyprland" "布局切换失败" "未能识别当前布局: $CURRENT"
        ;;
esac
