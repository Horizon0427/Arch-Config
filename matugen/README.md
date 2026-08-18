# Matugen compatibility

> [!WARNING]
> These templates target my custom Matugen build. They are not directly compatible with the officially packaged upstream Matugen.

I added a `contrary` palette to Matugen and use it in several templates. Upstream Matugen cannot resolve expressions such as `palettes.contrary._80` and will stop while rendering those templates.

To reuse this configuration with upstream Matugen, replace every `contrary` reference with an upstream color or palette available in your installed version. Hypr-Prelock can also run without Matugen by using its built-in monochrome fallback or a handwritten `~/.config/prelock/palette.conf`.
