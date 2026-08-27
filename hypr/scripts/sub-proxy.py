#!/usr/bin/env python3
"""Expose one subscription through a local User-Agent adapting proxy."""

from __future__ import annotations

import errno
import http.server
import os
import stat
import sys
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

LISTEN_HOST = "127.0.0.1"
LISTEN_PORT = 8199
USER_AGENT = "clash-verge/v2.4.2"
UPSTREAM_FILE = Path(
    os.environ.get(
        "SUB_PROXY_UPSTREAM_FILE",
        "~/.config/sub-proxy/upstream-url",
    )
).expanduser()
FORWARDED_HEADERS = (
    "subscription-userinfo",
    "profile-update-interval",
    "content-disposition",
    "profile-web-page-url",
)


def load_upstream_url() -> str:
    try:
        file_stat = UPSTREAM_FILE.stat()
        upstream = UPSTREAM_FILE.read_text(encoding="utf-8").strip()
    except OSError as exc:
        raise SystemExit(
            f"cannot read upstream URL file: {UPSTREAM_FILE} ({exc.strerror})"
        ) from None

    if file_stat.st_uid != os.getuid():
        raise SystemExit(
            f"upstream URL file is not owned by the current user: {UPSTREAM_FILE}"
        )
    if stat.S_IMODE(file_stat.st_mode) & 0o077:
        raise SystemExit(f"upstream URL file must have mode 0600: {UPSTREAM_FILE}")

    parsed = urllib.parse.urlsplit(upstream)
    if parsed.scheme not in {"http", "https"} or not parsed.hostname:
        raise SystemExit("upstream URL file does not contain a valid HTTP(S) URL")
    if parsed.scheme != "https":
        print("warning: upstream subscription uses unencrypted HTTP", file=sys.stderr)
    return upstream


UPSTREAM_URL = load_upstream_url()


class SubscriptionHandler(http.server.BaseHTTPRequestHandler):
    server_version = "sub-proxy/1"

    def do_GET(self) -> None:
        request_path = urllib.parse.urlsplit(self.path).path
        if request_path not in {"/", "/subscription"}:
            self.send_error(404, "not found")
            return

        request = urllib.request.Request(
            UPSTREAM_URL,
            headers={"User-Agent": USER_AGENT},
        )
        try:
            with urllib.request.urlopen(request, timeout=30) as response:
                body = response.read()
                forwarded = {
                    name: value
                    for name in FORWARDED_HEADERS
                    if (value := response.headers.get(name))
                }
        except urllib.error.HTTPError as exc:
            print(f"upstream returned HTTP {exc.code}", file=sys.stderr)
            self.send_error(502, "upstream request failed")
            return
        except (OSError, urllib.error.URLError) as exc:
            print(f"upstream request failed: {type(exc).__name__}", file=sys.stderr)
            self.send_error(502, "upstream request failed")
            return

        self.send_response(200)
        self.send_header("Content-Type", "text/yaml; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        for name, value in forwarded.items():
            self.send_header(name, value)
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, _format: str, *_args: object) -> None:
        return


class SubscriptionServer(http.server.ThreadingHTTPServer):
    allow_reuse_address = True
    daemon_threads = True


def main() -> None:
    try:
        server = SubscriptionServer((LISTEN_HOST, LISTEN_PORT), SubscriptionHandler)
    except OSError as exc:
        if exc.errno == errno.EADDRINUSE:
            raise SystemExit(
                f"{LISTEN_HOST}:{LISTEN_PORT} is already in use; "
                "check sub-proxy.service before starting another instance"
            ) from None
        raise

    print(f"sub-proxy listening on http://{LISTEN_HOST}:{LISTEN_PORT}/subscription")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
