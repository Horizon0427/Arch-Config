#!/bin/bash

CONFIG_FILE="$HOME/.config/ghostty/config"

if grep -q "custom-shader-animation = true" "$CONFIG_FILE"; then
  sed -i 's/custom-shader-animation = true/custom-shader-animation = false/' "$CONFIG_FILE"
  sed -i 's/^custom-shader = cursor-effects\/cursor_warp.glsl/#custom-shader = cursor-effects\/cursor_warp.glsl/' "$CONFIG_FILE"
  sed -i 's/^custom-shader = shaders\/bloom.glsl/#custom-shader = shaders\/bloom.glsl/' "$CONFIG_FILE"
  notify-send -a "Ghostty" -t 2000 "特效已关闭"
else
  sed -i 's/custom-shader-animation = false/custom-shader-animation = true/' "$CONFIG_FILE"
  sed -i 's/^#custom-shader = cursor-effects\/cursor_warp.glsl/custom-shader = cursor-effects\/cursor_warp.glsl/' "$CONFIG_FILE"
  sed -i 's/^#custom-shader = shaders\/bloom.glsl/custom-shader = shaders\/bloom.glsl/' "$CONFIG_FILE"
  notify-send -a "Ghostty" -t 2000 "特效已开启"
fi
