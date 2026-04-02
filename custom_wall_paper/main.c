#include "raylib.h"
#include <dirent.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#define HEX_RADIUS 200.0f

typedef struct {
  Texture2D tex;
  char filename[256];
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

int main(void) {
  SetConfigFlags(FLAG_WINDOW_TRANSPARENT | FLAG_WINDOW_UNDECORATED);
  InitWindow(1920, 1080, "wallpicker");

  int capacity = 20;
  Wallpaper *wallpapers = malloc(capacity * sizeof(Wallpaper));
  int wpCount = 0;

  int imgSize = (int)(HEX_RADIUS * 2.0f);
  Image hexMask = GenerateHexMask(imgSize, HEX_RADIUS);

  char wp_dir[512];
  char cache_dir[512];
  const char *home = getenv("HOME");
  if (home == NULL) {
    printf("无法获取 HOME 环境变量！\n");
    free(wallpapers);
    return 1;
  }

  snprintf(wp_dir, sizeof(wp_dir), "%s/Pictures/wallpapers", home);
  snprintf(cache_dir, sizeof(cache_dir), "%s/.cache/wallpicker", home);

  char mkdir_cmd[1024];
  snprintf(mkdir_cmd, sizeof(mkdir_cmd), "mkdir -p \"%s\"", cache_dir);
  system(mkdir_cmd);

  DIR *dir;
  struct dirent *ent;
  if ((dir = opendir(wp_dir)) != NULL) {
    while ((ent = readdir(dir)) != NULL) {
      if (HasExtension(ent->d_name, ".png") ||
          HasExtension(ent->d_name, ".jpg")) {

        if (wpCount >= capacity) {
          capacity *= 2;
          wallpapers = realloc(wallpapers, capacity * sizeof(Wallpaper));
        }

        BeginDrawing();
        ClearBackground(BLANK);
        DrawText("Loading & Caching Wallpapers...", GetScreenWidth() / 2 - 250,
                 GetScreenHeight() / 2, 30, WHITE);
        DrawText(ent->d_name, GetScreenWidth() / 2 - 250,
                 GetScreenHeight() / 2 + 40, 20, GRAY);
        EndDrawing();

        char full_img_path[1024];
        char cache_img_path[1024];
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

            // 某些图片的数据经过强制转换后可能无法正常匹配Raylib，导致出现方形而非六边形，我们四舍五入一下就好了
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

        if (img.width > 1) {
          wallpapers[wpCount].tex = LoadTextureFromImage(img);
          strcpy(wallpapers[wpCount].filename, ent->d_name);

          wallpapers[wpCount].currentScale = 1.0f;
          wallpapers[wpCount].currentColor = 130.0f;
          wpCount++;
        }
        UnloadImage(img);
      }
    }
    closedir(dir);
  } else {
    printf("无法打开目录: %s\n", wp_dir);
  }

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
        // 这里调用的依然是存放在 wp_dir 里的原图
        char full_target_path[1024];
        snprintf(full_target_path, sizeof(full_target_path), "%s/%s", wp_dir,
                 wallpapers[hoveredIndex].filename);

        float relX = currentX / (float)GetScreenWidth();
        float relY = (GetScreenHeight() - currentY) / (float)GetScreenHeight();

        char cmd[2048];
        snprintf(
            cmd, sizeof(cmd),
            "("
            "awww img \"%s\" --transition-type grow --transition-pos %.3f,%.3f "
            "--transition-step 30 --transition-duration 1.2 "
            "--transition-fps 60 & "
            "ln -sf \"%s\" $HOME/.config/hypr/current_wallpaper.png ; "
            "matugen image \"%s\" --source-color-index 0 ; "
            "makoctl reload ; "
            "hyprctl reload ; "
            "sleep 0.5 ; "
            "$HOME/.config/waybar/scripts/reload-waybar.sh "
            ") > /dev/null 2>&1 &",
            full_target_path, relX, relY, full_target_path, full_target_path);

        printf("执行系统联动命令: \n%s\n", cmd);
        system(cmd);
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
