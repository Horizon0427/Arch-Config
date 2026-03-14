# My Arch Linux Dotfiles
Welcome to Horizon's archlinux repository, 
a place saving personal configuration of my operating system. 
Here's a brief overview of what you will find in the listing directory:

## Hyprland

`Hyprland` recently added scrolling layouts, which is nice to laptop users. A shell script `toggle_layout.sh` can switch the layouts between `Dwindle` and `Scrolling` using keybinds(`super + D`). 

`screenshot.sh` is made for pasting screenshots in sessions.

`ghostty_cursors.sh` automatically closes(or start) the cursor trails in `ghostty` for reducing power consumption(or performance).

More keybinds can be found in `./hypr/hyprland.conf`.

The positioning of certain UI elements in `hyprlock` is hardcoded to my specific screen resolution. If you plan to use this, please manually adjust the coordinates of each component to fit your own display.

## Matugen

`matugen` takes over multiple styling aspects, triggered dynamically via `waypaper`. Specifically, this covers: `waybar`, active window borders, `starship`, `mako`, `wlogout`, `fastfetch`, `btop` and `hyprlock`. 

New releases shows that `matugen` supports `base16` and pipes(`|`), some syntax has been superseded. Go to `waypaper/config.ini`, add `--source-color-index 0` behind `matugen image "$wallpaper"` may help to fix color issues.

## cowsay

"What does the cow say?"

## waybar

Check out my very first `waybar` setup in `./waybar/config.jsonc` and `./waybar/style.css`.

# Screenshots

![1](./images/rice1.png)
![2](./images/rice2.png)
![3](./images/rice3.png)
![4](./images/rice4.png)
![5](./images/rice5.png)
![6](./images/rice6.png)
![7](./images/rice7.png)
![8](./images/rice8.png)
![9](./images/rice9.png)
![10](./images/rice10.png)
