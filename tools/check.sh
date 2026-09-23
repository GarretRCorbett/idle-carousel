#!/usr/bin/env bash
# Headless project check: imports assets, then parses every GDScript file.
# Set GODOT to your Godot 4.7 executable if it isn't on PATH, e.g.
#   export GODOT="/c/Tools/Godot/Godot_v4.7-stable_win64_console.exe"
set -u
GODOT="${GODOT:-godot}"
cd "$(dirname "$0")/.." || exit 1

if [ -d "$GODOT" ]; then
  echo "GODOT points to a folder: $GODOT" >&2
  echo "Point it at the console .exe inside that folder instead." >&2
  exit 2
fi
ver=$("$GODOT" --headless --version 2>/dev/null | tr -d '\r')
if ! echo "$ver" | grep -qE '^4\.'; then
  echo "Godot not found or not Godot 4 (got: '${ver}'). Set GODOT to your Godot 4.7 console .exe." >&2
  exit 2
fi
echo "== Godot $ver"

fail=0
echo "== Importing project"
out=$("$GODOT" --headless --path . --import 2>&1) || { echo "$out"; fail=1; }
if echo "$out" | grep -qE "SCRIPT ERROR|Parse Error|ERROR:"; then
  echo "$out" | grep -E "SCRIPT ERROR|Parse Error|ERROR:"
  fail=1
fi

echo "== Checking scripts"
while IFS= read -r -d '' f; do
  res=$("$GODOT" --headless --path . --check-only --script "res://${f#./}" 2>&1)
  if echo "$res" | grep -qE "SCRIPT ERROR|Parse Error|ERROR:"; then
    echo "FAIL $f"
    echo "$res" | grep -E "SCRIPT ERROR|Parse Error|ERROR:|at:"
    fail=1
  fi
done < <(find . -name "*.gd" -not -path "./.godot/*" -not -path "./addons/*" -print0)

if [ $fail -eq 0 ]; then echo "== PASS"; else echo "== FAIL"; fi
exit $fail
