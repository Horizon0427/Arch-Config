#!/bin/bash

umask 077

unlock_file="/tmp/prelock_unlocked"
prelock_bin="$HOME/.local/bin/prelock"
hyprlock_prelock_bin="${HYPRLOCK_PRELOCK_BIN:-$HOME/.local/libexec/prelock/hyprlock-prelock}"
stock_hyprlock_bin="${HYPRLOCK_STOCK_BIN:-/usr/bin/hyprlock}"
runtime_root="${XDG_RUNTIME_DIR:-/tmp}"

prelock_pid=""
hyprlock_pid=""
ready_dir=""
ready_fifo=""
transition_dir=""
release_fifo=""
outputs=()

close_ready_channel() {
    if [[ -n "${ready_fd:-}" ]]; then
        exec {ready_fd}>&-
        unset ready_fd
    fi
    [[ -n "$ready_fifo" ]] && rm -f -- "$ready_fifo"
    [[ -n "$ready_dir" ]] && rmdir -- "$ready_dir" 2>/dev/null || true
    ready_fifo=""
    ready_dir=""
}

close_release_channel() {
    if [[ -n "${release_fd:-}" ]]; then
        exec {release_fd}>&-
        unset release_fd
    fi
    [[ -n "$release_fifo" ]] && rm -f -- "$release_fifo"
    release_fifo=""
}

cleanup_transition() {
    local expected_prefix="${runtime_root%/}/prelock-transition."
    if [[ -n "$transition_dir" && "$transition_dir" == "$expected_prefix"* ]]; then
        rm -rf -- "$transition_dir"
    fi
    transition_dir=""
    outputs=()
}

stop_prelock_hidden() {
    local pid="${prelock_pid:-}"
    [[ -n "$pid" ]] || return

    prelock_pid=""
    if kill -0 "$pid" 2>/dev/null; then
        kill -TERM "$pid" 2>/dev/null || true
    fi
    wait "$pid" 2>/dev/null || true
}

fade_prelock_visible() {
    local pid="${prelock_pid:-}"
    [[ -n "$pid" ]] || return

    if kill -0 "$pid" 2>/dev/null; then
        touch "$unlock_file"
    fi
    wait "$pid" 2>/dev/null || true
    prelock_pid=""
}

cleanup() {
    close_ready_channel
    close_release_channel
    stop_prelock_hidden

    if [[ -z "${hyprlock_pid:-}" ]] || ! kill -0 "$hyprlock_pid" 2>/dev/null; then
        cleanup_transition
    fi
}

trap cleanup EXIT

capture_fade_out() {
    local output=""
    local target=""

    for output in "${outputs[@]}"; do
        target="$transition_dir/fade-out/$output.png"
        if ! grim -o "$output" -t png "$target"; then
            return 1
        fi
        if ! chmod 600 "$target"; then
            return 1
        fi
    done
}

prepare_transition() {
    local monitors_json=""
    local output_lines=""
    local output=""

    [[ -x "$hyprlock_prelock_bin" ]] || return 1
    command -v grim >/dev/null 2>&1 || return 1
    command -v hyprctl >/dev/null 2>&1 || return 1
    command -v jq >/dev/null 2>&1 || return 1

    transition_dir="$(mktemp -d "$runtime_root/prelock-transition.XXXXXX" 2>/dev/null)"
    [[ -n "$transition_dir" ]] || return 1
    mkdir -m 700 "$transition_dir/fade-out" || return 1

    monitors_json="$(hyprctl -j monitors 2>/dev/null)" || return 1
    output_lines="$(jq -er 'map(select(.disabled == false) | .name) | if length > 0 then .[] else error("no active outputs") end' <<<"$monitors_json")" || return 1
    mapfile -t outputs <<<"$output_lines"

    for output in "${outputs[@]}"; do
        if [[ ! "$output" =~ ^[A-Za-z0-9_.-]+$ || "$output" == "." || "$output" == ".." ]]; then
            return 1
        fi
    done

    capture_fade_out
}

launch_prelock() {
    local prelock_output=""

    if command -v hyprctl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
        prelock_output="$(hyprctl activeworkspace -j 2>/dev/null | jq -r '.monitor // empty' 2>/dev/null)"
    fi

    ready_dir="$(mktemp -d "$runtime_root/prelock-ready.XXXXXX" 2>/dev/null)"
    if [[ -n "$ready_dir" ]] && mkfifo -m 600 "$ready_dir/ready" &&
        exec {ready_fd}<>"$ready_dir/ready"; then
        ready_fifo="$ready_dir/ready"
        PRELOCK_OUTPUT="$prelock_output" PRELOCK_READY_FIFO="$ready_fifo" \
            "$prelock_bin" "$@" &
        prelock_pid=$!
        if IFS= read -r -t 4 -u "$ready_fd"; then
            close_ready_channel
            return 0
        fi
        close_ready_channel
        return 1
    fi

    close_ready_channel
    PRELOCK_OUTPUT="$prelock_output" "$prelock_bin" "$@" &
    prelock_pid=$!
    sleep 2.5
    return 1
}

run_stock_hyprlock() {
    local status=0

    if [[ ! -x "$stock_hyprlock_bin" ]]; then
        printf 'prelock: stock Hyprlock is unavailable: %s\n' "$stock_hyprlock_bin" >&2
        fade_prelock_visible
        return 127
    fi

    "$stock_hyprlock_bin"
    status=$?
    fade_prelock_visible
    return "$status"
}

open_release_channel() {
    release_fifo="$transition_dir/release"
    if ! mkfifo -m 600 "$release_fifo" || ! exec {release_fd}<>"$release_fifo"; then
        close_release_channel
        return 1
    fi
}

run_prelock_hyprlock() {
    local released=false
    local status=0
    local lock_state="unknown"

    HYPRLOCK_FADE_OUT_DIR="$transition_dir/fade-out" \
    HYPRLOCK_PRELOCK_RELEASE_FIFO="$release_fifo" \
        "$hyprlock_prelock_bin" &
    hyprlock_pid=$!

    while kill -0 "$hyprlock_pid" 2>/dev/null; do
        if IFS= read -r -t 0.1 -u "$release_fd"; then
            released=true
            stop_prelock_hidden
            close_release_channel
            cleanup_transition
            break
        fi
    done

    if [[ "$released" != true ]]; then
        close_release_channel
    fi
    wait "$hyprlock_pid"
    status=$?
    hyprlock_pid=""

    if [[ "$released" == true ]]; then
        return "$status"
    fi

    cleanup_transition
    if [[ "$status" -eq 0 ]]; then
        fade_prelock_visible
        return 0
    fi

    lock_state="$(hyprctl locked 2>/dev/null)" || lock_state="unknown"
    if [[ "$lock_state" == "false" ]]; then
        printf 'prelock: companion failed before locking; falling back to stock Hyprlock\n' >&2
        run_stock_hyprlock
        return $?
    fi

    printf 'prelock: companion failed after session-lock began; refusing to start a second locker\n' >&2
    stop_prelock_hidden
    return "$status"
}

rm -f "$unlock_file"

transition_prepared=false
if prepare_transition; then
    transition_prepared=true
else
    cleanup_transition
fi

prelock_ready=false
if launch_prelock "$@"; then
    prelock_ready=true
fi

if [[ "$transition_prepared" == true && "$prelock_ready" == true ]] &&
    open_release_channel; then
    run_prelock_hyprlock
    exit $?
fi

cleanup_transition
run_stock_hyprlock
exit $?
