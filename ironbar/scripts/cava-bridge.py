#!/usr/bin/env python3

from __future__ import annotations

import argparse
import os
import selectors
import signal
import socket
import subprocess
import sys
import time
from pathlib import Path


IDLE_FRAME = ("▁" * 18 + "\n").encode()


def socket_path() -> Path:
    runtime_dir = Path(os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}"))
    bridge_dir = runtime_dir / "ironbar-cava"
    bridge_dir.mkdir(mode=0o700, parents=True, exist_ok=True)
    return bridge_dir / "bridge.sock"


def broadcast(clients: set[socket.socket], frame: bytes) -> None:
    dead: list[socket.socket] = []
    for client in clients:
        try:
            sent = client.send(frame)
            if sent != len(frame):
                dead.append(client)
        except (BlockingIOError, BrokenPipeError, ConnectionError, OSError):
            dead.append(client)

    for client in dead:
        clients.discard(client)
        client.close()


def serve(producer_path: str) -> int:
    path = socket_path()
    path.unlink(missing_ok=True)

    server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    server.bind(str(path))
    os.chmod(path, 0o600)
    server.listen()
    server.setblocking(False)

    producer = subprocess.Popen(
        [producer_path],
        stdout=subprocess.PIPE,
        bufsize=0,
    )
    if producer.stdout is None:
        return 1

    os.set_blocking(producer.stdout.fileno(), False)
    selector = selectors.DefaultSelector()
    selector.register(server, selectors.EVENT_READ, "server")
    selector.register(producer.stdout, selectors.EVENT_READ, "producer")

    clients: set[socket.socket] = set()
    latest = IDLE_FRAME
    pending = b""
    running = True

    def request_stop(_signum: int, _frame: object) -> None:
        nonlocal running
        running = False

    signal.signal(signal.SIGINT, request_stop)
    signal.signal(signal.SIGTERM, request_stop)

    try:
        while running:
            if producer.poll() is not None:
                return producer.returncode or 1

            for key, _mask in selector.select(timeout=0.5):
                if key.data == "server":
                    while True:
                        try:
                            client, _ = server.accept()
                        except BlockingIOError:
                            break

                        client.setblocking(False)
                        clients.add(client)
                        broadcast({client}, latest)
                else:
                    try:
                        chunk = os.read(producer.stdout.fileno(), 65536)
                    except BlockingIOError:
                        continue

                    if not chunk:
                        return producer.poll() or 1

                    pending += chunk
                    while b"\n" in pending:
                        line, pending = pending.split(b"\n", 1)
                        latest = line + b"\n"
                        broadcast(clients, latest)
    finally:
        selector.close()
        for client in clients:
            client.close()
        server.close()
        path.unlink(missing_ok=True)

        if producer.poll() is None:
            producer.terminate()
            try:
                producer.wait(timeout=2)
            except subprocess.TimeoutExpired:
                producer.kill()
                producer.wait()

    return 0


def watch() -> int:
    path = socket_path()
    output = sys.stdout.buffer
    showing_idle = False

    while True:
        try:
            client = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
            client.connect(str(path))
            showing_idle = False

            with client, client.makefile("rb") as stream:
                for line in stream:
                    output.write(line)
                    output.flush()
        except (FileNotFoundError, ConnectionError, OSError):
            if not showing_idle:
                output.write(IDLE_FRAME)
                output.flush()
                showing_idle = True
            time.sleep(0.25)


def main() -> int:
    parser = argparse.ArgumentParser(description="Persistent Cava bridge for Ironbar")
    subparsers = parser.add_subparsers(dest="command", required=True)

    serve_parser = subparsers.add_parser("serve")
    serve_parser.add_argument("producer")
    subparsers.add_parser("watch")
    args = parser.parse_args()

    if args.command == "serve":
        return serve(args.producer)
    return watch()


if __name__ == "__main__":
    raise SystemExit(main())
