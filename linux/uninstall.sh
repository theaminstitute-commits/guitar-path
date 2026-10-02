#!/usr/bin/env bash
# Removes Guitar Path and its menu entry.
set -euo pipefail
DATA="${XDG_DATA_HOME:-$HOME/.local/share}"
rm -rf "$DATA/guitar-path"
rm -f "$DATA/applications/guitar-path.desktop"
update-desktop-database "$DATA/applications" >/dev/null 2>&1 || true
echo "Guitar Path has been removed."
