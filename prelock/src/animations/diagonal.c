#include "prelock/animations/diagonal.h"

#include "prelock/easing.h"
#include "raylib.h"

#include <math.h>
#include <stddef.h>

typedef enum {
  STRIP_PRIMARY,
  STRIP_SECONDARY,
  STRIP_TERTIARY,
  STRIP_ACCENT,
} StripRole;

static const StripRole STRIP_PATTERN[] = {
    STRIP_PRIMARY,   STRIP_SECONDARY, STRIP_TERTIARY, STRIP_SECONDARY,
    STRIP_PRIMARY,   STRIP_SECONDARY, STRIP_ACCENT,   STRIP_SECONDARY,
};

static Color strip_color(StripRole role, const PrelockPalette *palette) {
  switch (role) {
  case STRIP_PRIMARY:
    return palette->primary;
  case STRIP_SECONDARY:
    return palette->secondary;
  case STRIP_TERTIARY:
    return palette->tertiary;
  case STRIP_ACCENT:
    return palette->accent;
  }
  return palette->foreground;
}

static void strip_curve(StripRole role, Vector2 *control_1,
                        Vector2 *control_2) {
  switch (role) {
  case STRIP_PRIMARY:
    *control_1 = (Vector2){0.18f, 0.72f};
    *control_2 = (Vector2){0.82f, 0.28f};
    return;
  case STRIP_SECONDARY:
    *control_1 = (Vector2){0.22f, 0.10f};
    *control_2 = (Vector2){0.34f, 1.00f};
    return;
  case STRIP_TERTIARY:
    *control_1 = (Vector2){0.12f, 0.82f};
    *control_2 = (Vector2){0.68f, 0.18f};
    return;
  case STRIP_ACCENT:
    *control_1 = (Vector2){0.38f, 0.00f};
    *control_2 = (Vector2){0.62f, 1.00f};
    return;
  }

  *control_1 = (Vector2){0.25f, 0.25f};
  *control_2 = (Vector2){0.75f, 0.75f};
}

static void draw_strip(Vector2 center, float length, float width, Color color) {
  const Rectangle bounds = {
      .x = center.x,
      .y = center.y,
      .width = length,
      .height = width,
  };
  DrawRectanglePro(bounds, (Vector2){length / 2.0f, width / 2.0f}, -45.0f,
                   color);
}

static void draw_diagonal(const PrelockFrame *frame) {
  const float progress = frame->progress;
  const float global_alpha = frame->global_alpha;
  const PrelockPalette *palette = frame->palette;
  const float screen_width = (float)frame->screen_width;
  const float screen_height = (float)frame->screen_height;
  const float inverse_sqrt_two = 0.70710678f;
  const Vector2 direction = {inverse_sqrt_two, -inverse_sqrt_two};
  const Vector2 perpendicular = {inverse_sqrt_two, inverse_sqrt_two};
  const Vector2 screen_center = {screen_width / 2.0f,
                                 screen_height / 2.0f};

  DrawRectangle(0, 0, frame->screen_width, frame->screen_height,
                ColorAlpha(palette->background,
                           progress * 0.12f * global_alpha));

  const float projection_span =
      (screen_width + screen_height) * inverse_sqrt_two;
  const float strip_width =
      fmaxf(150.0f, fminf(screen_width, screen_height) * 0.17f);
  const float strip_spacing = strip_width - 2.0f;
  const float strip_length = projection_span + strip_width * 3.0f;
  const float travel_distance =
      (projection_span + strip_length) / 2.0f + strip_width;
  const int strip_count = (int)ceilf(projection_span / strip_spacing) + 3;
  const float first_offset =
      -(float)(strip_count - 1) * strip_spacing / 2.0f;
  const size_t pattern_count = sizeof(STRIP_PATTERN) / sizeof(STRIP_PATTERN[0]);

  for (int index = 0; index < strip_count; ++index) {
    const float rank = strip_count > 1
                           ? (float)index / (float)(strip_count - 1)
                           : 0.0f;
    const float offset = first_offset + (float)index * strip_spacing;
    const Vector2 final_center = {
        screen_center.x + perpendicular.x * offset,
        screen_center.y + perpendicular.y * offset,
    };
    const Vector2 start_center = {
        final_center.x - direction.x * travel_distance,
        final_center.y - direction.y * travel_distance,
    };

    const StripRole role = STRIP_PATTERN[(size_t)index % pattern_count];
    Vector2 control_1;
    Vector2 control_2;
    strip_curve(role, &control_1, &control_2);

    const float delay = 0.02f + rank * 0.16f;
    const float finish = 0.84f + rank * 0.14f;
    const float local_progress = prelock_remap_unit(progress, delay, finish);
    const float motion =
        prelock_ease_cubic_bezier(local_progress, control_1, control_2);
    const Vector2 center = {
        start_center.x + direction.x * travel_distance * motion,
        start_center.y + direction.y * travel_distance * motion,
    };

    draw_strip(center, strip_length, strip_width,
               ColorAlpha(strip_color(role, palette),
                          0.30f * global_alpha));
  }
}

const PrelockAnimation PRELOCK_ANIMATION_DIAGONAL = {
    .name = "diagonal",
    .description = "staggered translucent diagonal color sweep",
    .duration_seconds = 1.05f,
    .draw = draw_diagonal,
};
