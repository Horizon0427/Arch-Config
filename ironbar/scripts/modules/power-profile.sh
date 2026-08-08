#!/usr/bin/env bash

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
colors_file="${script_dir}/../../colors.css"

profile_color() {
    awk -v name="$1" '
        $1 == "@define-color" && $2 == name {
            gsub(/;/, "", $3)
            print $3
            exit
        }
    ' "$colors_file" 2>/dev/null
}

current_profile() {
    local profile

    read -r profile </sys/firmware/acpi/platform_profile 2>/dev/null \
        || profile="power-saver"
    printf '%s\n' "${profile:-power-saver}"
}

profile_class() {
    case "$1" in
        balanced)    printf 'profile-balanced\n' ;;
        performance) printf 'profile-performance\n' ;;
        *)           printf 'profile-powersaver\n' ;;
    esac
}

profile_markup() {
    local profile="$1"
    local tertiary="$2"
    local error="$3"
    local primary="$4"

    case "$profile" in
        balanced)    printf "<span color='%s'></span>\n" "${tertiary:-#b0c9e7}" ;;
        performance) printf "<span color='%s'></span>\n" "${error:-#ffb4ab}" ;;
        *)           printf "<span color='%s'></span>\n" "${primary:-#81d5ce}" ;;
    esac
}

set_runtime_class() {
    local class="$1"
    local previous_class="$2"

    if [[ -n "$previous_class" ]]; then
        timeout 0.5s ironbar style remove-class power-btn "$previous_class" \
            >/dev/null 2>&1 || return 1
    fi
    timeout 0.5s ironbar style add-class power-btn "$class" >/dev/null 2>&1
}

set_runtime_class_with_retry() {
    local class="$1"
    local previous_class="$2"

    # The first IPC call can race the module being attached during startup.
    # Keep the retry bounded and event-local; there is no background polling.
    for _ in {1..5}; do
        if set_runtime_class "$class" "$previous_class"; then
            return 0
        fi
        sleep 0.05
    done

    return 1
}

watch_profile() {
    local tertiary error primary profile class event
    local last_profile="" last_class=""

    tertiary=$(profile_color tertiary)
    error=$(profile_color error)
    primary=$(profile_color primary)

    while true; do
        profile=$(current_profile)
        if [[ "$profile" != "$last_profile" ]]; then
            profile_markup "$profile" "$tertiary" "$error" "$primary" || exit 0
            last_profile="$profile"
        fi
        class=$(profile_class "$profile")
        if [[ "$class" != "$last_class" ]]; then
            if set_runtime_class_with_retry "$class" "$last_class"; then
                last_class="$class"
            fi
        fi

        while IFS= read -r event; do
            case "$event" in
                *"ActiveProfile"*)
                    profile=$(current_profile)
                    if [[ "$profile" != "$last_profile" ]]; then
                        profile_markup "$profile" "$tertiary" "$error" "$primary" || exit 0
                        last_profile="$profile"
                    fi

                    class=$(profile_class "$profile")
                    if [[ "$class" != "$last_class" ]] \
                        && set_runtime_class_with_retry "$class" "$last_class"; then
                        last_class="$class"
                    fi
                    ;;
            esac
        done < <(
            gdbus monitor --system \
                --dest net.hadess.PowerProfiles \
                --object-path /net/hadess/PowerProfiles \
                2>/dev/null
        )

        # Reconnect only if the daemon or system bus disappears.
        sleep 1
    done
}

toggle_profile() {
    case "$(current_profile)" in
        balanced)    powerprofilesctl set performance ;;
        performance) powerprofilesctl set power-saver ;;
        *)           powerprofilesctl set balanced ;;
    esac
}

case "${1:-current}" in
    watch)   watch_profile ;;
    current) current_profile ;;
    toggle)  toggle_profile ;;
    *)
        printf 'Usage: %s {watch|current|toggle}\n' "$0" >&2
        exit 2
        ;;
esac
