# Hypr-Prelock

Hypr-Prelock is a small C/Raylib transition layer that runs immediately before Hyprlock. Its animation pool currently contains:

- `classic`: the original rotating padlock and expanding rays;
- `swift`: counter-moving bars with a shrinking lock and rings;
- `diagonal`: staggered translucent color strips;
- `meteor`: a dual-vortex vector-field meteor swarm;
- `liquid`: a screen-space liquid-glass refraction shader.

> [!IMPORTANT]
> This repository contains a personal Hyprland setup, not a drop-in theme. The bundled Matugen templates use a custom `contrary` palette that upstream Matugen does not provide. Hypr-Prelock itself does **not** require Matugen: without a palette file it prints a warning and continues with a monochrome fallback.

## Requirements

Building requires a C11 compiler, Make, and Raylib. Runtime integration uses Hyprland and Hyprlock. The launcher also uses `jq`; liquid mode uses `grim` to capture the focused output directly into memory. Other animations do not require `grim`.

## Install

```bash
make install
```

The default installation is split into stable XDG-style locations:

```text
~/.local/bin/prelock
~/.local/share/prelock/shaders/liquid_glass.fs
~/.config/prelock/palette.conf        # optional
```

`make install` atomically replaces the executable and liquid shader. The Hyprland integration used by this repository is in `hypr/scripts/smart_lock.sh` at the repository root.

## Palette

The palette file is optional. Copy `examples/palette.conf` to `~/.config/prelock/palette.conf`, write the seven roles manually, or generate the same plain-text format with any theming tool:

```text
background=101010
foreground=f5f5f5
primary=b8d8ff
secondary=bdebd2
tertiary=d7c1ff
accent=ffe0a8
contrast=202020
```

Missing roles retain their monochrome defaults. If the file is missing or contains no valid roles, Prelock uses white foreground/effect colors over a black background with dark contrast details.

The `matugen/` directory in this dotfiles repository documents the custom Matugen compatibility boundary. Upstream Matugen users should replace `palettes.contrary._80` in the template with an available upstream color or use a handwritten palette.

## Usage

```bash
prelock --list
~/.config/hypr/scripts/smart_lock.sh meteor
```

With no animation name, the launcher selects one at random. It waits for Prelock's private FIFO readiness signal before starting Hyprlock, then lets Prelock fade out after unlock.
