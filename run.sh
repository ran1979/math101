#!/usr/bin/env bash
# Build the web export and serve it locally.
#   ./run.sh            export + serve on http://localhost:8000
#   ./run.sh 9000       custom port
#   ./run.sh --native   run in a native Godot window instead
set -euo pipefail
cd "$(dirname "$0")"

GODOT="${GODOT:-godot}"
command -v "$GODOT" >/dev/null || { echo "Godot not found. Install Godot 4 or set GODOT=/path/to/godot"; exit 1; }

if [[ "${1:-}" == "--native" ]]; then
  exec "$GODOT" --path .
fi

PORT="${1:-8000}"
mkdir -p build/web
echo "Exporting web build..."
"$GODOT" --headless --path . --export-release "Web" build/web/index.html
echo "Serving at http://localhost:$PORT  (Ctrl+C to stop)"
( sleep 1; : open "http://localhost:$PORT" 2>/dev/null || xdg-open "http://localhost:$PORT" 2>/dev/null || true ) &
cd build/web && exec python3 -m http.server "$PORT"
