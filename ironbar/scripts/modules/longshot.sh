#!/usr/bin/env bash

longshot_bin="${IRONBAR_LONGSHOT_BIN:-/home/horizon/python-projects/hypr-longshot/longshot.sh}"
longshot_log="${XDG_RUNTIME_DIR:-/tmp}/ironbar-longshot.log"

current_status() {
    local status

    status=$("$longshot_bin" status 2>/dev/null) || status="idle"
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
    # Ironbar's command runner may tear down the command's process group as
    # soon as this wrapper exits.  stop/cancel need to outlive the wrapper so
    # they can wait for wf-recorder and then close the overlay.
    setsid -f "$longshot_bin" "$1" </dev/null >>"$longshot_log" 2>&1
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
