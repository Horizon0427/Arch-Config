<div align="center">

# Horizon's Arch Linux Dotfiles

[![Typing SVG](https://readme-typing-svg.demolab.com?font=JetBrains+Mono&weight=600&size=22&pause=1000&color=00A9FF&center=true&vCenter=true&width=600&lines=Welcome+to+my+Arch+Linux+configuration;A+hand-tuned+setup+centered+around+Hyprland)](https://git.io/typing-svg)

![Arch Linux](https://img.shields.io/badge/Arch_Linux-1793D1?style=for-the-badge&logo=arch-linux&logoColor=white)
![Hyprland](https://img.shields.io/badge/Hyprland-00DACF?style=for-the-badge&logo=hyprland&logoColor=white)
</div>

---

## System Overview

| Component         | Choice              |
| ----------------- | ------------------- |
| Operating System  | Arch GNU/Linux      |
| Window Manager    | Hyprland (Wayland)  |
| Status Bar        | Waybar              |
| Shell             | Fish                |
| Terminal Emulator | Ghostty             |


---

## Personal & Collaborative Projects

I've written some small tools along the way to perfect this workflow. All tools below require a window to render; see the `windowrule` entries in `./hypr/hyprland.conf` for details.

### [Hypr-Wallpicker](https://github.com/Horizon0427/hypr-wallpicker)
A fast, lightweight wallpaper selector written in **C** with [Raylib](https://www.raylib.com/). 
> *Currently collaborating with [GrandBIRDLizard](https://github.com/GrandBIRDLizard) to refine it along UNIX-philosophy lines and publish it to the AUR.*

### Hypr-Prelock
A small, smooth pre-lock animation written in **C** with Raylib. 
Launch it through `./hypr/scripts/smart_lock.sh` — a tiny lock pattern spins briefly before `hyprlock` takes over.

### [Hypr-Longshot](https://github.com/Horizon0427/hypr-longshot)
A scrolling-screenshot tool for Hyprland, written in **Python** (OpenCV) and **C** (Raylib). 
Run it through `./hypr/scripts/screenshot.sh`, or wire the script into a Waybar module for one-click capture.

---

## Customizations & Theming

### Waybar — Liquid Glass

Thanks to Hyprland's precise transparency-filtering capabilities, Waybar is themed with a translucent, liquid-glass effect. Two configurations live under `./waybar/`:
- **Toggle:** `./waybar/scripts/toggle-waybar.sh`
- **Reload:** `./waybar/scripts/reload-waybar.sh`

### Matugen Color Palette

[Matugen](https://github.com/InioX/matugen) extracts a Material You color palette from the current wallpaper and propagates it across the system:
- Waybar, Hyprland, Mako, Wlogout, Btop
- Hypr-Prelock, Hyprlock
- Ghostty (along with Starship, Fastfetch, and Yazi)

*Special thanks to [Shorin's templates](https://github.com/SHORiN-KiWATA/shorin-niri/tree/main/dotfiles/.config/matugen/templates/gtk-folder) for dynamic Thunar folder icons.*

---

## Gallery
<img width="3072" height="1920" alt="overview" src="https://github.com/user-attachments/assets/5327332d-8484-40c4-a992-350fcf7b4ec0" />
waybar-bottom:
<img width="3072" height="1920" alt="waybar-bottom" src="https://github.com/user-attachments/assets/54b4582a-edd0-497f-85ad-76a212c13337" />

waybar-top:
<img width="3072" height="1920" alt="waybar-top" src="https://github.com/user-attachments/assets/db03d546-50a1-426e-b4a4-6f8ec6bbe072" />


https://github.com/user-attachments/assets/69db9834-f806-4be3-bcbe-072944caee68


