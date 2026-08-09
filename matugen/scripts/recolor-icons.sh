#!/usr/bin/env bash

set -euo pipefail

check_only=false
if [[ "${1:-}" == --check ]]; then
  check_only=true
  shift
fi

PALETTE_FILE="${1:-$HOME/.cache/matugen/gtk-icons.conf}"
[[ -r "$PALETTE_FILE" ]] || {
  printf 'gtk icon palette is not readable: %s\n' "$PALETTE_FILE" >&2
  exit 1
}

declare -A palette=()
while IFS='=' read -r key value; do
  [[ -n "$key" && "$value" =~ ^#[[:xdigit:]]{6}$ ]] || {
    printf 'invalid gtk icon palette entry: %s=%s\n' "$key" "$value" >&2
    exit 1
  }
  palette["$key"]="$value"
done < "$PALETTE_FILE"

required_colors=(
  MAIN_COLOR MAIN_SHADOW MAIN_DARKER_SHADOW MAIN_HIGHLIGHT
  INVERSE_MAIN_COLOR INVERSE_MAIN_HIGHLIGHT INVERSE_MAIN_SHADOW
  TRASH_PAPER HTML_DEEP PRESENTATION_STAND AUDIO_PALE AUDIO_DEEP
)
for key in "${required_colors[@]}"; do
  [[ -n "${palette[$key]:-}" ]] || {
    printf 'missing gtk icon palette color: %s\n' "$key" >&2
    exit 1
  }
done

if [[ "$check_only" == true ]]; then
  printf 'gtk icon palette ok: %s\n' "$PALETTE_FILE"
  exit 0
fi

MAIN_COLOR=${palette[MAIN_COLOR]}
MAIN_SHADOW=${palette[MAIN_SHADOW]}
MAIN_DARKER_SHADOW=${palette[MAIN_DARKER_SHADOW]}
MAIN_HILIGHT=${palette[MAIN_HIGHLIGHT]}
INVERSE_MAIN_COLOR=${palette[INVERSE_MAIN_COLOR]}
INVERSE_MAIN_HIGHLT=${palette[INVERSE_MAIN_HIGHLIGHT]}
INVERSE_MAIN_SHADOW=${palette[INVERSE_MAIN_SHADOW]}
PAPER_COLOR="#fafafa"
PAPER_FOLE_COLOR="#deddda"
COLOR_FOLDER_BODY=$MAIN_COLOR
COLOR_FOLDER_TOP=$MAIN_HILIGHT
COLOR_FOLDER_SHADOW=$MAIN_SHADOW

COLOR_ACCENT_BODY=$INVERSE_MAIN_COLOR
COLOR_ACCENT_LIGHT=$INVERSE_MAIN_HIGHLT
COLOR_ACCENT_DARK=$INVERSE_MAIN_SHADOW
COLOR_TRASH_PAPER=${palette[TRASH_PAPER]}

COLOR_SCRIPT_BODY=$MAIN_SHADOW
COLOR_SCRIPT_HIGHLIGHT=$MAIN_HILIGHT
COLOR_SCRIPT_MID="#f0f0f0"
COLOR_SCRIPT_SHADOW=$MAIN_SHADOW
COLOR_SCRIPT_GEAR=$MAIN_DARKER_SHADOW
COLOR_SCRIPT_PALE="ffffff"

COLOR_HTML_PALE="#f0f0f0"
COLOR_HTML_HIGHLIGHT=$MAIN_HILIGHT
COLOR_HTML_BODY=$MAIN_SHADOW
COLOR_HTML_MID=$MAIN_SHADOW
COLOR_HTML_SHADOW=$MAIN_DARKER_SHADOW
COLOR_HTML_DEEP=${palette[HTML_DEEP]}
COLOR_DOC_PAPER=$PAPER_COLOR
COLOR_DOC_FOLD=$PAPER_FOLE_COLOR

COLOR_ADDON_BODY=$MAIN_COLOR
COLOR_ADDON_HIGHLIGHT=$MAIN_HILIGHT
COLOR_ADDON_SHADOW=$MAIN_SHADOW
COLOR_ADDON_DEEP=$MAIN_DARKER_SHADOW

COLOR_FONT_A=$MAIN_SHADOW
COLOR_FONT_BASE=$MAIN_DARKER_SHADOW

COLOR_DOC_PAPER=$PAPER_COLOR
COLOR_DOC_FOLD=$PAPER_FOLE_COLOR
COLOR_DOC_GRAD_ACCENT_START=$INVERSE_MAIN_COLOR
COLOR_DOC_GRAD_ACCENT_END=$INVERSE_MAIN_COLOR
COLOR_DOC_GRAD_SHADE_START=$MAIN_COLOR
COLOR_DOC_GRAD_SHADE_END=$INVERSE_MAIN_COLOR

COLOR_PRES_CHART_BLUE=$MAIN_COLOR
COLOR_PRES_CHART_BLUE_DEEP=$MAIN_SHADOW
COLOR_PRES_CHART_GREEN=$INVERSE_MAIN_COLOR
COLOR_PRES_CHART_GREEN_DEEP=$INVERSE_MAIN_SHADOW
COLOR_PRES_STAND_DARK=${palette[PRESENTATION_STAND]}
COLOR_PRES_STAND_LIGHT=${palette[PRESENTATION_STAND]}
COLOR_AUDIO_PALE=${palette[AUDIO_PALE]}
COLOR_AUDIO_HIGHLIGHT=$INVERSE_MAIN_HIGHLT
COLOR_AUDIO_BODY=$INVERSE_MAIN_COLOR
COLOR_AUDIO_SHADOW=$INVERSE_MAIN_SHADOW
COLOR_AUDIO_DEEP=${palette[AUDIO_DEEP]}

CMD_FOLDER="
s/#a4caee/$COLOR_FOLDER_BODY/g;
s/#438de6/$COLOR_FOLDER_SHADOW/g;
s/#62a0ea/$COLOR_FOLDER_SHADOW/g;
s/#afd4ff/$COLOR_FOLDER_TOP/g;
s/#c0d5ea/$COLOR_FOLDER_TOP/g"

CMD_NETWORK="
s/#62a0ea/$COLOR_ACCENT_LIGHT/g;
s/#1c71d8/$COLOR_ACCENT_BODY/g;
s/#c0bfbc/$COLOR_ACCENT_BODY/g;
s/#1a5fb4/$COLOR_ACCENT_DARK/g;
s/#14498a/$COLOR_ACCENT_DARK/g;
s/#9a9996/$COLOR_ACCENT_DARK/g;
s/#77767b/$COLOR_FOLDER_SHADOW/g;
s/#241f31/$COLOR_FOLDER_SHADOW/g;
s/#3d3846/$COLOR_FOLDER_SHADOW/g"

CMD_TRASH="
s/#2ec27e/$COLOR_ACCENT_BODY/g;
s/#33d17a/$COLOR_ACCENT_BODY/g;
s/#26a269/$COLOR_ACCENT_DARK/g;
s/#26a168/$COLOR_ACCENT_DARK/g;
s/#9a9996/$COLOR_ACCENT_DARK/g;
s/#c3c2bc/$COLOR_ACCENT_DARK/g;
s/#42d390/$COLOR_ACCENT_LIGHT/g;
s/#ffffff/$COLOR_FOLDER_SHADOW/g;
s/#deddda/$COLOR_TRASH_PAPER/g;
s/#f6f5f4/$COLOR_TRASH_PAPER/g;
s/#77767b/$COLOR_FOLDER_SHADOW/g"

CMD_SCRIPT="
s/#3584e4/$COLOR_SCRIPT_BODY/g;
s/#99c1f1/$COLOR_SCRIPT_HIGHLIGHT/g;
s/#98c1f1/$COLOR_SCRIPT_HIGHLIGHT/g;
s/#62a0ea/$COLOR_SCRIPT_MID/g;
s/#1c71d8/$COLOR_SCRIPT_SHADOW/g;
s/#1a5fb4/$COLOR_SCRIPT_GEAR/g;
s/#d7e8fc/$COLOR_SCRIPT_PALE/g;
s/#b3d3f9/$COLOR_SCRIPT_PALE/g"

CMD_HTML="
s/#f6f5f4/$COLOR_DOC_PAPER/g;
s/#deddda/$COLOR_DOC_FOLD/g;
s/#b3d3f9/$COLOR_HTML_PALE/g;
s/#d7e8fc/$COLOR_HTML_PALE/g;
s/#62a0ea/$COLOR_HTML_BODY/g;
s/#3584e4/$COLOR_HTML_MID/g;
s/#99c1f1/$COLOR_HTML_HIGHLIGHT/g;
s/#1c71d8/$COLOR_HTML_SHADOW/g;
s/#1a5fb4/$COLOR_HTML_DEEP/g"

CMD_ADDON="
s/#3584e4/$COLOR_ADDON_BODY/g;
s/#62a0ea/$COLOR_ADDON_HIGHLIGHT/g;
s/#98c1f1/$COLOR_ADDON_HIGHLIGHT/g;
s/#1c71d8/$COLOR_ADDON_SHADOW/g;
s/#1a5fb4/$COLOR_ADDON_DEEP/g"

CMD_FONT="
s/#3584e4/$COLOR_FONT_A/g;
s/#1a5fb4/$COLOR_FONT_BASE/g"

CMD_DOC="
s/#f6f5f4/$COLOR_DOC_PAPER/g;
s/#deddda/$COLOR_DOC_FOLD/g;
s/#50db81/$COLOR_DOC_GRAD_ACCENT_START/g;
s/#8ff0a4/$COLOR_DOC_GRAD_ACCENT_END/g;
s/#4a86cf/$COLOR_DOC_GRAD_SHADE_START/g;
s/#87bae1/$COLOR_DOC_GRAD_SHADE_END/g;
s/#d7e8fc/$COLOR_SCRIPT_PALE/g; 
s/#b3d3f9/$COLOR_SCRIPT_PALE/g"

CMD_PRES="
s/#4a86cf/$COLOR_PRES_CHART_BLUE/g;
s/#1a5fb4/$COLOR_PRES_CHART_BLUE_DEEP/g;
s/#50db81/$COLOR_PRES_CHART_GREEN/g;
s/#26a269/$COLOR_PRES_CHART_GREEN_DEEP/g;
s/#f6f5f4/$COLOR_DOC_PAPER/g;
s/#ffffff/$COLOR_DOC_PAPER/g;
s/#414140/$COLOR_PRES_STAND_DARK/g;
s/#949390/$COLOR_PRES_STAND_LIGHT/g;
s/#d7e8fc/$COLOR_SCRIPT_PALE/g"

CMD_AUDIO="
s/#1a6842/$COLOR_AUDIO_DEEP/g;
s/#26a269/$COLOR_AUDIO_SHADOW/g;
s/#2dbd7d/$COLOR_AUDIO_BODY/g;
s/#2dc47e/$COLOR_AUDIO_BODY/g;
s/#33d17a/$COLOR_AUDIO_BODY/g;
s/#38ec8b/$COLOR_AUDIO_HIGHLIGHT/g;
s/#38f39d/$COLOR_AUDIO_HIGHLIGHT/g;
s/#8ff0a4/$COLOR_AUDIO_PALE/g"

TEMPLATE_DIR="$HOME/.config/matugen/assets/gtk-icons/Adwaita-Matugen"
[[ -d "$TEMPLATE_DIR" ]] || {
  printf 'gtk icon assets are missing: %s\n' "$TEMPLATE_DIR" >&2
  exit 1
}
CURRENT_THEME=$(gsettings get org.gnome.desktop.interface icon-theme | tr -d "'")

if [[ "$CURRENT_THEME" == "Adwaita-Matugen-A" ]]; then
  TARGET_THEME="Adwaita-Matugen-B"
else
  TARGET_THEME="Adwaita-Matugen-A"
fi
TARGET_DIR="$HOME/.local/share/icons/$TARGET_THEME"

mkdir -p "$TARGET_DIR"
cp -rf --reflink=auto --no-preserve=mode,ownership "$TEMPLATE_DIR/"* "$TARGET_DIR/"
sed -i "s/Name=.*/Name=$TARGET_THEME/" "$TARGET_DIR/index.theme"

find "$TARGET_DIR" -name "*.png" -print0 | xargs -0 -r -P0 -I {} magick "{}" \
  -channel RGB -colorspace gray -sigmoidal-contrast 10,50% \
  +level-colors "$COLOR_FOLDER_SHADOW","$COLOR_FOLDER_BODY" \
  +channel "{}"

# [Group 1] Folders
find "$TARGET_DIR/scalable" \
  \( -name "folder*.svg" -o -name "user-home*.svg" -o -name "user-desktop*.svg" -o -name "user-bookmarks*.svg" -o -name "inode-directory*.svg" \) \
  -print0 | xargs -0 -r -P0 sed -i "$CMD_FOLDER"

# [Group 2] Network
find "$TARGET_DIR/scalable" -name "network*.svg" -print0 | xargs -0 -r -P0 sed -i --follow-symlinks "$CMD_NETWORK"

# [Group 3] Trash
find "$TARGET_DIR/scalable" -name "user-trash*.svg" -print0 | xargs -0 -r -P0 sed -i --follow-symlinks "$CMD_TRASH"

# [Group 4] Mimetypes - Script & Executable
find "$TARGET_DIR/scalable/mimetypes" \
  \( -name "text-x-script*.svg" -o -name "application-x-executable*.svg" \) \
  -print0 | xargs -0 -r -P0 sed -i "$CMD_SCRIPT"

# [Group 5] Mimetypes - Addon
find "$TARGET_DIR/scalable/mimetypes" -name "application-x-addon*.svg" -print0 | xargs -0 -r -P0 sed -i "$CMD_ADDON"

# [Group 6] Mimetypes - HTML
find "$TARGET_DIR/scalable/mimetypes" -name "text-html*.svg" -print0 | xargs -0 -r -P0 sed -i "$CMD_HTML"

# [Group 7] Mimetypes - Font
find "$TARGET_DIR/scalable/mimetypes" -name "font-x-generic*.svg" -print0 | xargs -0 -r -P0 sed -i "$CMD_FONT"

# [Group 8] Mimetypes - Document
find "$TARGET_DIR/scalable/mimetypes" -name "x-office-document*.svg" -print0 | xargs -0 -r -P0 sed -i "$CMD_DOC"

# [Group 9] Mimetypes - Presentation
find "$TARGET_DIR/scalable/mimetypes" -name "x-office-presentation*.svg" -print0 | xargs -0 -r -P0 sed -i "$CMD_PRES"
# [Group 10] Mimetypes - Audio
find "$TARGET_DIR/scalable/mimetypes" -name "audio-x-generic*.svg" -print0 | xargs -0 -r -P0 sed -i "$CMD_AUDIO"
gsettings set org.gnome.desktop.interface icon-theme "$TARGET_THEME"
flatpak override --user --env=ICON_THEME="$TARGET_THEME" 2>/dev/null || true

exit 0
