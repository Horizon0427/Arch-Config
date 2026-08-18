#!/bin/bash

rm -f /tmp/prelock_unlocked

prelock_bin="$HOME/.local/bin/prelock"
prelock_output=""
if command -v hyprctl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    prelock_output="$(hyprctl activeworkspace -j 2>/dev/null | jq -r '.monitor // empty' 2>/dev/null)"
fi

runtime_root="${XDG_RUNTIME_DIR:-/tmp}"
ready_dir="$(mktemp -d "$runtime_root/prelock-ready.XXXXXX" 2>/dev/null)"
ready_fifo=""

if [[ -n "$ready_dir" ]] && mkfifo -m 600 "$ready_dir/ready"; then
    ready_fifo="$ready_dir/ready"
    exec {ready_fd}<>"$ready_fifo"
    PRELOCK_OUTPUT="$prelock_output" PRELOCK_READY_FIFO="$ready_fifo" \
        "$prelock_bin" "$@" &
    IFS= read -r -t 4 -u "$ready_fd" || true
    exec {ready_fd}>&-
    rm -f -- "$ready_fifo"
    rmdir -- "$ready_dir" 2>/dev/null || true
else
    [[ -n "$ready_dir" ]] && rmdir -- "$ready_dir" 2>/dev/null || true
    PRELOCK_OUTPUT="$prelock_output" \
        "$prelock_bin" "$@" &
    sleep 2.5
fi

hyprlock

touch /tmp/prelock_unlocked
