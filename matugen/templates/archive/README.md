# Archived Matugen templates

These files are intentionally excluded from `../../config.toml`.

- `config.jsonc`, `starship.toml`, and `yazi-theme.toml` were not referenced by
  Matugen.
- `colors-hyprland.conf` duplicated the active Lua palette and its rendered
  output was not consumed by Hyprland.
- `colors.css` and `walker-colors.css` were replaced by the shared
  `../gtk-palette.css` color-only template.
- `mako`, `wlogout.css`, `hyprlock.conf`, and `gtk3-theme.css` were full
  application templates. Their static layout now lives with each application,
  while Matugen renders only the corresponding color fragment.
- `generated/` contains the final unused rendered files for rollback/provenance.
