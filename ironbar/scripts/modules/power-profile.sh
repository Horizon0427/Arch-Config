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

rail_spine_enabled() {
    [[ "${IRONBAR_RAIL_PROFILE:-0}" == 1 ]]
}

rail_spine_color() {
    local profile="$1"
    local tertiary="$2"
    local error="$3"
    local primary="$4"

    case "$profile" in
        balanced)    printf '%s\n' "${tertiary:-#b0c9e7}" ;;
        performance) printf '%s\n' "${error:-#ffb4ab}" ;;
        *)           printf '%s\n' "${primary:-#81d5ce}" ;;
    esac
}

rail_spine_css_path() {
    printf '%s/ironbar-left-profile.css\n' \
        "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
}

write_rail_spine_css() {
    local profile="$1"
    local tertiary="$2"
    local error="$3"
    local primary="$4"
    local color css_file

    rail_spine_enabled || return 0

    color=$(rail_spine_color "$profile" "$tertiary" "$error" "$primary")
    css_file=$(rail_spine_css_path)
    umask 077

    # Keep one uniform profile-coloured glow along the whole spine. Node and
    # icon animations carry the local interaction; the line stays quiet.
    printf '%s\n' \
        '#bar {' \
        '    background-image:' \
        "        linear-gradient(to right, transparent 1px, alpha(${color}, 0.00) 1px, alpha(${color}, 0.08) 5px, alpha(${color}, 0.20) 8px, alpha(${color}, 0.08) 11px, alpha(${color}, 0.00) 15px, transparent 15px)," \
        "        linear-gradient(to right, transparent 7px, alpha(${color}, 0.34) 7px, alpha(${color}, 0.42) 8px, transparent 9px);" \
        '}' >"$css_file"
}

load_rail_spine_css_with_retry() {
    local css_file

    rail_spine_enabled || return 0
    css_file=$(rail_spine_css_path)

    # The module can emit before Ironbar's IPC endpoint is ready. Loading the
    # sheet once is enough: Ironbar then watches this path for profile updates.
    for _ in {1..5}; do
        if timeout 0.5s ironbar style load-css "$css_file" >/dev/null 2>&1; then
            return 0
        fi
        sleep 0.05
    done

    return 1
}

blade_strip_enabled() {
    [[ "${IRONBAR_BLADE_PROFILE:-0}" == 1 ]]
}

blade_strip_css_path() {
    printf '%s/ironbar-right-profile.css\n' \
        "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
}

write_blade_strip_css() {
    local profile="$1"
    local tertiary="$2"
    local error="$3"
    local primary="$4"
    local color css_file

    blade_strip_enabled || return 0

    color=$(rail_spine_color "$profile" "$tertiary" "$error" "$primary")
    css_file=$(blade_strip_css_path)
    umask 077

    # The whole carrier follows the selected profile. Three same-colour ramps
    # concentrate the optical cut beside the icons, then disperse smoothly to
    # full transparency at the screen edge.
    printf '%s\n' \
        '#bar {' \
        '    background-image:' \
        "        linear-gradient(to right, transparent 0, transparent 27px, alpha(${color}, 0.52) 27px, alpha(${color}, 0.38) 30px, alpha(${color}, 0.25) 33px, alpha(${color}, 0.14) 37px, alpha(${color}, 0.055) 41px, alpha(${color}, 0.00) 44px)," \
        "        linear-gradient(to right, transparent 0, transparent 27px, alpha(${color}, 0.40) 27px, alpha(${color}, 0.25) 29px, alpha(${color}, 0.12) 32px, alpha(${color}, 0.040) 36px, alpha(${color}, 0.00) 40px, transparent 44px)," \
        "        linear-gradient(to right, transparent 0, transparent 27px, alpha(${color}, 0.34) 27px, alpha(${color}, 0.12) 29px, alpha(${color}, 0.00) 31px, transparent 44px);" \
        '    background-repeat: no-repeat;' \
        '    background-size: 100% 100%, 100% 100%, 100% 100%;' \
        '    background-position: left top, left top, left top;' \
        '}' >"$css_file"
}

load_blade_strip_css_with_retry() {
    local css_file

    blade_strip_enabled || return 0
    css_file=$(blade_strip_css_path)

    for _ in {1..5}; do
        if timeout 0.5s ironbar style load-css "$css_file" >/dev/null 2>&1; then
            return 0
        fi
        sleep 0.05
    done

    return 1
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
    local last_profile="" last_class="" spine_css_loaded=0 blade_css_loaded=0

    tertiary=$(profile_color tertiary)
    error=$(profile_color error)
    primary=$(profile_color primary)

    while true; do
        profile=$(current_profile)
        if [[ "$profile" != "$last_profile" ]]; then
            profile_markup "$profile" "$tertiary" "$error" "$primary" || exit 0
            write_rail_spine_css "$profile" "$tertiary" "$error" "$primary"
            write_blade_strip_css "$profile" "$tertiary" "$error" "$primary"
            last_profile="$profile"
        fi
        if rail_spine_enabled && ((spine_css_loaded == 0)); then
            if load_rail_spine_css_with_retry; then
                spine_css_loaded=1
            fi
        fi
        if blade_strip_enabled && ((blade_css_loaded == 0)); then
            if load_blade_strip_css_with_retry; then
                blade_css_loaded=1
            fi
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
                        write_rail_spine_css "$profile" "$tertiary" "$error" "$primary"
                        write_blade_strip_css "$profile" "$tertiary" "$error" "$primary"
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
