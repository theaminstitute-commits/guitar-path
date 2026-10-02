#!/usr/bin/env bash
# Opens Guitar Path in its own window. A Chromium-based browser's app mode is used when one is
# installed (no tabs or address bar); otherwise Firefox (Linux Mint's default), otherwise the default browser.
DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
URL="file://$DIR/guitar-path.html"
for b in chromium chromium-browser google-chrome google-chrome-stable brave-browser microsoft-edge; do
  if command -v "$b" >/dev/null 2>&1; then exec "$b" --app="$URL" --window-size=1280,760; fi
done
if command -v firefox >/dev/null 2>&1; then exec firefox --new-window "$URL"; fi
exec xdg-open "$URL"
