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

Building requires a C11 compiler, Make, and Raylib. Runtime integration uses
Hyprland and Hyprlock. The launcher uses `jq`; liquid mode and the optional
seamless Hyprlock integration use `grim`.

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

### Optional seamless Hyprlock companion

Stock Hyprlock uses one screencopy for both fade directions. When Prelock is on
screen, that makes the unlock fade replay Prelock's final frame. The optional
patch in `patches/hyprlock-v0.9.6-dual-transition.patch` adds a separate,
per-output fade-out image without changing authentication or the session-lock
state machine. Hyprlock's native GPU screencopy remains the fade-in source.

Build it against the pinned upstream release and install it under a distinct
name; do not replace the system Hyprlock:

```bash
git clone --depth 1 --branch v0.9.6 https://github.com/hyprwm/hyprlock.git
cd hyprlock
git apply /path/to/prelock/patches/hyprlock-v0.9.6-dual-transition.patch
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build --target hyprlock -j"$(nproc)"
install -Dm755 build/hyprlock \
  ~/.local/libexec/prelock/hyprlock-prelock
```

The launcher uses the companion only when the binary exists and a clean
fade-out snapshot was captured for every active output. Otherwise it falls back
to the stock Hyprlock flow. The system `/usr/bin/hyprlock` remains available for
direct use and recovery. See `patches/README.md` for the patch boundary and
update notes.

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

With no animation name, the launcher selects one at random. With the companion
installed, it captures the clean desktop before Prelock. Hyprlock uses its
native screencopy of Prelock's final frame for fade-in and the clean image for
fade-out, then notifies the launcher when fade-in is complete so that the exact
Prelock child can be destroyed behind the lock surface.

Snapshots live in a mode-0700 directory under `$XDG_RUNTIME_DIR`, use mode 0600,
and are unlinked by Hyprlock as soon as their textures are loaded into memory.
If any companion prerequisite or capture fails, the launcher
retains the original behavior and lets Prelock fade after unlock.
