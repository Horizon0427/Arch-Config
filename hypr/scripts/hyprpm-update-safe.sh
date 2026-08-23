#!/usr/bin/env bash

set -Eeuo pipefail

target=/usr/share/pkgconfig/hyprland.pc
runtime_dir="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
temporary_root="$(mktemp -d "$runtime_dir/hyprpm-update-safe.XXXXXX")"
saved="$temporary_root/hyprland.pc"
saved_ready=false

cleanup() {
    case "$temporary_root" in
        "$runtime_dir"/hyprpm-update-safe.*) rm -rf -- "$temporary_root" ;;
    esac
}

finish() {
    local status=$?
    trap - EXIT
    if $saved_ready && ! cmp -s "$saved" "$target"; then
        printf '%s\n' 'Restoring package-owned /usr/share/pkgconfig/hyprland.pc'
        sudo /usr/bin/install -o root -g root -m644 "$saved" "$target" || status=1
    fi
    cleanup
    exit "$status"
}
trap finish EXIT

[[ "$(pacman -Qoq "$target")" == hyprland ]]
[[ "$(pkg-config --variable=prefix hyprland)" == /usr/include ]]
cp -a "$target" "$saved"
saved_ready=true

hyprpm update "$@"

[[ -r /var/cache/hyprpm/"$USER"/headersRoot/share/pkgconfig/hyprland.pc ]]
hyprpm list
