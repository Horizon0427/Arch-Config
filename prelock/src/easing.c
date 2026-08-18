#include "prelock/easing.h"

float prelock_clamp_unit(float value) {
  if (value < 0.0f) {
    return 0.0f;
  }
  if (value > 1.0f) {
    return 1.0f;
  }
  return value;
}

float prelock_remap_unit(float value, float start, float end) {
  return prelock_clamp_unit((value - start) / (end - start));
}

float prelock_ease_cubic_bezier(float value, Vector2 control_1,
                                Vector2 control_2) {
  const float target_x = prelock_clamp_unit(value);
  if (target_x <= 0.0f || target_x >= 1.0f) {
    return target_x;
  }

  const Vector2 start = {0.0f, 0.0f};
  const Vector2 end = {1.0f, 1.0f};
  float lower = 0.0f;
  float upper = 1.0f;
  float parameter = target_x;

  for (int iteration = 0; iteration < 14; ++iteration) {
    const Vector2 point = GetSplinePointBezierCubic(
        start, control_1, control_2, end, parameter);
    if (point.x < target_x) {
      lower = parameter;
    } else {
      upper = parameter;
    }
    parameter = (lower + upper) / 2.0f;
  }

  const Vector2 point = GetSplinePointBezierCubic(
      start, control_1, control_2, end, parameter);
  return prelock_clamp_unit(point.y);
}
