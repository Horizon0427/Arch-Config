#include "raylib.h"
#include <dirent.h>
#include <limits.h>
#include <linux/limits.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <unistd.h>

#define HEX_RADIUS 200.0f

typedef struct {
  Texture2D tex;
  char filename[PATH_MAX];
  float currentScale;
  float currentColor;
} Wallpaper;

bool HasExtension(const char *filename, const char *ext) {
  const char *dot = strrchr(filename, '.');
  if (!dot || dot == filename)
    return false;
  return strcmp(dot, ext) == 0;
}

Image GenerateHexMask(int size, float radius) {
  Image mask = GenImageColor(size, size, BLANK);
  float cx = size / 2.0f;
  float cy = size / 2.0f;

  for (int y = 0; y < size; y++) {
    for (int x = 0; x < size; x++) {
      float dx = fabsf((float)x - cx);
      float dy = fabsf((float)y - cy);

      if (dx <= 0.866025f * radius && dy <= radius - dx * 0.57735f) {
        ImageDrawPixel(&mask, x, y, WHITE);
      } else {
        ImageDrawPixel(&mask, x, y, BLANK);
      }
    }
  }
  return mask;
}

int main(int argc, char **argv) {
  char wp_dir[PATH_MAX];

  if (argc > 1) {
    strncpy(wp_dir, argv[1], PATH_MAX - 1);
    wp_dir[PATH_MAX - 1] = '\0';
  } else {
    const char *home = getenv("HOME");
    if (home == NULL) {
      fprintf(stderr, "Error: 无法获取 HOME 环境变量！\n");
      return 1;
    }
    snprintf(wp_dir, sizeof(wp_dir), "%s/Pictures/wallpapers", home);
  }

  char cache_dir[PATH_MAX];
  const char *home = getenv("HOME");
  snprintf(cache_dir, sizeof(cache_dir), "%s/.cache/wallpicker", home);
  char mkdir_cmd[PATH_MAX + 128];
  snprintf(mkdir_cmd, sizeof(mkdir_cmd), "mkdir -p \"%s\"", cache_dir);
  system(mkdir_cmd);

  int capacity = 0;
  DIR *dir = opendir(wp_dir);
  struct dirent *ent;
  if (dir == NULL) {
    fprintf(stderr, "Error: 无法打开目录 %s\n", wp_dir);
    return 1;
  }
  while ((ent = readdir(dir)) != NULL) {
    if (HasExtension(ent->d_name, ".png") ||
        HasExtension(ent->d_name, ".jpg")) {
      capacity++;
    }
  }
  closedir(dir);

  if (capacity == 0) {
    printf("在 %s 中没有找到 .png 或 .jpg 格式的壁纸！\n", wp_dir);
    return 0;
  }

  Wallpaper *wallpapers = malloc(capacity * sizeof(Wallpaper));
  if (wallpapers == NULL) {
    fprintf(stderr,
            "Fatal Error: malloc 内存分配失败 (尝试分配 %d 个壁纸空间)\n",
            capacity);
    return 1;
  }

  SetConfigFlags(FLAG_WINDOW_TRANSPARENT | FLAG_WINDOW_UNDECORATED);
  InitWindow(1920, 1080, "wallpicker");

  int imgSize = (int)(HEX_RADIUS * 2.0f);
  Image hexMask = GenerateHexMask(imgSize, HEX_RADIUS);

  int wpCount = 0;
  dir = opendir(wp_dir);
  while ((ent = readdir(dir)) != NULL) {
    if (HasExtension(ent->d_name, ".png") ||
        HasExtension(ent->d_name, ".jpg")) {

      BeginDrawing();
      ClearBackground(BLANK);
      DrawText("Loading & Caching Wallpapers...", GetScreenWidth() / 2 - 250,
               GetScreenHeight() / 2, 30, WHITE);
      DrawText(ent->d_name, GetScreenWidth() / 2 - 250,
               GetScreenHeight() / 2 + 40, 20, GRAY);
      EndDrawing();

      char full_img_path[PATH_MAX * 2];
      char cache_img_path[PATH_MAX * 2];
      snprintf(full_img_path, sizeof(full_img_path), "%s/%s", wp_dir,
               ent->d_name);
      snprintf(cache_img_path, sizeof(cache_img_path), "%s/%s.png", cache_dir,
               ent->d_name);

      Image img;

      if (access(cache_img_path, F_OK) == 0) {
        img = LoadImage(cache_img_path);
      } else {
        img = LoadImage(full_img_path);
        if (img.width > 1) {
          float scaleX = (float)imgSize / img.width;
          float scaleY = (float)imgSize / img.height;
          float scale = (scaleX > scaleY) ? scaleX : scaleY;

          int newW = (int)roundf(img.width * scale);
          int newH = (int)roundf(img.height * scale);

          if (newW < imgSize)
            newW = imgSize;
          if (newH < imgSize)
            newH = imgSize;

          ImageResize(&img, newW, newH);

          int cropX = (newW - imgSize) / 2;
          int cropY = (newH - imgSize) / 2;
          ImageCrop(&img, (Rectangle){cropX, cropY, imgSize, imgSize});
          ImageFormat(&img, PIXELFORMAT_UNCOMPRESSED_R8G8B8A8);
          ImageAlphaMask(&img, hexMask);

          ExportImage(img, cache_img_path);
        }
      }

      if (img.width > 1 && wpCount < capacity) {
        wallpapers[wpCount].tex = LoadTextureFromImage(img);
        strncpy(wallpapers[wpCount].filename, ent->d_name, PATH_MAX - 1);
        wallpapers[wpCount].filename[PATH_MAX - 1] = '\0';

        wallpapers[wpCount].currentScale = 1.0f;
        wallpapers[wpCount].currentColor = 130.0f;
        wpCount++;
      }
      UnloadImage(img);
    }
  }
  closedir(dir);

  UnloadImage(hexMask);
  SetTargetFPS(60);

  float inradius = HEX_RADIUS * 0.866025f;
  float scrollY = 0.0f;
  float targetScrollY = 0.0f;

  while (!WindowShouldClose()) {
    Vector2 mousePoint = GetMousePosition();

    int COLS = 5;
    float spacing = 15.0f;
    float stepX = 1.73205f * HEX_RADIUS + spacing;
    float stepY = 1.5f * HEX_RADIUS + spacing;

    int totalRows = (wpCount + COLS - 1) / COLS;
    float totalWidth = COLS * stepX;
    float totalHeight = (2.0f * HEX_RADIUS) + (totalRows - 1) * stepY;

    float startX = (GetScreenWidth() - totalWidth) / 2.0f + stepX / 2.0f;
    float startY;
    float maxScroll = 0.0f;

    if (totalHeight <= GetScreenHeight()) {
      startY = (GetScreenHeight() - totalHeight) / 2.0f + HEX_RADIUS;
      targetScrollY = 0.0f;
    } else {
      startY = HEX_RADIUS + 50.0f;
      maxScroll = totalHeight - GetScreenHeight() + 100.0f;
    }

    float wheel = GetMouseWheelMove();
    if (wheel != 0.0f && maxScroll > 0.0f) {
      targetScrollY += wheel * 120.0f;
    }

    if (targetScrollY > 0.0f)
      targetScrollY = 0.0f;
    if (targetScrollY < -maxScroll)
      targetScrollY = -maxScroll;

    scrollY += (targetScrollY - scrollY) * 0.15f;

    int hoveredIndex = -1;

    for (int i = 0; i < wpCount; i++) {
      int row = i / COLS;
      int col = i % COLS;
      float currentX = startX + col * stepX;
      if (row % 2 != 0)
        currentX += stepX / 2.0f;
      float currentY = startY + row * stepY + scrollY;

      float dx = mousePoint.x - currentX;
      float dy = mousePoint.y - currentY;
      if ((dx * dx + dy * dy) <= (inradius * inradius)) {
        hoveredIndex = i;
        break;
      }
    }

    for (int i = 0; i < wpCount; i++) {
      float targetScale = (i == hoveredIndex) ? 1.15f : 1.0f;
      float targetColor = (i == hoveredIndex) ? 255.0f : 130.0f;
      wallpapers[i].currentScale +=
          (targetScale - wallpapers[i].currentScale) * 0.15f;
      wallpapers[i].currentColor +=
          (targetColor - wallpapers[i].currentColor) * 0.15f;
    }

    BeginDrawing();
    ClearBackground(BLANK);

    for (int i = 0; i < wpCount; i++) {
      if (i == hoveredIndex)
        continue;

      int row = i / COLS;
      int col = i % COLS;
      float currentX = startX + col * stepX;
      if (row % 2 != 0)
        currentX += stepX / 2.0f;
      float currentY = startY + row * stepY + scrollY;

      float scale = wallpapers[i].currentScale;
      unsigned char c = (unsigned char)wallpapers[i].currentColor;
      Color tint = (Color){c, c, c, 255};

      Rectangle sourceRec = {0, 0, imgSize, imgSize};
      Rectangle destRec = {currentX, currentY, imgSize * scale,
                           imgSize * scale};
      Vector2 origin = {(imgSize * scale) / 2.0f, (imgSize * scale) / 2.0f};

      DrawTexturePro(wallpapers[i].tex, sourceRec, destRec, origin, 0.0f, tint);
    }

    if (hoveredIndex != -1) {
      int row = hoveredIndex / COLS;
      int col = hoveredIndex % COLS;
      float currentX = startX + col * stepX;
      if (row % 2 != 0)
        currentX += stepX / 2.0f;
      float currentY = startY + row * stepY + scrollY;
      Vector2 currentCenter = {currentX, currentY};

      float scale = wallpapers[hoveredIndex].currentScale;
      unsigned char c = (unsigned char)wallpapers[hoveredIndex].currentColor;
      Color tint = (Color){c, c, c, 255};

      Rectangle sourceRec = {0, 0, imgSize, imgSize};
      Rectangle destRec = {currentX, currentY, imgSize * scale,
                           imgSize * scale};
      Vector2 origin = {(imgSize * scale) / 2.0f, (imgSize * scale) / 2.0f};

      DrawTexturePro(wallpapers[hoveredIndex].tex, sourceRec, destRec, origin,
                     0.0f, tint);
      DrawPolyLinesEx(currentCenter, 6, HEX_RADIUS * scale, 30.0f, 8.0f, WHITE);

      if (IsMouseButtonReleased(MOUSE_BUTTON_LEFT)) {
        char full_target_path[PATH_MAX * 2];
        snprintf(full_target_path, sizeof(full_target_path), "%s/%s", wp_dir,
                 wallpapers[hoveredIndex].filename);

        float relX = currentX / (float)GetScreenWidth();
        float relY = (GetScreenHeight() - currentY) / (float)GetScreenHeight();

        char relX_str[32], relY_str[32];
        snprintf(relX_str, sizeof(relX_str), "%.3f", relX);
        snprintf(relY_str, sizeof(relY_str), "%.3f", relY);

        pid_t pid = fork();

        if (pid == 0) {
          char script[] =
              "awww img \"$1\" --transition-type grow --transition-pos "
              "\"$2\",\"$3\" "
              "--transition-step 30 --transition-duration 1.2 "
              "--transition-fps 60 & "
              "ln -sf \"$1\" $HOME/.config/hypr/current_wallpaper.png ; "
              "matugen image \"$1\" --source-color-index 0 ; "
              "makoctl reload ; "
              "hyprctl reload ; "
              "sleep 0.5 ; "
              "$HOME/.config/waybar/scripts/reload-waybar.sh";
          execl("/bin/sh", "sh", "-c", script, "--", full_target_path, relX_str,
                relY_str, NULL);

          perror("execl failed");
          exit(1);

        } else if (pid < 0) {

          perror("fork failed");
        }

        printf("已通过 fork/exec 触发壁纸更换，目标文件: %s\n",
               full_target_path);

        break;
      }
    }

    if (IsKeyPressed(KEY_ESCAPE))
      break;
    EndDrawing();
  }

  for (int i = 0; i < wpCount; i++)
    UnloadTexture(wallpapers[i].tex);

  free(wallpapers);
  CloseWindow();
  return 0;
}
