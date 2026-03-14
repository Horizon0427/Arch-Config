#!/bin/bash

rm -f /tmp/prelock_unlocked

~/.config/hypr/lock_animation/my_prelock &

sleep 1.2

hyprlock

touch /tmp/prelock_unlocked
