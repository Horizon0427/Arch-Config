#include "prelock/animations/meteor.h"

#include "prelock/easing.h"
#include "raylib.h"

#include <math.h>
#include <stdint.h>

#define METEOR_COUNT 220

static uint32_t mix_bits(uint32_t value) {
  value ^= value >> 16;
  value *= UINT32_C(0x7feb352d);
  value ^= value >> 15;
  value *= UINT32_C(0x846ca68b);
  return value ^ (value >> 16);
}

static float random_unit(uint32_t value) {
  return (float)(mix_bits(value) & UINT32_C(0x00ffffff)) / 16777215.0f;
}

static float mix(float start, float end, float amount) {
  return start + (end - start) * amount;
}

static float smooth_unit(float value) {
  const float clamped = prelock_clamp_unit(value);
  return clamped * clamped * (3.0f - 2.0f * clamped);
}

static float ease_slow_departure(float value) {
  const float departure_end = 0.30f;
  if (value >= departure_end) {
    return value;
  }

  const float departure = value / departure_end;
  const float eased = prelock_ease_cubic_bezier(
      departure, (Vector2){0.38f, 0.00f}, (Vector2){0.68f, 1.00f});
  return eased * departure_end;
}

static float meteor_delay(int index) {
  const uint32_t seed = (uint32_t)index + UINT32_C(1);
  return 0.015f + random_unit(seed * UINT32_C(0x9e3779b9)) * 0.17f;
}

static float meteor_finish(int index) {
  const uint32_t seed = (uint32_t)index + UINT32_C(1);
  return 0.83f + random_unit(seed * UINT32_C(0x85ebca6b)) * 0.12f;
}

static Vector2 meteor_position(int index, float progress, float screen_width,
                               float screen_height) {
  const uint32_t seed = (uint32_t)index + UINT32_C(1);
  const bool right_vortex = (index & 1) != 0;
  const float entry_seed = random_unit(seed * UINT32_C(0xc2b2ae35));
  const float radius_seed = random_unit(seed * UINT32_C(0x27d4eb2f));
  const float turn_seed = random_unit(seed * UINT32_C(0x165667b1));
  const float lane_seed = random_unit(seed * UINT32_C(0xd3a2646c));
  const float delay = meteor_delay(index);
  const float finish = meteor_finish(index);
  const float local = ease_slow_departure(
      prelock_remap_unit(progress, delay, finish));
  const Vector2 control_1 =
      right_vortex ? (Vector2){0.18f, 0.20f} : (Vector2){0.16f, 0.72f};
  const Vector2 control_2 =
      right_vortex ? (Vector2){0.40f, 1.00f} : (Vector2){0.78f, 0.28f};
  const float motion =
      prelock_ease_cubic_bezier(local, control_1, control_2);

  const Vector2 screen_center = {screen_width / 2.0f,
                                 screen_height / 2.0f};
  const float minimum_dimension = fminf(screen_width, screen_height);
  const float diagonal = hypotf(screen_width, screen_height);
  const float entry_angle = entry_seed * 2.0f * PI;
  const float entry_radius = diagonal * (0.61f + radius_seed * 0.08f);
  const Vector2 start = {
      screen_center.x + cosf(entry_angle) * entry_radius,
      screen_center.y + sinf(entry_angle) * entry_radius,
  };

  const Vector2 vortex = {
      screen_width * (right_vortex ? 0.66f : 0.34f),
      screen_height * (0.47f + (lane_seed - 0.5f) * 0.10f),
  };
  const float start_angle = atan2f(start.y - vortex.y, start.x - vortex.x);
  const float start_radius = hypotf(start.x - vortex.x, start.y - vortex.y);
  const float orbit_radius =
      minimum_dimension * (0.095f + radius_seed * 0.105f);
  const float settle = 1.0f - powf(1.0f - motion, 3.0f);
  float radius = mix(start_radius, orbit_radius, settle);

  const float collapse =
      smooth_unit(prelock_remap_unit(local, 0.56f, 0.96f));
  radius *= 1.0f - collapse;

  const float lane_limit = fminf(screen_height * 0.17f, 260.0f);
  const float lane_offset = (lane_seed * 2.0f - 1.0f) * lane_limit;
  const Vector2 spine_target = {screen_center.x,
                                screen_center.y + lane_offset};
  const float fusion =
      smooth_unit(prelock_remap_unit(local, 0.52f, 0.93f));
  Vector2 moving_center = {
      mix(vortex.x, spine_target.x, fusion),
      mix(vortex.y, spine_target.y, fusion),
  };

  const float snap =
      smooth_unit(prelock_remap_unit(progress, 0.89f, 0.99f));
  moving_center.y = mix(moving_center.y, screen_center.y, snap);
  radius *= 1.0f - snap;

  const float direction = right_vortex ? -1.0f : 1.0f;
  const float turns = 0.90f + turn_seed * 0.85f;
  const float angle = start_angle + direction * turns * 2.0f * PI * motion;
  return (Vector2){
      moving_center.x + cosf(angle) * radius,
      moving_center.y + sinf(angle) * radius,
  };
}

static Color meteor_color(int index, const PrelockPalette *palette) {
  switch (index % 8) {
  case 0:
  case 4:
    return palette->primary;
  case 2:
    return palette->tertiary;
  case 6:
    return palette->accent;
  default:
    return palette->secondary;
  }
}

static void draw_meteor_layer(const PrelockFrame *frame, bool glow_layer) {
  const float screen_width = (float)frame->screen_width;
  const float screen_height = (float)frame->screen_height;
  const float disappearance =
      smooth_unit(prelock_remap_unit(frame->progress, 0.87f, 0.995f));

  for (int index = 0; index < METEOR_COUNT; ++index) {
    const float delay = meteor_delay(index);
    if (frame->progress <= delay) {
      continue;
    }

    const uint32_t seed = (uint32_t)index + UINT32_C(1);
    const float width_seed = random_unit(seed * UINT32_C(0xa24baed5));
    const float local = prelock_remap_unit(frame->progress, delay,
                                           meteor_finish(index));
    const float appearance =
        smooth_unit(prelock_remap_unit(local, 0.0f, 0.085f));
    const float alpha = appearance * (1.0f - disappearance) *
                        frame->global_alpha;
    if (alpha <= 0.001f) {
      continue;
    }

    const Vector2 head = meteor_position(index, frame->progress, screen_width,
                                         screen_height);
    const Vector2 previous =
        meteor_position(index, fmaxf(0.0f, frame->progress - 0.0065f),
                        screen_width, screen_height);
    const float delta_x = head.x - previous.x;
    const float delta_y = head.y - previous.y;
    const float movement = hypotf(delta_x, delta_y);
    if (movement < 0.15f) {
      continue;
    }

    const float inverse_movement = 1.0f / movement;
    const float trail_length =
        fminf(118.0f, fmaxf(18.0f, movement * (2.00f + width_seed * 0.90f)));
    const Vector2 tail = {
        head.x - delta_x * inverse_movement * trail_length,
        head.y - delta_y * inverse_movement * trail_length,
    };
    const Color color = meteor_color(index, frame->palette);

    if (glow_layer) {
      DrawLineEx(tail, head, 5.0f + width_seed * 4.0f,
                 ColorAlpha(color, alpha * 0.11f));
    } else {
      const float core_width = 1.15f + width_seed * 1.45f;
      DrawLineEx(tail, head, core_width,
                 ColorAlpha(color, alpha * 0.76f));
      DrawCircleV(head, core_width * 0.82f,
                  ColorAlpha(color, alpha * 0.92f));
    }
  }
}

static void draw_meteor(const PrelockFrame *frame) {
  const float backdrop =
      smooth_unit(prelock_remap_unit(frame->progress, 0.0f, 0.42f));
  DrawRectangle(0, 0, frame->screen_width, frame->screen_height,
                ColorAlpha(frame->palette->background,
                           backdrop * 0.24f * frame->global_alpha));

  BeginBlendMode(BLEND_ADDITIVE);
  draw_meteor_layer(frame, true);
  EndBlendMode();
  draw_meteor_layer(frame, false);
}

const PrelockAnimation PRELOCK_ANIMATION_METEOR = {
    .name = "meteor",
    .description = "dual-vortex vector-field meteor swarm",
    .duration_seconds = 1.45f,
    .draw = draw_meteor,
};
