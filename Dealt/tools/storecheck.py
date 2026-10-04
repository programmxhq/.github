#!/usr/bin/env python3
"""Checks AppStore/metadata.md fields against App Store Connect character limits."""
import re, sys

LIMITS = {"Name": 30, "Subtitle": 30, "Promotional text": 170, "Keywords": 100, "Description": 4000,
          "What's New": 4000}
text = open(sys.argv[1] if len(sys.argv) > 1 else "AppStore/metadata.md").read()
problems = 0
for title, body in re.findall(r"^## ([^\n(]+?)(?: \([^)]*\))?\n(.*?)(?=^## |\Z)", text, re.S | re.M):
    if title not in LIMITS:
        continue
    value = body.strip()
    n = len(value)
    ok = n <= LIMITS[title]
    if title == "Keywords" and ", " in value:
        ok = False
        print("Keywords: remove spaces after commas")
    problems += not ok
    print(f"{'ok ' if ok else 'BAD'} {title}: {n}/{LIMITS[title]}")
print(f"storecheck: {problems} problems")
sys.exit(1 if problems else 0)
