#!/usr/bin/env python3
"""Local Language Roulette admin server (no Node required)."""

from __future__ import annotations

import json
import mimetypes
import os
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import unquote, urlparse

ROOT = Path(__file__).resolve().parent
REPO_ROOT = ROOT.parent
PORT = int(os.environ.get("PORT", "5180"))

CONTENT_TARGETS = [
    REPO_ROOT / "content" / "content.json",
    REPO_ROOT / "admin" / "content" / "content.json",
    REPO_ROOT / "LanguageRoulette" / "Resources" / "content" / "content.json",
]


class AdminHandler(BaseHTTPRequestHandler):
    def log_message(self, fmt: str, *args) -> None:
        print("%s - %s" % (self.address_string(), fmt % args))

    def _send(self, status: int, body: bytes, content_type: str) -> None:
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self) -> None:  # noqa: N802
        path = unquote(urlparse(self.path).path)
        if path == "/":
            path = "/index.html"
        file_path = (ROOT / path.lstrip("/")).resolve()
        if not str(file_path).startswith(str(ROOT)) or not file_path.is_file():
            self._send(404, b"Not found", "text/plain; charset=utf-8")
            return
        content_type = mimetypes.guess_type(str(file_path))[0] or "application/octet-stream"
        if content_type.startswith("text/") or content_type in {
            "application/json",
            "application/javascript",
        }:
            content_type = f"{content_type}; charset=utf-8"
        self._send(200, file_path.read_bytes(), content_type)

    def do_POST(self) -> None:  # noqa: N802
        path = urlparse(self.path).path
        if path != "/api/save-content":
            self._send(404, b"Not found", "text/plain; charset=utf-8")
            return
        length = int(self.headers.get("Content-Length", "0"))
        raw = self.rfile.read(length)
        try:
            parsed = json.loads(raw.decode("utf-8"))
            pretty = json.dumps(parsed, ensure_ascii=False, indent=2) + "\n"
            saved = []
            for target in CONTENT_TARGETS:
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text(pretty, encoding="utf-8")
                saved.append(str(target))
            body = json.dumps({"ok": True, "saved": saved}).encode("utf-8")
            self._send(200, body, "application/json; charset=utf-8")
        except Exception as exc:  # noqa: BLE001
            self._send(500, str(exc).encode("utf-8"), "text/plain; charset=utf-8")


def main() -> None:
    server = ThreadingHTTPServer(("127.0.0.1", PORT), AdminHandler)
    print(f"Language Roulette admin running at http://localhost:{PORT}")
    print("Save writes:")
    for target in CONTENT_TARGETS:
        print(f" - {target}")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nStopped.")
        server.server_close()


if __name__ == "__main__":
    main()
