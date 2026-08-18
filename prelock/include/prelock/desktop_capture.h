#ifndef PRELOCK_DESKTOP_CAPTURE_H
#define PRELOCK_DESKTOP_CAPTURE_H

#include <stdbool.h>

typedef struct {
  unsigned char *data;
  int size;
} PrelockDesktopCapture;

bool prelock_capture_desktop_png(PrelockDesktopCapture *capture);
void prelock_desktop_capture_release(PrelockDesktopCapture *capture);

#endif
