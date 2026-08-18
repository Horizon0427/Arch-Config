#include "prelock/animations/registry.h"

#include "prelock/animations/classic.h"
#include "prelock/animations/diagonal.h"
#include "prelock/animations/liquid.h"
#include "prelock/animations/meteor.h"
#include "prelock/animations/swift.h"

#include <stdint.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

static const PrelockAnimation *const ANIMATIONS[] = {
    &PRELOCK_ANIMATION_CLASSIC,
    &PRELOCK_ANIMATION_SWIFT,
    &PRELOCK_ANIMATION_DIAGONAL,
    &PRELOCK_ANIMATION_METEOR,
    &PRELOCK_ANIMATION_LIQUID,
};

size_t prelock_animation_count(void) {
  return sizeof(ANIMATIONS) / sizeof(ANIMATIONS[0]);
}

const PrelockAnimation *prelock_animation_at(size_t index) {
  if (index >= prelock_animation_count()) {
    return NULL;
  }
  return ANIMATIONS[index];
}

const PrelockAnimation *prelock_animation_find(const char *name) {
  for (size_t index = 0; index < prelock_animation_count(); ++index) {
    if (strcmp(ANIMATIONS[index]->name, name) == 0) {
      return ANIMATIONS[index];
    }
  }
  return NULL;
}

static uint64_t mix_seed(uint64_t value) {
  value ^= value >> 30;
  value *= UINT64_C(0xbf58476d1ce4e5b9);
  value ^= value >> 27;
  value *= UINT64_C(0x94d049bb133111eb);
  return value ^ (value >> 31);
}

const PrelockAnimation *prelock_animation_random(void) {
  const size_t count = prelock_animation_count();
  if (count == 0) {
    return NULL;
  }

  struct timespec now = {0};
  (void)timespec_get(&now, TIME_UTC);
  uint64_t seed = (uint64_t)now.tv_sec ^ ((uint64_t)now.tv_nsec << 32);
  seed ^= (uint64_t)(unsigned int)getpid();
  seed ^= (uint64_t)(uintptr_t)&seed;

  return ANIMATIONS[mix_seed(seed) % count];
}
