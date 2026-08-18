#ifndef PRELOCK_ANIMATION_H
#define PRELOCK_ANIMATION_H

#include "prelock/palette.h"

#include <stdbool.h>

typedef struct {
  int screen_width;
  int screen_height;
  float elapsed_seconds;
  float delta_seconds;
  float progress;
  float eased_progress;
  float global_alpha;
  const PrelockPalette *palette;
} PrelockFrame;

typedef struct {
  const char *name;
  const char *description;
  float duration_seconds;
  bool (*prepare)(void);
  bool (*load)(const PrelockPalette *palette);
  void (*unload)(void);
  void (*draw)(const PrelockFrame *frame);
} PrelockAnimation;

#endif
