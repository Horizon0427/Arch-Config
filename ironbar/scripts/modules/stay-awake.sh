#!/usr/bin/env bash

set -u

readonly unit="ironbar-stay-awake.service"
readonly unit_path="/org/freedesktop/systemd1/unit/ironbar_2dstay_2dawake_2eservice"
readonly widget_name="stay-awake-btn"
readonly active_class="stay-awake-active"

is_active() {
    systemctl --user is-active --quiet "$unit"
}

state_name() {
    if is_active; then
        printf 'active\n'
    else
        printf 'inactive\n'
    fi
}

state_icon() {
    if [[ "$1" == active ]]; then
        printf '\n'
    else
        printf '\n'
    fi
}

apply_runtime_class() {
    local state=$1

    if [[ "$state" == active ]]; then
        timeout 0.5s ironbar style add-class "$widget_name" "$active_class" \
            >/dev/null 2>&1
    else
        timeout 0.5s ironbar style remove-class "$widget_name" "$active_class" \
            >/dev/null 2>&1
    fi
}

apply_runtime_class_with_retry() {
    local state=$1

    for _ in {1..5}; do
        if apply_runtime_class "$state"; then
            return 0
        fi
        sleep 0.05
    done
    return 1
}

emit_state() {
    local state=$1

    state_icon "$state"
    apply_runtime_class_with_retry "$state" || true
}

watch_state() {
    local state last_state="" event

    while true; do
        state=$(state_name)
        if [[ "$state" != "$last_state" ]]; then
            emit_state "$state"
            last_state=$state
        fi

        while IFS= read -r event; do
            case "$event" in
                *"PropertiesChanged"*|*"ActiveState"*)
                    state=$(state_name)
                    if [[ "$state" != "$last_state" ]]; then
                        emit_state "$state"
                        last_state=$state
                    fi
                    ;;
            esac
        done < <(
            gdbus monitor --session \
                --dest org.freedesktop.systemd1 \
                --object-path "$unit_path" \
                2>/dev/null
        )

        sleep 0.5
    done
}

toggle_state() {
    if is_active; then
        systemctl --user stop "$unit"
    else
        systemctl --user start "$unit"
    fi
}

status_text() {
    if is_active; then
        printf 'Stay awake · on\n'
    else
        printf 'Stay awake · off\n'
    fi
}

case "${1:-status}" in
    watch)  watch_state ;;
    toggle) toggle_state ;;
    status) status_text ;;
    *)
        printf 'Usage: %s {watch|toggle|status}\n' "$0" >&2
        exit 2
        ;;
esac
