#include "prelock/desktop_capture.h"

#include <errno.h>
#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

#define PRELOCK_CAPTURE_LIMIT (128u * 1024u * 1024u)

void prelock_desktop_capture_release(PrelockDesktopCapture *capture) {
  free(capture->data);
  capture->data = NULL;
  capture->size = 0;
}

static bool child_succeeded(pid_t child) {
  int status = 0;
  while (waitpid(child, &status, 0) < 0) {
    if (errno != EINTR) {
      return false;
    }
  }
  return WIFEXITED(status) && WEXITSTATUS(status) == 0;
}

bool prelock_capture_desktop_png(PrelockDesktopCapture *capture) {
  prelock_desktop_capture_release(capture);

  int pipe_fds[2];
  if (pipe(pipe_fds) != 0) {
    perror("prelock: pipe");
    return false;
  }

  const pid_t child = fork();
  if (child < 0) {
    perror("prelock: fork");
    close(pipe_fds[0]);
    close(pipe_fds[1]);
    return false;
  }

  if (child == 0) {
    close(pipe_fds[0]);
    if (dup2(pipe_fds[1], STDOUT_FILENO) < 0) {
      _exit(126);
    }
    close(pipe_fds[1]);

    const char *output = getenv("PRELOCK_OUTPUT");
    if (output != NULL && output[0] != '\0') {
      execlp("grim", "grim", "-o", output, "-t", "png", "-l", "0",
             "-", (char *)NULL);
    } else {
      execlp("grim", "grim", "-t", "png", "-l", "0", "-",
             (char *)NULL);
    }
    _exit(127);
  }

  close(pipe_fds[1]);
  size_t capacity = 1024u * 1024u;
  size_t length = 0;
  unsigned char *data = malloc(capacity);
  bool read_ok = data != NULL;

  while (read_ok) {
    if (length == capacity) {
      if (capacity >= PRELOCK_CAPTURE_LIMIT) {
        read_ok = false;
        break;
      }
      size_t next_capacity = capacity * 2u;
      if (next_capacity > PRELOCK_CAPTURE_LIMIT) {
        next_capacity = PRELOCK_CAPTURE_LIMIT;
      }
      unsigned char *resized = realloc(data, next_capacity);
      if (resized == NULL) {
        read_ok = false;
        break;
      }
      data = resized;
      capacity = next_capacity;
    }

    const ssize_t bytes = read(pipe_fds[0], data + length, capacity - length);
    if (bytes > 0) {
      length += (size_t)bytes;
    } else if (bytes == 0) {
      break;
    } else if (errno != EINTR) {
      read_ok = false;
      break;
    }
  }

  close(pipe_fds[0]);
  const bool capture_ok = child_succeeded(child);
  if (!read_ok || !capture_ok || length == 0 || length > (size_t)INT_MAX) {
    free(data);
    return false;
  }

  capture->data = data;
  capture->size = (int)length;
  return true;
}
