#!/usr/bin/env bash
set -euo pipefail

readonly WALLPAPER_PATH="${1:-}"
readonly REL_X="${2:-0.5}"
readonly REL_Y="${3:-0.5}"
readonly MATUGEN_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/matugen/config.toml"
readonly MATUGEN_SCRIPTS="${XDG_CONFIG_HOME:-$HOME/.config}/matugen/scripts"
readonly MATUGEN_BIN="${MATUGEN_BIN:-$HOME/.local/bin/matugen}"
readonly WALLPICKER_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/wallpicker"
readonly LOG_FILE="${WALLPICKER_LOG_FILE:-$WALLPICKER_CACHE/last-run.log}"
readonly PALETTE_PATH="$WALLPICKER_CACHE/current-palette.json"

if [[ "${WALLPICKER_LOCK_HELD:-0}" != 1 ]]; then
  mkdir -p "$WALLPICKER_CACHE"
  exec env WALLPICKER_LOCK_HELD=1 \
    flock --close "$WALLPICKER_CACHE/apply.lock" "$0" "$@"
fi

exec > >(tee "$LOG_FILE") 2>&1

log() {
  printf '[wallpicker] %s\n' "$*"
}

warn() {
  printf '[wallpicker] warning: %s\n' "$*" >&2
}

run_action() {
  local label=$1
  shift

  if "$@"; then
    log "$label: ok"
  else
    local status=$?
    warn "$label failed (exit $status)"
  fi
}

reload_ironbar() {
  local controller="$HOME/.config/ironbar/scripts/ironbar-control.sh"
  [[ -x "$controller" ]] || return 0
  [[ "$("$controller" status)" != stopped ]] || return 0
  "$controller" reload
}

reload_ghostty() {
  pgrep -x ghostty >/dev/null || return 0
  pkill -USR2 -x ghostty
}

reload_btop() {
  pgrep -x btop >/dev/null || return 0
  pkill -USR2 -x btop
}

reload_mako() {
  makoctl reload >/dev/null
}

reload_hyprland() {
  hyprctl reload >/dev/null
}

reload_copyq() {
  pgrep -x copyq >/dev/null || return 0
  copyq eval -- 'loadTheme("/home/horizon/.config/copyq/themes/matugen.ini")' >/dev/null
}

reload_fcitx5() {
  pgrep -x fcitx5 >/dev/null || return 0
  fcitx5 -r -d >/dev/null 2>&1
}

if [[ -z "$WALLPAPER_PATH" ]]; then
  echo "usage: $0 <wallpaper_path> [rel_x] [rel_y]" >&2
  exit 1
fi
[[ -f "$WALLPAPER_PATH" ]] || {
  warn "wallpaper is not a regular file: $WALLPAPER_PATH"
  exit 1
}

if [[ ! -x "$MATUGEN_BIN" ]]; then
  warn "custom Matugen is unavailable: $MATUGEN_BIN"
  exit 1
fi
if ! command -v jq >/dev/null 2>&1; then
  warn "jq is unavailable; wallpaper, colors and reloads were skipped"
  exit 1
fi

palette_tmp=""
cleanup() {
  [[ -n "$palette_tmp" ]] && rm -f -- "$palette_tmp"
  return 0
}
trap cleanup EXIT

palette_tmp="$(mktemp "$WALLPICKER_CACHE/.palette.XXXXXX")"
if ! "$MATUGEN_BIN" \
  --config "$MATUGEN_CONFIG" \
  --type scheme-tonal-spot \
  --mode dark \
  --source-color-index 0 \
  --dry-run \
  --json hex \
  image "$WALLPAPER_PATH" >"$palette_tmp"; then
  warn "native palette generation failed; wallpaper, colors and reloads were skipped"
  exit 1
fi

if ! jq -e '
  [
    .colors.source_color.default.color,
    .colors.primary.default.color,
    .colors.tertiary.default.color,
    .palettes.contrary["80"].color,
    .base16.base00.default.color
  ]
  | all(.[]; type == "string" and test("^#[0-9A-Fa-f]{6}$"))
' "$palette_tmp" >/dev/null; then
  warn "native palette validation failed; wallpaper, colors and reloads were skipped"
  exit 1
fi
log "native palette generation: ok"

if ! "$MATUGEN_BIN" --config "$MATUGEN_CONFIG" json "$palette_tmp"; then
  warn "Matugen template render failed; wallpaper and reloads were skipped"
  exit 1
fi
chmod 0600 "$palette_tmp"
mv -- "$palette_tmp" "$PALETTE_PATH"
palette_tmp=""
log "palette render: ok"

if command -v awww >/dev/null 2>&1; then
  awww img "$WALLPAPER_PATH" \
    --transition-type grow \
    --transition-pos "$REL_X,$REL_Y" \
    --transition-step 30 \
    --transition-duration 1.2 \
    --transition-fps 60
  log "wallpaper: ok"
else
  warn "awww is unavailable; wallpaper was not changed"
fi

mkdir -p "$HOME/.config/hypr"
ln -sfn "$WALLPAPER_PATH" "$WALLPICKER_CACHE/current_wallpaper.png"
ln -sfn "$WALLPAPER_PATH" "$HOME/.config/hypr/current_wallpaper.png"
log "wallpaper links: ok"

run_action "GTK icon recolor" "$MATUGEN_SCRIPTS/recolor-icons.sh"
run_action "GTK3 theme reload" "$MATUGEN_SCRIPTS/reload-gtk.sh"
command -v makoctl >/dev/null 2>&1 && run_action "Mako reload" reload_mako
command -v hyprctl >/dev/null 2>&1 && run_action "Hyprland reload" reload_hyprland
run_action "Ironbar hard reload" reload_ironbar
run_action "Ghostty reload" reload_ghostty
run_action "Btop reload" reload_btop
command -v copyq >/dev/null 2>&1 && run_action "CopyQ theme reload" reload_copyq
command -v fcitx5 >/dev/null 2>&1 && run_action "Fcitx5 reload" reload_fcitx5

log "done"
