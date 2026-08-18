#define _GNU_SOURCE

#include "prelock/prelock.h"

#include "prelock/animation.h"
#include "prelock/animations/registry.h"
#include "prelock/palette.h"
#include "raylib.h"

#include <fcntl.h>
#include <math.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#define PRELOCK_WINDOW_TITLE "Smooth_Prelock"
#define PRELOCK_UNLOCK_FILE "/tmp/prelock_unlocked"

static void signal_animation_ready(void) {
  const char *fifo_path = getenv("PRELOCK_READY_FIFO");
  if (fifo_path == NULL || fifo_path[0] == '\0') {
    return;
  }

  const int descriptor =
      open(fifo_path, O_WRONLY | O_NONBLOCK | O_CLOEXEC | O_NOFOLLOW);
  if (descriptor < 0) {
    return;
  }

  static const char message[] = "ready\n";
  (void)write(descriptor, message, sizeof(message) - 1u);
  close(descriptor);
}

typedef struct {
  const char *animation_name;
  bool random_animation;
  bool list_animations;
  bool show_help;
} PrelockOptions;

static void print_usage(FILE *stream, const char *program_name) {
  fprintf(stream,
          "Usage: %s [ANIMATION]\n"
          "       %s [--animation ANIMATION]\n"
          "       %s --list\n\n"
          "With no animation, one is selected at random.\n\n"
          "Options:\n"
          "  -a, --animation NAME  play a specific animation\n"
          "      --random          explicitly select at random\n"
          "      --list            list available animations\n"
          "  -h, --help            show this help\n",
          program_name, program_name, program_name);
}

static int set_animation_name(PrelockOptions *options, const char *name) {
  if (options->animation_name != NULL) {
    fprintf(stderr, "prelock: animation specified more than once\n");
    return -1;
  }
  if (options->random_animation) {
    fprintf(stderr, "prelock: --random cannot be combined with an animation\n");
    return -1;
  }

  options->animation_name = name;
  return 0;
}

static int parse_options(int argc, char *argv[], PrelockOptions *options) {
  *options = (PrelockOptions){0};

  for (int index = 1; index < argc; ++index) {
    const char *argument = argv[index];

    if (strcmp(argument, "-h") == 0 || strcmp(argument, "--help") == 0) {
      options->show_help = true;
    } else if (strcmp(argument, "--list") == 0) {
      options->list_animations = true;
    } else if (strcmp(argument, "--random") == 0) {
      if (options->animation_name != NULL) {
        fprintf(stderr,
                "prelock: --random cannot be combined with an animation\n");
        return -1;
      }
      options->random_animation = true;
    } else if (strcmp(argument, "-a") == 0 ||
               strcmp(argument, "--animation") == 0) {
      if (++index >= argc) {
        fprintf(stderr, "prelock: %s requires a name\n", argument);
        return -1;
      }
      if (set_animation_name(options, argv[index]) != 0) {
        return -1;
      }
    } else if (strncmp(argument, "--animation=", 12) == 0) {
      const char *name = argument + 12;
      if (*name == '\0') {
        fprintf(stderr, "prelock: --animation requires a name\n");
        return -1;
      }
      if (set_animation_name(options, name) != 0) {
        return -1;
      }
    } else if (argument[0] == '-') {
      fprintf(stderr, "prelock: unknown option: %s\n", argument);
      return -1;
    } else if (set_animation_name(options, argument) != 0) {
      return -1;
    }
  }

  return 0;
}

static void list_animations(FILE *stream) {
  const size_t count = prelock_animation_count();

  for (size_t index = 0; index < count; ++index) {
    const PrelockAnimation *animation = prelock_animation_at(index);
    fprintf(stream, "%-12s %s\n", animation->name, animation->description);
  }
}

static const PrelockAnimation *select_animation(const PrelockOptions *options) {
  if (options->animation_name == NULL) {
    return prelock_animation_random();
  }

  return prelock_animation_find(options->animation_name);
}

int prelock_run(int argc, char *argv[]) {
  PrelockOptions options;
  if (parse_options(argc, argv, &options) != 0) {
    print_usage(stderr, argv[0]);
    return 2;
  }

  if (options.show_help) {
    print_usage(stdout, argv[0]);
    return 0;
  }

  if (options.list_animations) {
    list_animations(stdout);
    return 0;
  }

  const PrelockAnimation *animation = select_animation(&options);
  if (animation == NULL) {
    fprintf(stderr, "prelock: unknown animation: %s\n",
            options.animation_name == NULL ? "(none)" : options.animation_name);
    fprintf(stderr, "Available animations:\n");
    list_animations(stderr);
    return 2;
  }

  const PrelockPalette palette = prelock_load_palette();
  if (animation->prepare != NULL && !animation->prepare()) {
    fprintf(stderr, "prelock: animation preparation failed: %s\n",
            animation->name);
    if (animation->unload != NULL) {
      animation->unload();
    }
    return 1;
  }

  unsigned int window_flags = FLAG_WINDOW_UNDECORATED |
                              FLAG_WINDOW_TRANSPARENT |
                              FLAG_WINDOW_RESIZABLE;
  if (animation->load != NULL) {
    window_flags |= FLAG_WINDOW_HIDDEN;
  }
  SetConfigFlags(window_flags);
  InitWindow(1920, 1080, PRELOCK_WINDOW_TITLE);
  if (!IsWindowReady()) {
    fprintf(stderr, "prelock: failed to create the animation window\n");
    if (animation->unload != NULL) {
      animation->unload();
    }
    return 1;
  }
  SetTargetFPS(60);

  if (animation->load != NULL && !animation->load(&palette)) {
    fprintf(stderr, "prelock: animation loading failed: %s\n",
            animation->name);
    if (animation->unload != NULL) {
      animation->unload();
    }
    CloseWindow();
    return 1;
  }

  if (animation->load != NULL) {
    const PrelockFrame initial_frame = {
        .screen_width = GetScreenWidth(),
        .screen_height = GetScreenHeight(),
        .elapsed_seconds = 0.0f,
        .delta_seconds = 0.0f,
        .progress = 0.0f,
        .eased_progress = 0.0f,
        .global_alpha = 1.0f,
        .palette = &palette,
    };
    BeginDrawing();
    ClearBackground(BLANK);
    animation->draw(&initial_frame);
    EndDrawing();
    ClearWindowState(FLAG_WINDOW_HIDDEN);
  }

  float animation_time = 0.0f;
  bool is_unlocked = false;
  bool readiness_signaled = false;
  float fade_out_time = 0.0f;
  const float fade_out_duration = 0.3f;

  while (!WindowShouldClose()) {
    float delta_time = GetFrameTime();
    float global_alpha = 1.0f;

    if (!is_unlocked) {
      animation_time += delta_time;
      if (animation_time > animation->duration_seconds) {
        animation_time = animation->duration_seconds;
      }

      if (!readiness_signaled &&
          animation_time >= animation->duration_seconds) {
        signal_animation_ready();
        readiness_signaled = true;
      }

      if (animation_time >= animation->duration_seconds &&
          access(PRELOCK_UNLOCK_FILE, F_OK) == 0) {
        is_unlocked = true;
        (void)remove(PRELOCK_UNLOCK_FILE);
      }
    } else {
      if (delta_time > 0.1f) {
        delta_time = 0.016f;
      }

      fade_out_time += delta_time;
      const float fade_progress = fade_out_time / fade_out_duration;
      if (fade_progress >= 1.0f) {
        break;
      }
      global_alpha = 1.0f - fade_progress;
    }

    const float progress = animation_time / animation->duration_seconds;
    const PrelockFrame frame = {
        .screen_width = GetScreenWidth(),
        .screen_height = GetScreenHeight(),
        .elapsed_seconds = animation_time,
        .delta_seconds = delta_time,
        .progress = progress,
        .eased_progress = sinf(progress * PI / 2.0f),
        .global_alpha = global_alpha,
        .palette = &palette,
    };

    BeginDrawing();
    ClearBackground(BLANK);
    animation->draw(&frame);
    EndDrawing();
  }

  if (animation->unload != NULL) {
    animation->unload();
  }
  CloseWindow();
  return 0;
}
