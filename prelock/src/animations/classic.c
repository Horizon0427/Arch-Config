#include "prelock/animations/classic.h"

#include "prelock/components/lock_icon.h"
#include "raylib.h"

static void draw_classic(const PrelockFrame *frame) {
  const float progress = frame->progress;
  const float ease_out = frame->eased_progress;
  const float global_alpha = frame->global_alpha;
  const PrelockPalette *palette = frame->palette;
  const float center_x = (float)frame->screen_width / 2.0f;
  const float center_y = (float)frame->screen_height / 2.0f;

  DrawRectangle(0, 0, frame->screen_width, frame->screen_height,
                ColorAlpha(palette->background,
                           ease_out * 0.6f * global_alpha));

  const float line_start_offset = ease_out * 120.0f + 30.0f;
  const float line_length = ease_out * ((float)frame->screen_width / 2.0f);
  const Color line_color = ColorAlpha(palette->secondary, global_alpha);

  DrawLineEx((Vector2){center_x - line_start_offset, center_y},
             (Vector2){center_x - line_start_offset - line_length, center_y},
             2.0f, line_color);
  DrawLineEx((Vector2){center_x + line_start_offset, center_y},
             (Vector2){center_x + line_start_offset + line_length, center_y},
             2.0f, line_color);

  const float outer_radius = ease_out * 120.0f;
  float outer_inner = outer_radius - 12.0f;
  if (outer_inner < 0.0f) {
    outer_inner = 0.0f;
  }

  const float start_angle = 270.0f;
  const float end_angle = start_angle + ease_out * 360.0f;
  if (end_angle > start_angle) {
    DrawRing((Vector2){center_x, center_y}, outer_inner, outer_radius,
             start_angle, end_angle, 64,
             ColorAlpha(palette->primary, global_alpha));
  }

  const float reverse_radius = ease_out * 145.0f;
  float reverse_inner = reverse_radius - 3.0f;
  if (reverse_inner < 0.0f) {
    reverse_inner = 0.0f;
  }

  const float reverse_start_angle = 270.0f - ease_out * 360.0f;
  const float reverse_end_angle = 270.0f;
  if (reverse_end_angle > reverse_start_angle) {
    DrawRing((Vector2){center_x, center_y}, reverse_inner, reverse_radius,
             reverse_start_angle, reverse_end_angle, 64,
             ColorAlpha(palette->accent, global_alpha));
  }

  float shackle_progress = 0.0f;
  if (progress > 0.4f) {
    shackle_progress = (progress - 0.4f) / 0.35f;
  }

  const PrelockLockIcon lock = {
      .position = (Vector2){center_x, center_y},
      .scale = 1.0f,
      .rotation_degrees = (1.0f - ease_out) * -180.0f,
      .shackle_progress = shackle_progress,
      .color = ColorAlpha(palette->tertiary, global_alpha),
      .detail_color = ColorAlpha(palette->contrast, global_alpha),
  };
  prelock_draw_lock_icon(&lock);
}

const PrelockAnimation PRELOCK_ANIMATION_CLASSIC = {
    .name = "classic",
    .description = "the original rotating lock",
    .duration_seconds = 1.2f,
    .draw = draw_classic,
};
