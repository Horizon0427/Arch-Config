#ifndef PRELOCK_PALETTE_H
#define PRELOCK_PALETTE_H

#include "raylib.h"

typedef struct {
  Color background;
  Color foreground;
  Color primary;
  Color secondary;
  Color tertiary;
  Color accent;
  Color contrast;
} PrelockPalette;

PrelockPalette prelock_load_palette(void);

#endif
