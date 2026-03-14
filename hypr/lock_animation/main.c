#include "raylib.h"
#include "rlgl.h"
#include <math.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

Color GetMatugenColor() {
  char path[256];
  snprintf(path, sizeof(path), "%s/.config/hypr/lock_animation/prelock_color",
           getenv("HOME"));
  FILE *file = fopen(path, "r");
  if (!file)
    return RAYWHITE;

  char hexStr[7];
  if (fscanf(file, "%6s", hexStr) != 1) {
    fclose(file);
    return RAYWHITE;
  }
  fclose(file);

  unsigned int hexValue;
  sscanf(hexStr, "%x", &hexValue);

  return (Color){(hexValue >> 16) & 0xFF, (hexValue >> 8) & 0xFF,
                 hexValue & 0xFF, 255};
}

int main(void) {
  SetConfigFlags(FLAG_WINDOW_UNDECORATED | FLAG_WINDOW_TRANSPARENT |
                 FLAG_WINDOW_RESIZABLE);
  InitWindow(1920, 1080, "Smooth_Prelock");
  SetTargetFPS(60);

  float animTime = 0.0f;
  const float animDuration = 1.2f;

  bool isUnlocked = false;
  float fadeOutTime = 0.0f;
  const float fadeOutDuration = 0.3f;

  Color primaryColor = GetMatugenColor();

  while (!WindowShouldClose()) {
    float deltaTime = GetFrameTime();
    float globalAlpha = 1.0f;

    if (!isUnlocked) {
      animTime += deltaTime;
      if (animTime > animDuration) {
        animTime = animDuration;
      }

      float progress = animTime / animDuration;

      if (progress >= 1.0f) {
        if (access("/tmp/prelock_unlocked", F_OK) != -1) {
          isUnlocked = true;
          remove("/tmp/prelock_unlocked");
        }
      }
    } else {
      if (deltaTime > 0.1f)
        deltaTime = 0.016f;

      fadeOutTime += deltaTime;
      float fadeProgress = fadeOutTime / fadeOutDuration;

      if (fadeProgress >= 1.0f) {
        break;
      }
      globalAlpha = 1.0f - fadeProgress;
    }

    float progress = animTime / animDuration;
    float easeOut = sin(progress * PI / 2.0f);

    BeginDrawing();
    ClearBackground(BLANK);

    DrawRectangle(0, 0, GetScreenWidth(), GetScreenHeight(),
                  Fade(BLACK, easeOut * 0.6f * globalAlpha));

    int centerX = GetScreenWidth() / 2;
    int centerY = GetScreenHeight() / 2;

    float lineStartOffset = (easeOut * 120.0f) + 30.0f;
    float lineLength = easeOut * (GetScreenWidth() / 2.0f);

    Color rayColor = Fade(primaryColor, (1.0f - progress) * globalAlpha);

    DrawLineEx((Vector2){centerX - lineStartOffset, centerY},
               (Vector2){centerX - lineStartOffset - lineLength, centerY}, 2.0f,
               rayColor);

    DrawLineEx((Vector2){centerX + lineStartOffset, centerY},
               (Vector2){centerX + lineStartOffset + lineLength, centerY}, 2.0f,
               rayColor);

    float outerRadius = easeOut * 120.0f;
    float outerThickness = 12.0f;
    float startAngle = 270.0f;
    float endAngle = 270.0f + (easeOut * 360.0f);
    DrawRing((Vector2){centerX, centerY}, outerRadius - outerThickness,
             outerRadius, startAngle, endAngle, 64,
             Fade(primaryColor, (1.0f - progress * 0.2f) * globalAlpha));

    float revRadius = easeOut * 145.0f;
    float revThickness = 3.0f;
    float revStartAngle = 270.0f - (easeOut * 360.0f);
    float revEndAngle = 270.0f;

    DrawRing((Vector2){centerX, centerY}, revRadius - revThickness, revRadius,
             revStartAngle, revEndAngle, 64,
             Fade(primaryColor, (1.0f - progress * 0.2f) * 0.6f * globalAlpha));

    rlPushMatrix();
    rlTranslatef(centerX, centerY, 0);

    float lockRotation = (1.0f - easeOut) * -180.0f;
    rlRotatef(lockRotation, 0, 0, 1);

    float shackleProgress = 0.0f;
    if (progress > 0.4f) {
      shackleProgress = (progress - 0.4f) / 0.35f;
    }
    if (shackleProgress > 1.0f) {
      shackleProgress = 1.0f;
    }

    float shackleEase = sin(shackleProgress * PI / 2.0f);
    float shackleY = -18.0f * (1.0f - shackleEase);

    Color lockColor =
        Fade(primaryColor, (1.0f - progress * 0.2f) * globalAlpha);

    float baseY = -22.0f + shackleY;

    DrawRing((Vector2){0, baseY}, 10, 18, 180, 360, 32, lockColor);
    DrawLineEx((Vector2){-14, baseY}, (Vector2){-14, baseY + 34.0f}, 8.0f,
               lockColor);
    DrawLineEx((Vector2){14, baseY}, (Vector2){14, baseY + 18.0f}, 8.0f,
               lockColor);

    DrawRectangleRounded((Rectangle){-25, -10, 50, 38}, 0.3f, 16, lockColor);

    DrawCircle(0, 5, 4, Fade(DARKGRAY, globalAlpha));
    DrawTriangle((Vector2){0, 3}, (Vector2){-4, 14}, (Vector2){4, 14},
                 Fade(DARKGRAY, globalAlpha));

    rlPopMatrix();

    EndDrawing();
  }

  CloseWindow();

  return 0;
}
