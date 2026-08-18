#include "prelock/palette.h"

#include <stdbool.h>
#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static PrelockPalette fallback_palette(void) {
  return (PrelockPalette){
      .background = BLACK,
      .foreground = RAYWHITE,
      .primary = RAYWHITE,
      .secondary = RAYWHITE,
      .tertiary = RAYWHITE,
      .accent = RAYWHITE,
      .contrast = DARKGRAY,
  };
}

static char *trim_whitespace(char *text) {
  while (isspace((unsigned char)*text) != 0) {
    ++text;
  }

  char *end = text + strlen(text);
  while (end > text && isspace((unsigned char)end[-1]) != 0) {
    --end;
  }
  *end = '\0';
  return text;
}

static bool parse_hex_color(const char *text, Color *color) {
  const char *hex = text[0] == '#' ? text + 1 : text;
  if (strlen(hex) != 6) {
    return false;
  }

  unsigned int red = 0;
  unsigned int green = 0;
  unsigned int blue = 0;
  char trailing = '\0';
  if (sscanf(hex, "%2x%2x%2x%c", &red, &green, &blue, &trailing) != 3) {
    return false;
  }

  *color = (Color){(unsigned char)red, (unsigned char)green,
                   (unsigned char)blue, 255};
  return true;
}

static bool set_palette_role(PrelockPalette *palette, const char *role,
                             Color color) {
  if (strcmp(role, "background") == 0) {
    palette->background = color;
  } else if (strcmp(role, "foreground") == 0) {
    palette->foreground = color;
  } else if (strcmp(role, "primary") == 0) {
    palette->primary = color;
  } else if (strcmp(role, "secondary") == 0) {
    palette->secondary = color;
  } else if (strcmp(role, "tertiary") == 0) {
    palette->tertiary = color;
  } else if (strcmp(role, "accent") == 0) {
    palette->accent = color;
  } else if (strcmp(role, "contrast") == 0) {
    palette->contrast = color;
  } else {
    return false;
  }
  return true;
}

static bool palette_path(char *path, size_t path_size) {
  const char *config_home = getenv("XDG_CONFIG_HOME");
  int length;
  if (config_home != NULL && config_home[0] != '\0') {
    length = snprintf(path, path_size, "%s/prelock/palette.conf", config_home);
  } else {
    const char *home = getenv("HOME");
    if (home == NULL || home[0] == '\0') {
      return false;
    }
    length = snprintf(path, path_size,
                      "%s/.config/prelock/palette.conf", home);
  }
  return length >= 0 && (size_t)length < path_size;
}

PrelockPalette prelock_load_palette(void) {
  PrelockPalette palette = fallback_palette();
  char path[4096];
  if (!palette_path(path, sizeof(path))) {
    fprintf(stderr,
            "prelock: palette path unavailable; using monochrome fallback\n");
    return palette;
  }

  FILE *file = fopen(path, "r");
  if (file == NULL) {
    fprintf(stderr,
            "prelock: palette not found at %s; using monochrome fallback\n",
            path);
    return palette;
  }

  char line[256];
  int loaded_roles = 0;
  while (fgets(line, sizeof(line), file) != NULL) {
    char *text = trim_whitespace(line);
    if (*text == '\0') {
      continue;
    }

    char *separator = strchr(text, '=');
    if (separator == NULL) {
      continue;
    }

    *separator = '\0';
    char *role = trim_whitespace(text);
    char *value = trim_whitespace(separator + 1);
    Color color;
    if (parse_hex_color(value, &color) &&
        set_palette_role(&palette, role, color)) {
      ++loaded_roles;
    }
  }
  fclose(file);

  if (loaded_roles == 0) {
    fprintf(stderr,
            "prelock: palette at %s has no valid roles; using monochrome "
            "fallback\n",
            path);
  }

  return palette;
}
