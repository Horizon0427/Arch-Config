#!/usr/bin/env bash

set -u

ironbar_root="${XDG_CONFIG_HOME:-$HOME/.config}/ironbar"
lock_file="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/ironbar-control.lock"

ironbar_server_pids() {
    ps -C ironbar -o pid=,stat=,args= 2>/dev/null \
        | awk '$2 !~ /^Z/ && $0 ~ /\/(top|bottom|left|right)\/config\.toml/ { print $1 }'
}

ironbar_current_side() {
    local side

    side=$(
        ps -C ironbar -o stat=,args= 2>/dev/null \
            | awk '
                $1 !~ /^Z/ && match($0, /\/(top|bottom|left|right)\/config\.toml/, m) {
                    print m[1]
                    exit
                }
            '
    )
    printf '%s\n' "${side:-top}"
}

ironbar_start() {
    local side=${1:-top}

    case "$side" in
        top|bottom|left|right) ;;
        *) printf 'invalid side: %s\n' "$side" >&2; return 2 ;;
    esac

    if [[ -n "$(ironbar_server_pids)" ]]; then
        return 0
    fi

    # A dedicated session makes the bar and its ordinary module children one
    # safely targetable process group. Detached Longshot jobs use their own
    # sessions, so switching the bar does not interrupt an active capture.
    setsid -f env -u IRONBAR_CONTROL_LOCKED \
        GSK_RENDERER="${GSK_RENDERER:-gl}" \
        GDK_DISABLE="${GDK_DISABLE:-vulkan}" \
        ironbar \
            -c "$ironbar_root/$side/config.toml" \
            -t "$ironbar_root/$side/style.css" \
        >/dev/null 2>&1

    for _ in {1..75}; do
        [[ -n "$(ironbar_server_pids)" ]] && return 0
        sleep 0.01
    done

    return 1
}

ironbar_stop() {
    local pid pgid sid own_pgid
    local -a pids groups=()

    mapfile -t pids < <(ironbar_server_pids)
    ((${#pids[@]})) || return 0
    own_pgid=$(ps -o pgid= -p $$ | tr -d ' ')

    for pid in "${pids[@]}"; do
        read -r pgid sid < <(ps -o pgid=,sid= -p "$pid")
        if [[ "$pgid" == "$pid" && "$sid" == "$pid" && "$pgid" != "$own_pgid" ]]; then
            groups+=("$pgid")
            kill -TERM -- "-$pgid" 2>/dev/null || true
        else
            kill -TERM "$pid" 2>/dev/null || true
        fi
    done

    # Normal shutdown takes only a few milliseconds. Keep a short grace period
    # for cleanup, then bound recovery from a stuck GTK process.
    for _ in {1..40}; do
        [[ -z "$(ironbar_server_pids)" ]] && break
        sleep 0.01
    done

    for pgid in "${groups[@]}"; do
        kill -KILL -- "-$pgid" 2>/dev/null || true
    done
    mapfile -t pids < <(ironbar_server_pids)
    ((${#pids[@]} == 0)) || kill -KILL "${pids[@]}" 2>/dev/null || true

    for _ in {1..20}; do
        [[ -z "$(ironbar_server_pids)" ]] && return 0
        sleep 0.01
    done

    return 1
}

usage() {
    printf 'usage: %s {start [top|bottom|left|right]|stop|reload|toggle|status}\n' "$0" >&2
}

action=${1:-status}

# Serialize state transitions from Matugen, keybinds and manual invocations.
# --close prevents the launched bar from holding the lock for its lifetime.
if [[ "${IRONBAR_CONTROL_LOCKED:-0}" != 1 && "$action" != status ]]; then
    exec env IRONBAR_CONTROL_LOCKED=1 \
        flock --close --timeout 2 "$lock_file" "$0" "$@"
fi

case "$action" in
    start)
        ironbar_start "${2:-top}"
        ;;
    stop)
        ironbar_stop
        ;;
    reload)
        side=$(ironbar_current_side)
        ironbar_stop && ironbar_start "$side"
        ;;
    toggle)
        side=$(ironbar_current_side)
        case "$side" in
            left) next_side=top ;;
            top) next_side=bottom ;;
            bottom) next_side=right ;;
            right) next_side=left ;;
            *) next_side=left ;;
        esac
        if ironbar_stop; then
            ironbar_start "$next_side"
        fi
        ;;
    status)
        if [[ -n "$(ironbar_server_pids)" ]]; then
            ironbar_current_side
        else
            printf 'stopped\n'
        fi
        ;;
    *)
        usage
        exit 2
        ;;
esac
