#include "prelock/components/lock_icon.h"

#include "raylib.h"
#include "rlgl.h"

#include <math.h>

static float clamp_unit(float value) {
  if (value < 0.0f) {
    return 0.0f;
  }
  if (value > 1.0f) {
    return 1.0f;
  }
  return value;
}

void prelock_draw_lock_icon(const PrelockLockIcon *icon) {
  const float shackle_progress = clamp_unit(icon->shackle_progress);
  const float shackle_ease = sinf(shackle_progress * PI / 2.0f);
  const float shackle_y = -18.0f * (1.0f - shackle_ease);
  const float base_y = -22.0f + shackle_y;

  rlPushMatrix();
  rlTranslatef(icon->position.x, icon->position.y, 0.0f);
  rlRotatef(icon->rotation_degrees, 0.0f, 0.0f, 1.0f);
  rlScalef(icon->scale, icon->scale, 1.0f);

  DrawRing((Vector2){0.0f, base_y}, 10.0f, 18.0f, 180.0f, 360.0f, 32,
           icon->color);
  DrawLineEx((Vector2){-14.0f, base_y},
             (Vector2){-14.0f, base_y + 34.0f}, 8.0f, icon->color);
  DrawLineEx((Vector2){14.0f, base_y},
             (Vector2){14.0f, base_y + 18.0f}, 8.0f, icon->color);
  DrawRectangleRounded((Rectangle){-25.0f, -10.0f, 50.0f, 38.0f}, 0.3f, 16,
                       icon->color);
  DrawCircleV((Vector2){0.0f, 5.0f}, 4.0f, icon->detail_color);
  DrawTriangle((Vector2){0.0f, 3.0f}, (Vector2){-4.0f, 14.0f},
               (Vector2){4.0f, 14.0f}, icon->detail_color);

  rlPopMatrix();
}
