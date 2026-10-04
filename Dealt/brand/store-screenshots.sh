#!/bin/bash
# Frames raw 6.9" simulator captures (from the CI artifact dealt-xcode26-ios26) into App Store screenshots.
# Usage: brand/store-screenshots.sh <dir with 01-start.png ... 09-next-generation.png>
set -euo pipefail
cd "$(dirname "$0")"
RAW="$(realpath "$1")"
OUT="$(realpath -m ../AppStore/screenshots)"
mkdir -p "$OUT"
CHROME="${CHROME:-$(ls -d ~/.cache/ms-playwright/chromium_headless_shell-*/chrome-headless-shell-linux64/chrome-headless-shell | sort -V | tail -1)}"
enc() { python3 -c 'import sys,urllib.parse;print(urllib.parse.quote(sys.argv[1]))' "$1"; }
shot() { # n raw stage headline subline
  local url="file://$PWD/store-shot.html?img=$(enc "file://$RAW/$2.png")&stage=$3&h=$(enc "$4")&s=$(enc "$5")"
  "$CHROME" --headless --no-sandbox --hide-scrollbars --force-device-scale-factor=1 --allow-file-access-from-files \
    --window-size=1320,2868 --virtual-time-budget=3000 --screenshot="$OUT/$1.png" "$url" >/dev/null 2>&1
  echo "$OUT/$1.png"
}
shot 1-hand        06-midlife-hand    2 "Life deals you three cards." "Play one. Let the other two go."
shot 2-card        04-card            0 "Every choice has a price."   "Play it safe, or roll the dice."
shot 3-ambition    02-ambition        1 "Choose what you live for."   "Fortune, fame, family, or something wilder."
shot 4-outcome     05-outcome         3 "Small moments, big ripples." "Every card changes who you become."
shot 5-epitaph     07-summary         4 "Write your own epitaph."      "Score your life. Pass on an heirloom."
shot 6-legacy      09-next-generation 0 "Your story outlives you."     "Each heir inherits what you leave behind."
