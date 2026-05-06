<div align="center">

# Horizon's Arch Linux Dotfiles

[![Typing SVG](https://readme-typing-svg.demolab.com?font=JetBrains+Mono&weight=600&size=22&pause=1000&color=00A9FF&center=true&vCenter=true&width=600&lines=Welcome+to+my+Arch+Linux+configuration;A+hand-tuned+setup+centered+around+Hyprland)](https://git.io/typing-svg)

![Arch Linux](https://img.shields.io/badge/Arch_Linux-1793D1?style=for-the-badge&logo=arch-linux&logoColor=white)
![Hyprland](https://img.shields.io/badge/Hyprland-00DACF?style=for-the-badge&logo=hyprland&logoColor=white)
</div>

---

## System Overview

| Component | Choice |
| :--- | :--- |
| **OS** | Arch GNU/Linux |
| **WM** | Hyprland (Wayland) |
| **Status Bar** | Waybar (Liquid Glass) |
| **Shell** | Fish |
| **Terminal** | Ghostty |
| **AUR Helper** | yay |
| **Snapshots** | btrfs-assistant |

---

## Personal & Collaborative Projects

I've written a handful of small tools along the way to perfect this workflow. All tools below require a window to render; see the `windowrule` entries in `./hypr/hyprland.conf` for details.

### [Hypr-Wallpicker](https://github.com/Horizon0427/hypr-wallpicker)
A fast, lightweight wallpaper selector written in **C** with [Raylib](https://www.raylib.com/). 
> *Currently collaborating with [GrandBIRDLizard](https://github.com/GrandBIRDLizard) to refine it along UNIX-philosophy lines and publish it to the AUR.*

### Hypr-Prelock
A small, smooth pre-lock animation written in **C** with Raylib. 
Launch it through `./hypr/scripts/smart_lock.sh` — a tiny lock pattern spins briefly before `hyprlock` takes over.

### Hypr-Longshot
A scrolling-screenshot tool for Hyprland, written in **Python** (OpenCV) and **C** (Raylib). 
Run it through `./hypr/scripts/screenshot.sh`, or wire the script into a Waybar module for one-click capture.

---

## Customizations & Theming

<details>
<summary><b> Waybar — Liquid Glass</b> (Click to expand)</summary>

Thanks to Hyprland's precise transparency-filtering capabilities, Waybar is themed with a translucent, liquid-glass effect. Two configurations live under `./waybar/`:
- **Toggle:** `./waybar/scripts/toggle-waybar.sh`
- **Reload:** `./waybar/scripts/reload-waybar.sh`
</details>

<details>
<summary><b> Matugen Color Palette</b> (Click to expand)</summary>

[Matugen](https://github.com/InioX/matugen) extracts a Material You color palette from the current wallpaper and propagates it across the system:
- Waybar, Hyprland, Mako, Wlogout, Btop
- Hypr-Prelock, Hyprlock
- Ghostty (along with Starship, Fastfetch, and Yazi)

*Special thanks to [Shorin's templates](https://github.com/SHORiN-KiWATA/shorin-niri/tree/main/dotfiles/.config/matugen/templates/gtk-folder) for dynamic Thunar folder icons.*
</details>

---

## Gallery
