#!/usr/bin/env bash

set -euo pipefail

# GTK3 reloads its named theme when gtk-theme changes.
gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'
sleep 0.2
gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark-matugen'

# GTK4 has no generic trigger that rereads ~/.config/gtk-4.0/gtk.css.
# GTK4 consumers reload their own generated files or update on restart.
