#ifndef PRELOCK_ANIMATIONS_REGISTRY_H
#define PRELOCK_ANIMATIONS_REGISTRY_H

#include "prelock/animation.h"

#include <stddef.h>

size_t prelock_animation_count(void);
const PrelockAnimation *prelock_animation_at(size_t index);
const PrelockAnimation *prelock_animation_find(const char *name);
const PrelockAnimation *prelock_animation_random(void);

#endif
