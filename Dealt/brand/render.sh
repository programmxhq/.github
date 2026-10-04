#!/bin/bash
# Renders brand/svg/*.svg to PNG with headless Chromium (Playwright's build).
# Usage: brand/render.sh <svg> <png> <width> <height> [transparent]
set -euo pipefail
CHROME="${CHROME:-$(ls -d ~/.cache/ms-playwright/chromium_headless_shell-*/chrome-headless-shell-linux64/chrome-headless-shell 2>/dev/null | sort -V | tail -1)}"
in="$(realpath "$1")"; out="$(realpath -m "$2")"; w="$3"; h="$4"
bg=()
[ "${5:-}" = "transparent" ] && bg=(--default-background-color=00000000)
"$CHROME" --headless --no-sandbox --hide-scrollbars --force-device-scale-factor=1 \
  --window-size="$w,$h" "${bg[@]}" --screenshot="$out" "file://$in" >/dev/null 2>&1
echo "$out"
