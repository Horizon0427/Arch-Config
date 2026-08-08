#!/bin/bash

set -u

ENTRY="$HOME/.config/hypr/hyprland.lua"
PROFILE_DIR="$HOME/.config/hypr/configuration"

notify() { notify-send -a "Hyprland" -t 2000 -h string:x-canonical-private-synchronous:hypr-anim "$@"; }
fail()   { notify-send -a "Hyprland" -u critical -h string:x-canonical-private-synchronous:hypr-anim "动画切换失败" "$1"; exit 1; }

[[ -f "$ENTRY" ]] || fail "找不到 $ENTRY"

current=$(sed -nE 's/^[[:space:]]*require\("configuration\.(animations[0-9]*)"\).*/\1/p' "$ENTRY" | head -1)
[[ -n "$current" ]] || fail "$ENTRY 里找不到 require(\"configuration.animations…\")"

case "${1:-toggle}" in
    1) module="animations"  ;;
    2) module="animations2" ;;
    toggle)
        if [[ "$current" == "animations" ]]; then
            module="animations2"
        else
            module="animations"
        fi
        ;;
    *) fail "未知参数: $1" ;;
esac

case "$module" in
    animations)  label="Soft Bezier" ;;
    animations2) label="Quiet Spring" ;;
esac

profile="$PROFILE_DIR/$module.lua"
[[ -f "$profile" ]] || fail "找不到 $profile"

if command -v luac >/dev/null 2>&1; then
    luac -p "$profile" 2>/dev/null || fail "$module.lua 语法错误"
fi

if [[ "$module" != "$current" ]]; then
    sed -i -E "s|^([[:space:]]*)require\(\"configuration\.animations[0-9]*\"\)|\1require(\"configuration.$module\")|" "$ENTRY" \
        || fail "改写 $ENTRY 失败"
fi

result=$(hyprctl reload 2>&1)
[[ "$result" == ok* ]] || fail "hyprctl reload: ${result:-无响应}"

notify "Animation changed" "Current: $label"
