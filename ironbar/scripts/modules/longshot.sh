#!/usr/bin/env bash

if [[ -n "${IRONBAR_LONGSHOT_BIN:-}" ]]; then
    longshot_cmd=("$IRONBAR_LONGSHOT_BIN")
else
    longshot_cmd=(
        /home/horizon/Projects/python-projects/hypr-longshot/.venv/bin/python
        /home/horizon/Projects/python-projects/hypr-longshot/longshot.py
    )
fi
longshot_log="${XDG_RUNTIME_DIR:-/tmp}/ironbar-longshot.log"

current_status() {
    local status

    status=$("${longshot_cmd[@]}" status 2>/dev/null) || status="idle"
    printf '%s\n' "${status:-idle}"
}

status_icon() {
    case "$(current_status)" in
        selecting) printf '󰆞\n' ;;
        recording) printf '\n' ;;
        stitching) printf '󰑮\n' ;;
        *)         printf '󰹑\n' ;;
    esac
}

run_async() {
    setsid -f "${longshot_cmd[@]}" "$1" </dev/null >>"$longshot_log" 2>&1
}

case "${1:-status}" in
    status) status_icon ;;
    toggle)
        case "$(current_status)" in
            idle)      run_async start ;;
            selecting) run_async cancel ;;
            recording) run_async stop ;;
            stitching) notify-send -u normal "Longshot" "正在拼接图像，请稍候" ;;
        esac
        ;;
    cancel) run_async cancel ;;
    *)
        printf 'Usage: %s {status|toggle|cancel}\n' "$0" >&2
        exit 2
        ;;
esac
