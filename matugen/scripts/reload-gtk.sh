#!/usr/bin/env bash

# GTK3 (Wayland backend): gtk-theme toggle forces CSS reload from disk
gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'
# sleep 0.3
gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark-matugen'

# GTK4 / libadwaita: color-scheme toggle forces full CSS reinitialize
gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'
# sleep 0.2
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
