#!/bin/bash

CONFIG_FILE="$HOME/.config/hypr/hyprland.conf"

if grep -q "layout = scrolling" "$CONFIG_FILE"; then
  sed -i 's/layout = scrolling/layout = dwindle/' "$CONFIG_FILE"
  notify-send -a "Hyprland" -t 2000 "布局已切换" "当前布局: Dwindle"
elif grep -q "layout = dwindle" "$CONFIG_FILE"; then
  sed -i 's/layout = dwindle/layout = scrolling/' "$CONFIG_FILE"
  notify-send -a "Hyprland" -t 2000 "布局已切换" "当前布局: Scrolling"
else
  notify-send -u critical -a "Hyprland" "布局切换失败" "未在配置文件中找到预期的 layout 字段"
fi
