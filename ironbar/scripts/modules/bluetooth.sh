#!/usr/bin/env bash

status_icon() {
    if rfkill list bluetooth 2>/dev/null | grep -q 'Soft blocked: yes' \
        || ! bluetoothctl show 2>/dev/null | grep -q 'Powered: yes'; then
        printf '󰂲\n'
    elif bluetoothctl devices Connected 2>/dev/null | grep -q .; then
        printf '󰂱\n'
    else
        printf '󰂯\n'
    fi
}

connected_devices() {
    local devices

    devices=$(
        bluetoothctl devices Connected 2>/dev/null \
            | sed 's/^Device [^ ]* //' \
            | paste -sd ',' - \
            | sed 's/,/, /g'
    )

    printf '%s\n' "${devices:-No device connected}"
}

watch_status() {
    local event

    status_icon

    while true; do
        while IFS= read -r event; do
            case "$event" in
                *"member=PropertiesChanged"*|\
                *"member=InterfacesAdded"*|\
                *"member=InterfacesRemoved"*|\
                *"member=NameOwnerChanged"*)
                    while IFS= read -r -t 0.05 event; do :; done
                    status_icon
                    ;;
            esac
        done < <(
            dbus-monitor --system \
                "type='signal',sender='org.bluez',interface='org.freedesktop.DBus.Properties'" \
                "type='signal',sender='org.bluez',interface='org.freedesktop.DBus.ObjectManager'" \
                "type='signal',interface='org.freedesktop.DBus',member='NameOwnerChanged',arg0='org.bluez'" \
                2>/dev/null
        )

        sleep 1
        status_icon
    done
}

case "${1:-status}" in
    status)  status_icon ;;
    watch)   watch_status ;;
    tooltip) connected_devices ;;
    open)
        blueman-manager >/dev/null 2>&1 &
        ;;
    *)
        printf 'Usage: %s {status|watch|tooltip|open}\n' "$0" >&2
        exit 2
        ;;
esac
