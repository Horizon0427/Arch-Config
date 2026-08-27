# Hyprlock companion patch

`hyprlock-v0.9.6-dual-transition.patch` targets the upstream Hyprlock v0.9.6
release at commit `b222d9b1f87e980cac379371df57913a53b99d7f`.

The patch is intentionally narrow:

- preload optional per-output PNGs from `HYPRLOCK_FADE_OUT_DIR`;
- use upstream screencopy while entering the lock and the external image while
  leaving it, with upstream screencopy as the fade-out fallback;
- write `release\n` to `HYPRLOCK_PRELOCK_RELEASE_FIFO` after Hyprlock's fade-in
  completes.

It does not modify PAM, authentication, input handling, the ext-session-lock
protocol, or unlock timing. The launcher creates all paths in a private runtime
directory and opens the release FIFO before starting Hyprlock. Hyprlock unlinks
the fade-out PNG immediately after its texture has loaded.

After a Hyprlock update, first try the new tag in a fresh source tree:

```bash
git apply --check hyprlock-v0.9.6-dual-transition.patch
```

If the check fails, rebase only the resource-loading, background-selection, and
fade-completion callback changes. Build the result with warnings treated as
errors before installing it under the separate `hyprlock-prelock` name.

Hyprlock is distributed under the BSD 3-Clause License. This patch is an
optional downstream modification and does not bundle an upstream source tree.
