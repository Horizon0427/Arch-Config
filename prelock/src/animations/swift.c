#include "prelock/animations/swift.h"

#include "prelock/components/lock_icon.h"
#include "prelock/easing.h"
#include "raylib.h"

#include <math.h>

static float ease_weighted_middle(float value) {
  return prelock_ease_cubic_bezier(value, (Vector2){0.20f, 0.68f},
                                   (Vector2){0.80f, 0.32f});
}

static float ease_out_quint(float value) {
  const float inverse = 1.0f - value;
  return 1.0f - inverse * inverse * inverse * inverse * inverse;
}

static float mix(float start, float end, float amount) {
  return start + (end - start) * amount;
}

static void draw_bar(float center_x, float center_y, float width, float height,
                     Color color) {
  const Rectangle bounds = {
      .x = center_x - width / 2.0f,
      .y = center_y - height / 2.0f,
      .width = width,
      .height = height,
  };
  DrawRectangleRounded(bounds, 0.35f, 8, color);
}

static void draw_swift(const PrelockFrame *frame) {
  const float progress = frame->progress;
  const float global_alpha = frame->global_alpha;
  const PrelockPalette *palette = frame->palette;
  const float screen_width = (float)frame->screen_width;
  const float screen_height = (float)frame->screen_height;
  const float center_x = screen_width / 2.0f;
  const float center_y = screen_height / 2.0f;

  const float dim_progress = ease_out_quint(progress);
  DrawRectangle(0, 0, frame->screen_width, frame->screen_height,
                ColorAlpha(palette->background,
                           dim_progress * 0.6f * global_alpha));

  const float bar_width = 100.0f;
  const float bar_height = fmaxf(680.0f, screen_height * 1.2f);
  const float bar_offset = fminf(400.0f, screen_width * 0.24f);
  const float detail_width = 8.0f;
  const float detail_height = bar_height;
  const float detail_gap = 28.0f;
  const float detail_offset =
      bar_width / 2.0f + detail_gap + detail_width / 2.0f;
  const float outside_top = -bar_height / 2.0f - 24.0f;
  const float outside_bottom = screen_height + bar_height / 2.0f + 24.0f;
  const float detail_outside_top = -detail_height / 2.0f - 24.0f;
  const float detail_outside_bottom =
      screen_height + detail_height / 2.0f + 24.0f;
  const float left_motion =
      ease_weighted_middle(prelock_remap_unit(progress, 0.02f, 0.72f));
  const float right_motion =
      ease_weighted_middle(prelock_remap_unit(progress, 0.08f, 0.78f));
  const float left_detail_motion =
      ease_weighted_middle(prelock_remap_unit(progress, 0.02f, 0.98f));
  const float right_detail_motion =
      ease_weighted_middle(prelock_remap_unit(progress, 0.08f, 1.0f));
  const float left_x = center_x - bar_offset;
  const float right_x = center_x + bar_offset;

  draw_bar(left_x - detail_offset,
           mix(detail_outside_bottom, detail_outside_top, left_detail_motion),
           detail_width, detail_height,
           ColorAlpha(palette->primary, global_alpha));
  draw_bar(right_x + detail_offset,
           mix(detail_outside_top, detail_outside_bottom, right_detail_motion),
           detail_width, detail_height,
           ColorAlpha(palette->accent, global_alpha));

  draw_bar(left_x,
           mix(outside_bottom, outside_top, left_motion), bar_width,
           bar_height, ColorAlpha(palette->primary, global_alpha));
  draw_bar(right_x,
           mix(outside_top, outside_bottom, right_motion), bar_width,
           bar_height, ColorAlpha(palette->accent, global_alpha));

  const float ring_motion =
      ease_weighted_middle(prelock_remap_unit(progress, 0.04f, 0.84f));
  const float center_motion =
      ease_weighted_middle(prelock_remap_unit(progress, 0.0f, 0.86f));
  const float lock_scale = mix(2.1f, 0.7f, center_motion);
  const float ring_start_angle = 270.0f;
  const float ring_end_angle = ring_start_angle + ring_motion * 360.0f;
  if (ring_end_angle > ring_start_angle) {
    DrawRing((Vector2){center_x, center_y}, 108.0f * lock_scale,
             120.0f * lock_scale,
             ring_start_angle, ring_end_angle, 64,
             ColorAlpha(palette->primary, global_alpha));
  }

  const float outer_end_angle = 270.0f;
  const float outer_start_angle = outer_end_angle - ring_motion * 360.0f;
  if (outer_end_angle > outer_start_angle) {
    DrawRing((Vector2){center_x, center_y}, 142.0f * lock_scale,
             145.0f * lock_scale,
             outer_start_angle, outer_end_angle, 64,
             ColorAlpha(palette->accent, global_alpha));
  }

  const PrelockLockIcon lock = {
      .position = (Vector2){center_x, center_y},
      .scale = lock_scale,
      .rotation_degrees = mix(-360.0f, 0.0f, center_motion),
      .shackle_progress = 1.0f,
      .color = ColorAlpha(palette->tertiary, global_alpha),
      .detail_color = ColorAlpha(palette->contrast, global_alpha),
  };
  prelock_draw_lock_icon(&lock);
}

const PrelockAnimation PRELOCK_ANIMATION_SWIFT = {
    .name = "swift",
    .description = "counter-moving bars and a shrinking lock",
    .duration_seconds = 1.0f,
    .draw = draw_swift,
};
