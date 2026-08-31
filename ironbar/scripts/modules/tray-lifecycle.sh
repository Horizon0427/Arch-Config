#!/usr/bin/env bash

set -uo pipefail

readonly ipc_timeout=0.8
readonly settle_delay=0.08

ironbar_ipc() {
    timeout "$ipc_timeout" ironbar "$@" >/dev/null 2>&1
}

popup_visible() {
    local bar_name=$1 state

    state=$(timeout "$ipc_timeout" ironbar bar "$bar_name" get-popup-visible 2>/dev/null) || return 1
    [[ "$state" == "true" ]]
}

set_reset() {
    ironbar_ipc style add-class "$1" tray-reset || true
}

clear_reset() {
    ironbar_ipc style remove-class "$1" tray-reset || true
}

hide_popup() {
    ironbar_ipc bar "$1" hide-popup || true
}

monitor_tray_actions() {
    exec dbus-monitor --session \
        "type='method_call',interface='com.canonical.dbusmenu',member='Event',arg1='clicked'" \
        "type='method_call',interface='org.kde.StatusNotifierItem',member='Activate'" \
        "type='method_call',interface='org.kde.StatusNotifierItem',member='SecondaryActivate'"
}

watch_popup() {
    local bar_name=$1 module_name=$2 event_pid event_fd line

    coproc TRAY_EVENTS { monitor_tray_actions 2>/dev/null; }
    event_pid=$TRAY_EVENTS_PID
    event_fd=${TRAY_EVENTS[0]}

    while popup_visible "$bar_name"; do
        if IFS= read -r -t 0.12 -u "$event_fd" line \
            && [[ "$line" == method\ call* ]]; then
            sleep "$settle_delay"
            hide_popup "$bar_name"
        elif ! kill -0 "$event_pid" 2>/dev/null; then
            sleep 0.12
        fi
    done

    kill "$event_pid" 2>/dev/null || true
    wait "$event_pid" 2>/dev/null || true
    set_reset "$module_name"
}

toggle_popup() {
    local bar_name=$1 module_name=$2

    if popup_visible "$bar_name"; then
        hide_popup "$bar_name"
        set_reset "$module_name"
        return
    fi

    clear_reset "$module_name"
    ironbar_ipc bar "$bar_name" show-popup "$module_name" || return 1
    watch_popup "$bar_name" "$module_name"
}

watch_reset() {
    local module_name=$1 line

    printf '\n'

    while :; do
        while IFS= read -r line; do
            if [[ "$line" == method\ call* ]]; then
                sleep "$settle_delay"
                set_reset "$module_name"
            fi
        done < <(monitor_tray_actions 2>/dev/null)
        sleep 1
    done
}

case ${1:-} in
    toggle)
        [[ $# -eq 3 ]] || exit 2
        toggle_popup "$2" "$3"
        ;;
    clear)
        [[ $# -eq 2 ]] || exit 2
        clear_reset "$2"
        ;;
    watch-reset)
        [[ $# -eq 2 ]] || exit 2
        watch_reset "$2"
        ;;
    *)
        printf 'Usage: %s {toggle BAR MODULE|clear MODULE|watch-reset MODULE}\n' "$0" >&2
        exit 2
        ;;
esac
