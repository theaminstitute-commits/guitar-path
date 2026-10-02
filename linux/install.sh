#!/usr/bin/env bash
# Installs Guitar Path for the current user (no sudo needed): copies the game to
# ~/.local/share/guitar-path and adds "Guitar Path" to the application menu.
set -euo pipefail
SRC="$(cd "$(dirname "$0")" && pwd)"
DATA="${XDG_DATA_HOME:-$HOME/.local/share}"
DEST="$DATA/guitar-path"
APPS="$DATA/applications"
mkdir -p "$DEST" "$APPS"
cp "$SRC/guitar-path.html" "$SRC/guitar-path.sh" "$SRC/guitar-path.svg" "$DEST/"
chmod +x "$DEST/guitar-path.sh"
cat > "$APPS/guitar-path.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Guitar Path
Comment=Learn the guitar fretboard one triad at a time
Exec="$DEST/guitar-path.sh"
Icon=$DEST/guitar-path.svg
Terminal=false
Categories=Education;Game;
EOF
chmod +x "$APPS/guitar-path.desktop"
update-desktop-database "$APPS" >/dev/null 2>&1 || true
echo "Guitar Path is installed."
echo "Open it from the menu (Education or Games), or run: $DEST/guitar-path.sh"
