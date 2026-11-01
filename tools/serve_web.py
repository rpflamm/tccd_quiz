#!/usr/bin/env python3
"""Serve the Web export locally with correct MIME types (fixes the audio worklet on Windows).

Usage: python3 tools/serve_web.py [directory] [port]
       defaults: export/web 8060  ->  open http://localhost:8060/
"""
import functools
import http.server
import os
import sys

MIME = {
    ".html": "text/html",
    ".js": "text/javascript",
    ".mjs": "text/javascript",
    ".wasm": "application/wasm",
    ".pck": "application/octet-stream",
    ".png": "image/png",
    ".svg": "image/svg+xml",
    ".json": "application/json",
}


class Handler(http.server.SimpleHTTPRequestHandler):
    # Python reads .js types from the Windows registry, which is often text/plain.
    extensions_map = {**http.server.SimpleHTTPRequestHandler.extensions_map, **MIME}

    def end_headers(self):
        self.send_header("Cache-Control", "no-cache")
        super().end_headers()


def main():
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    directory = sys.argv[1] if len(sys.argv) > 1 else os.path.join(root, "export", "web")
    port = int(sys.argv[2]) if len(sys.argv) > 2 else 8060
    if not os.path.isfile(os.path.join(directory, "index.html")):
        sys.exit(f"No index.html in {directory} - export the 'Web' preset first.")
    handler = functools.partial(Handler, directory=directory)
    with http.server.ThreadingHTTPServer(("127.0.0.1", port), handler) as httpd:
        print(f"Serving {directory} at http://localhost:{port}/  (Ctrl+C to stop)")
        httpd.serve_forever()


if __name__ == "__main__":
    main()
