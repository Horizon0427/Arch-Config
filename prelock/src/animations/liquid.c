#include "prelock/animations/liquid.h"

#include "prelock/desktop_capture.h"
#include "raylib.h"

#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>

typedef struct {
  PrelockDesktopCapture capture;
  Texture2D desktop_texture;
  Shader shader;
  int resolution_location;
  int progress_location;
  int time_location;
  int opacity_location;
} LiquidState;

static LiquidState state = {0};

static void set_palette_uniform(Shader shader, const char *name, Color color) {
  const int location = GetShaderLocation(shader, name);
  const float value[3] = {
      (float)color.r / 255.0f,
      (float)color.g / 255.0f,
      (float)color.b / 255.0f,
  };
  SetShaderValue(shader, location, value, SHADER_UNIFORM_VEC3);
}

static bool load_wallpaper_fallback(Image *image) {
  char path[4096];
  const char *config_home = getenv("XDG_CONFIG_HOME");
  int length;
  if (config_home != NULL && config_home[0] != '\0') {
    length = snprintf(path, sizeof(path),
                      "%s/hypr/current_wallpaper.png", config_home);
  } else {
    const char *home = getenv("HOME");
    if (home == NULL || home[0] == '\0') {
      return false;
    }
    length = snprintf(path, sizeof(path),
                      "%s/.config/hypr/current_wallpaper.png", home);
  }
  if (length < 0 || (size_t)length >= sizeof(path)) {
    return false;
  }

  *image = LoadImage(path);
  return IsImageValid(*image);
}

static bool liquid_prepare(void) {
  if (!prelock_capture_desktop_png(&state.capture)) {
    fprintf(stderr,
            "prelock: desktop capture failed; liquid will use wallpaper\n");
  }
  return true;
}

static bool liquid_load(const PrelockPalette *palette) {
  Image image = {0};
  if (state.capture.data != NULL && state.capture.size > 0) {
    image =
        LoadImageFromMemory(".png", state.capture.data, state.capture.size);
  }
  prelock_desktop_capture_release(&state.capture);

  if (!IsImageValid(image) && !load_wallpaper_fallback(&image)) {
    fprintf(stderr, "prelock: no image is available for liquid refraction\n");
    return false;
  }

  const int monitor = GetCurrentMonitor();
  int target_width = GetMonitorWidth(monitor);
  int target_height = GetMonitorHeight(monitor);
  if (target_width <= 0 || target_height <= 0) {
    target_width = GetScreenWidth();
    target_height = GetScreenHeight();
  }

  const float source_aspect =
      (float)image.width / (float)image.height;
  const float target_aspect = (float)target_width / (float)target_height;
  Rectangle crop = {0.0f, 0.0f, (float)image.width, (float)image.height};
  if (source_aspect > target_aspect) {
    crop.width = (float)image.height * target_aspect;
    crop.x = ((float)image.width - crop.width) / 2.0f;
  } else if (source_aspect < target_aspect) {
    crop.height = (float)image.width / target_aspect;
    crop.y = ((float)image.height - crop.height) / 2.0f;
  }
  ImageCrop(&image, crop);
  ImageResize(&image, target_width, target_height);

  state.desktop_texture = LoadTextureFromImage(image);
  UnloadImage(image);
  if (!IsTextureValid(state.desktop_texture)) {
    return false;
  }
  SetTextureFilter(state.desktop_texture, TEXTURE_FILTER_BILINEAR);

  char shader_path[4096];
  const char *data_home = getenv("XDG_DATA_HOME");
  int path_length;
  if (data_home != NULL && data_home[0] != '\0') {
    path_length = snprintf(shader_path, sizeof(shader_path),
                           "%s/prelock/shaders/liquid_glass.fs", data_home);
  } else {
    const char *home = getenv("HOME");
    if (home == NULL || home[0] == '\0') {
      return false;
    }
    path_length = snprintf(
        shader_path, sizeof(shader_path),
        "%s/.local/share/prelock/shaders/liquid_glass.fs", home);
  }
  if (path_length < 0 || (size_t)path_length >= sizeof(shader_path)) {
    return false;
  }

  state.shader = LoadShader(NULL, shader_path);
  if (!IsShaderValid(state.shader)) {
    return false;
  }

  state.resolution_location = GetShaderLocation(state.shader, "resolution");
  state.progress_location = GetShaderLocation(state.shader, "progress");
  state.time_location = GetShaderLocation(state.shader, "time");
  state.opacity_location = GetShaderLocation(state.shader, "opacity");
  set_palette_uniform(state.shader, "primaryColor", palette->primary);
  set_palette_uniform(state.shader, "secondaryColor", palette->secondary);
  set_palette_uniform(state.shader, "tertiaryColor", palette->tertiary);
  set_palette_uniform(state.shader, "accentColor", palette->accent);
  return true;
}

static void liquid_unload(void) {
  prelock_desktop_capture_release(&state.capture);
  if (IsShaderValid(state.shader)) {
    UnloadShader(state.shader);
  }
  if (IsTextureValid(state.desktop_texture)) {
    UnloadTexture(state.desktop_texture);
  }
  state = (LiquidState){0};
}

static void draw_liquid(const PrelockFrame *frame) {
  const float resolution[2] = {(float)frame->screen_width,
                               (float)frame->screen_height};
  SetShaderValue(state.shader, state.resolution_location, resolution,
                 SHADER_UNIFORM_VEC2);
  SetShaderValue(state.shader, state.progress_location, &frame->progress,
                 SHADER_UNIFORM_FLOAT);
  SetShaderValue(state.shader, state.time_location, &frame->elapsed_seconds,
                 SHADER_UNIFORM_FLOAT);
  SetShaderValue(state.shader, state.opacity_location, &frame->global_alpha,
                 SHADER_UNIFORM_FLOAT);

  const Rectangle source = {0.0f, 0.0f, (float)state.desktop_texture.width,
                            (float)state.desktop_texture.height};
  const Rectangle destination = {0.0f, 0.0f, (float)frame->screen_width,
                                 (float)frame->screen_height};
  BeginShaderMode(state.shader);
  DrawTexturePro(state.desktop_texture, source, destination, (Vector2){0}, 0.0f,
                 WHITE);
  EndShaderMode();
}

const PrelockAnimation PRELOCK_ANIMATION_LIQUID = {
    .name = "liquid",
    .description = "refractive liquid-glass membrane",
    .duration_seconds = 2.0f,
    .prepare = liquid_prepare,
    .load = liquid_load,
    .unload = liquid_unload,
    .draw = draw_liquid,
};
