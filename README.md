# Horizon's Arch Linux Dotfiles

Welcome to my personal Arch Linux configuration repository — a focused, hand-tuned setup centered around Hyprland and a handful of small tools I've written along the way.

## System Overview

| Component         | Choice              |
| ----------------- | ------------------- |
| Operating System  | Arch GNU/Linux      |
| Window Manager    | Hyprland (Wayland)  |
| Status Bar        | Waybar              |
| Shell             | Fish                |
| Terminal Emulator | Ghostty             |

## Personal & Collaborative Projects

### Hypr-Wallpicker

A fast, lightweight wallpaper selector written in **C** with [Raylib](https://www.raylib.com/).
The project has its own [standalone repository](https://github.com/Horizon0427/hypr-wallpicker), and I'm currently collaborating with [GrandBIRDLizard](https://github.com/GrandBIRDLizard) to refine it along UNIX-philosophy lines and publish it to the AUR.

### Hypr-Prelock

A small, smooth pre-lock animation written in **C** with Raylib.
Launch it through `./hypr/scripts/smart_lock.sh` — a tiny lock pattern spins briefly before `hyprlock` takes over.

### Hypr-Longshot

A scrolling-screenshot tool for Hyprland, written in **Python** (OpenCV) and **C** (Raylib).
Run it through `./hypr/scripts/screenshot.sh`, or wire the script into a Waybar module for one-click capture.

> All three tools above require a window in order to render. See the relevant `windowrule` entries in `./hypr/hyprland.conf` for details.

## Customizations of Upstream Tools

### Waybar — Liquid Glass

Thanks to Hyprland's precise transparency-filtering capabilities, Waybar is themed with a translucent, liquid-glass effect.
Two Waybar configurations live under `./waybar/`:

- Toggle between them — `./waybar/scripts/toggle-waybar.sh`
- Reload the active one — `./waybar/scripts/reload-waybar.sh`

### Matugen

[Matugen](https://github.com/InioX/matugen) extracts a Material You color palette from the current wallpaper and propagates it to:

- Waybar
- Hyprland
- Mako
- Wlogout
- Btop
- Hypr-Prelock
- Hyprlock
- Ghostty (along with Starship, Fastfetch, and Yazi)

Special thanks to [Shorin's templates](https://github.com/SHORiN-KiWATA/shorin-niri/tree/main/dotfiles/.config/matugen/templates/gtk-folder) — Thunar folder icons follow the active theme as well.

## Screenshots

*Coming soon.*
