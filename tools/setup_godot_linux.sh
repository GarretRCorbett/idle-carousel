#!/usr/bin/env bash
# Sets up Godot on a Linux machine with no Godot installed (e.g. a Claude Code
# cloud session), so tools/check.sh can run. Downloads the official build from
# GitHub into ~/godot and prints the GODOT line to export.
#
#   bash tools/setup_godot_linux.sh            # 4.7.2-stable (the version Garret uses)
#   GODOT_VERSION=4.7.1-stable bash tools/setup_godot_linux.sh
#   export GODOT="$HOME/godot/godot"
#   bash tools/check.sh
#
# Optional: RENDER=1 also installs a virtual display and software rendering
# (xvfb + Mesa), for trying --write-movie renders without a GPU. That part
# needs apt and may not work everywhere; tests don't need it.
set -eu

VERSION="${GODOT_VERSION:-4.7.2-stable}"
DEST="$HOME/godot"
NAME="Godot_v${VERSION}_linux.x86_64"
URL="https://github.com/godotengine/godot/releases/download/${VERSION}/${NAME}.zip"

mkdir -p "$DEST"
if [ ! -x "$DEST/godot" ]; then
  echo "== Downloading $URL"
  if ! curl -fL --retry 3 -o "$DEST/godot.zip" "$URL"; then
    echo "Download failed. Check the version exists at https://github.com/godotengine/godot/releases" >&2
    echo "and re-run with GODOT_VERSION=<tag>, e.g. GODOT_VERSION=4.7.1-stable." >&2
    exit 1
  fi
  (cd "$DEST" && unzip -o -q godot.zip && rm godot.zip && mv "$NAME" godot && chmod +x godot)
fi

echo "== $("$DEST/godot" --headless --version)"

if [ "${RENDER:-0}" = "1" ]; then
  echo "== Installing a virtual display and software rendering (for renders only)"
  if command -v apt-get >/dev/null 2>&1; then
    SUDO=""
    if [ "$(id -u)" != "0" ]; then SUDO="sudo"; fi
    $SUDO apt-get update -qq
    $SUDO apt-get install -y -qq xvfb mesa-vulkan-drivers libgl1-mesa-dri >/dev/null
    echo "Render with: xvfb-run -a \"\$GODOT\" --path . --rendering-driver vulkan --audio-driver Dummy --write-movie out/f.png --fixed-fps 30 --quit-after 60 res://scenes/Game.tscn"
    echo "(If Vulkan fails, try --rendering-method gl_compatibility.)"
  else
    echo "No apt-get here; skipping. Renders can be done on Garret's machine instead." >&2
  fi
fi

echo
echo "Now run:"
echo "  export GODOT=\"$DEST/godot\""
echo "  bash tools/check.sh"
