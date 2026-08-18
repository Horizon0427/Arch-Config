#ifndef PRELOCK_EASING_H
#define PRELOCK_EASING_H

#include "raylib.h"

float prelock_clamp_unit(float value);
float prelock_remap_unit(float value, float start, float end);
float prelock_ease_cubic_bezier(float value, Vector2 control_1,
                                Vector2 control_2);

#endif
