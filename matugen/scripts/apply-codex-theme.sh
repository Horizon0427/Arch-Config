#!/usr/bin/env bash
set -euo pipefail

readonly STATE_DIR="${CODEX_MATUGEN_DIR:-$HOME/.codex/matugen}"
readonly THEME_FILE="${1:-$STATE_DIR/theme.json}"
readonly SOCKET_PATH="${CODEX_APP_SERVER_SOCKET:-$HOME/.codex/app-server-control/app-server-control.sock}"
readonly LOG_FILE="$STATE_DIR/last-update.log"

mkdir -p "$STATE_DIR"
: >"$LOG_FILE"

log() {
  printf '%s\n' "$*" >>"$LOG_FILE"
}

for command_name in codex jq python3; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    log "missing command: $command_name"
    exit 1
  fi
done

if [[ ! -r "$THEME_FILE" ]]; then
  log "theme file is not readable: $THEME_FILE"
  exit 1
fi

if ! jq -e '
  def color: type == "string" and test("^#[0-9A-Fa-f]{6}$");
  .variant == "dark"
  and (.codeThemeId | type == "string" and length > 0)
  and (.theme.accent | color)
  and (.theme.ink | color)
  and (.theme.surface | color)
  and (.theme.semanticColors.diffAdded | color)
  and (.theme.semanticColors.diffRemoved | color)
  and (.theme.semanticColors.skill | color)
  and (.theme.contrast | type == "number" and . >= 0 and . <= 100 and floor == .)
  and (.theme.opaqueWindows | type == "boolean")
  and (.theme.fonts.code | type == "string" and length > 0)
  and (.theme.fonts.ui | type == "string" and length > 0)
' "$THEME_FILE" >/dev/null; then
  log "invalid Codex theme JSON: $THEME_FILE"
  exit 1
fi

python3 - "$THEME_FILE" "$SOCKET_PATH" "$LOG_FILE" <<'PY'
import json
import os
import selectors
import subprocess
import sys
import time

theme_file, socket_path, log_file = sys.argv[1:]
with open(theme_file, encoding="utf-8") as handle:
    spec = json.load(handle)

requests = [
    {
        "method": "initialize",
        "id": 1,
        "params": {
            "clientInfo": {
                "name": "matugen-codex-theme",
                "title": "Matugen Codex Theme",
                "version": "1.0.0",
            },
            "capabilities": {"experimentalApi": True},
        },
    },
    {"method": "initialized", "params": {}},
    {
        "method": "config/batchWrite",
        "id": 2,
        "params": {
            "edits": [
                {
                    "keyPath": "desktop.appearanceDarkCodeThemeId",
                    "value": spec["codeThemeId"],
                    "mergeStrategy": "replace",
                },
                {
                    "keyPath": "desktop.appearanceDarkChromeTheme",
                    "value": spec["theme"],
                    "mergeStrategy": "replace",
                },
            ],
            "reloadUserConfig": True,
        },
    },
]


def encode_requests():
    return b"".join(
        (json.dumps(request, separators=(",", ":")) + "\n").encode()
        for request in requests
    )


def check_response(line, log_handle):
    text = line.decode(errors="replace") if isinstance(line, bytes) else line
    log_handle.write(text if text.endswith("\n") else text + "\n")
    log_handle.flush()
    try:
        response = json.loads(text)
    except json.JSONDecodeError:
        return None
    if response.get("id") != 2:
        return None
    if "error" in response:
        return False
    return response.get("result", {}).get("status") in {"ok", "okOverridden"}


def apply_via_process(command, log_handle, timeout):
    process = subprocess.Popen(
        command,
        cwd=os.path.expanduser("~"),
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=log_handle,
    )
    try:
        process.stdin.write(encode_requests())
        process.stdin.flush()
        selector = selectors.DefaultSelector()
        selector.register(process.stdout, selectors.EVENT_READ)
        deadline = time.monotonic() + timeout
        while time.monotonic() < deadline:
            events = selector.select(max(0.1, deadline - time.monotonic()))
            if not events:
                break
            line = process.stdout.readline()
            if not line:
                break
            result = check_response(line, log_handle)
            if result is not None:
                return result
    finally:
        process.terminate()
        try:
            process.wait(timeout=2)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait()
    return False


with open(log_file, "a", encoding="utf-8") as log_handle:
    proxy_command = ["codex", "app-server", "proxy", "--sock", socket_path]
    if os.path.exists(socket_path) and apply_via_process(proxy_command, log_handle, 5):
        log_handle.write("applied through running Codex app-server\n")
        raise SystemExit(0)
    log_handle.write("running app-server proxy failed; falling back to stdio\n")
    if apply_via_process(["codex", "app-server", "--stdio"], log_handle, 8):
        log_handle.write("applied through temporary Codex app-server\n")
        raise SystemExit(0)
    log_handle.write("failed to apply Codex theme\n")
    raise SystemExit(1)
PY
