#ifndef PRELOCK_COMPONENTS_LOCK_ICON_H
#define PRELOCK_COMPONENTS_LOCK_ICON_H

#include "raylib.h"

typedef struct {
  Vector2 position;
  float scale;
  float rotation_degrees;
  float shackle_progress;
  Color color;
  Color detail_color;
} PrelockLockIcon;

void prelock_draw_lock_icon(const PrelockLockIcon *icon);

#endif
