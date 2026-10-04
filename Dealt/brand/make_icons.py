#!/usr/bin/env python3
"""Generates the Dealt app icon SVGs (light, dark, tinted) from one geometry.

Render to PNG with render.sh. Edit the constants here, not the SVGs.
"""
import math, os

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "svg")
S = 1024

# The five life stages, dawn to dusk (iOS system colours, matching Stage.palette.accent).
STAGES = ["#34C759", "#FF2D55", "#007AFF", "#FF9500", "#5856D6"]

# Card geometry
CW, CH, CR = 480, 660, 72
CX, CY = S / 2, S / 2 + 10
# Life arc on the card: five stage dots rising from the horizon and setting again.
AR, DOT = 156, 41
AX, AY = CX, CY + (AR + DOT * 1.2 - 24) / 2 + 8


def card(x, y, angle, fill, extra="", trim=0):
    """trim shortens the card from the top, so rotated back cards don't peek over the front one."""
    return (f'<rect x="{x - CW / 2:.1f}" y="{y - CH / 2 + trim:.1f}" width="{CW}" height="{CH - trim}" rx="{CR}" '
            f'fill="{fill}" transform="rotate({angle} {CX} {CY + CH / 2 + 140})" {extra}/>')


def arc_dots(colors, line):
    parts = []
    # The horizon the day rises from and sets into.
    parts.append(f'<line x1="{AX - AR - 52}" y1="{AY + DOT + 26}" x2="{AX + AR + 52}" y2="{AY + DOT + 26}" '
                 f'stroke="{line}" stroke-width="14" stroke-linecap="round"/>')
    for i, c in enumerate(colors):
        a = math.pi - i * math.pi / 4
        x, y = AX + AR * math.cos(a), AY - AR * math.sin(a)
        r = DOT * (1.18 if i == 2 else 1.0)
        parts.append(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{r:.1f}" fill="{c}"/>')
    return "\n  ".join(parts)


def icon(name, bg_top, bg_bottom, back_left, back_right, face, line, dots, shadow=True):
    defs = f'''<defs>
    <linearGradient id="bg" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="{bg_top}"/><stop offset="1" stop-color="{bg_bottom}"/>
    </linearGradient>
    <filter id="sh" x="-30%" y="-30%" width="160%" height="160%">
      <feDropShadow dx="0" dy="18" stdDeviation="22" flood-color="#000" flood-opacity="0.35"/>
    </filter>
  </defs>'''
    f = 'filter="url(#sh)"' if shadow else ""
    svg = f'''<svg xmlns="http://www.w3.org/2000/svg" width="{S}" height="{S}" viewBox="0 0 {S} {S}">
  {defs}
  <rect width="{S}" height="{S}" fill="url(#bg)"/>
  {card(CX, CY, -11, back_left, trim=70)}
  {card(CX, CY, 11, back_right, trim=70)}
  {card(CX, CY, 0, face, f)}
  {arc_dots(dots, line)}
</svg>
'''
    os.makedirs(OUT, exist_ok=True)
    with open(os.path.join(OUT, name + ".svg"), "w") as fh:
        fh.write(svg)


icon("AppIcon", "#2D2667", "#141030", "#4B4390", "#5E55A8", "#FFF8EC", "#1C183826", STAGES)
icon("AppIcon-Dark", "#1A1733", "#07060F", "#2A264D", "#353060", "#302B5E", "#FFFFFF2E",
     ["#30D158", "#FF375F", "#0A84FF", "#FF9F0A", "#7D7AFF"])
icon("AppIcon-Tinted", "#000000", "#000000", "#262626", "#333333", "#4A4A4A", "#FFFFFF40",
     ["#FFFFFF"] * 5, shadow=False)
print("wrote", sorted(os.listdir(OUT)))
