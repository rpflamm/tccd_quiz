#!/usr/bin/env python3
"""Generate the project's own minimal stroke icons (24x24 grid, white, tinted in Godot).

Usage: python tools/gen_icons.py   -> writes assets/icons/<name>.svg
All icons are original drawings for this project (no third-party icon set).
"""
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "icons")

STROKE = 'fill="none" stroke="#fff" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"'
FILL = 'fill="#fff"'

ICONS = {
    "heart": f'<path {FILL} d="M12 21 C5 15.5 2 12.3 2 8.5 C2 5.4 4.4 3 7.4 3 C9.2 3 10.9 3.9 12 5.3 C13.1 3.9 14.8 3 16.6 3 C19.6 3 22 5.4 22 8.5 C22 12.3 19 15.5 12 21 Z"/>',
    "heart_empty": f'<path {STROKE} d="M12 20 C5.5 15 3 12 3 8.6 C3 6 5 4 7.5 4 C9.2 4 10.8 5 12 6.6 C13.2 5 14.8 4 16.5 4 C19 4 21 6 21 8.6 C21 12 18.5 15 12 20 Z"/>',
    "flame": f'<path {FILL} d="M12 2 C13 6 18 8.5 18 14 C18 18.4 15.3 22 12 22 C8.7 22 6 18.6 6 14.8 C6 11.7 7.6 9.8 9 8.6 C9 10.6 10 12 11.2 12.4 C10.6 8.8 11 5 12 2 Z"/>',
    "clock": f'<circle {STROKE} cx="12" cy="12" r="9"/><path {STROKE} d="M12 7 V12 L15.5 14"/>',
    "flag": f'<path {STROKE} d="M5 21 V4"/><path {FILL} d="M5 4 H18 L15.5 8 L18 12 H5 Z"/>',
    "star": f'<path {FILL} d="M12 2.5 L14.9 8.6 L21.5 9.4 L16.6 13.9 L17.9 20.5 L12 17.2 L6.1 20.5 L7.4 13.9 L2.5 9.4 L9.1 8.6 Z"/>',
    "trophy": f'<path {STROKE} d="M7 4 H17 V9 C17 12 14.8 14 12 14 C9.2 14 7 12 7 9 Z"/><path {STROKE} d="M7 6 H4 C4 9 5.5 10.5 7.5 10.8 M17 6 H20 C20 9 18.5 10.5 16.5 10.8"/><path {STROKE} d="M12 14 V18 M8 21 H16 M9 18 H15"/>',
    "check": f'<path {STROKE} stroke-width="3" d="M4.5 12.5 L9.5 17.5 L19.5 6.5"/>',
    "cross": f'<path {STROKE} stroke-width="3" d="M6 6 L18 18 M18 6 L6 18"/>',
    "book": f'<path {STROKE} d="M4 5 C6.5 4 9.5 4 12 6 C14.5 4 17.5 4 20 5 V19 C17.5 18 14.5 18 12 20 C9.5 18 6.5 18 4 19 Z"/><path {STROKE} d="M12 6 V20"/>',
    "gear": f'<circle {STROKE} cx="12" cy="12" r="3.2"/><path {STROKE} d="M12 2.8 V5.2 M12 18.8 V21.2 M2.8 12 H5.2 M18.8 12 H21.2 M5.5 5.5 L7.2 7.2 M16.8 16.8 L18.5 18.5 M5.5 18.5 L7.2 16.8 M16.8 7.2 L18.5 5.5"/><circle {STROKE} cx="12" cy="12" r="6.8"/>',
    "chart": f'<path {STROKE} d="M4 20 H20"/><path {FILL} d="M5.5 13 H8.5 V18.5 H5.5 Z M10.5 8 H13.5 V18.5 H10.5 Z M15.5 4.5 H18.5 V18.5 H15.5 Z"/>',
    "arrow_left": f'<path {STROKE} d="M19 12 H5 M11 6 L5 12 L11 18"/>',
    "arrow_right": f'<path {STROKE} d="M5 12 H19 M13 6 L19 12 L13 18"/>',
    "bolt": f'<path {FILL} d="M13.5 2 L4.5 13.5 H11 L10 22 L19.5 10 H13 Z"/>',
    "shield": f'<path {STROKE} d="M12 3 L20 6 V11.5 C20 16.2 16.6 19.8 12 21 C7.4 19.8 4 16.2 4 11.5 V6 Z"/><path {STROKE} d="M8.5 12 L11 14.5 L15.8 9.5"/>',
    "calendar": f'<rect {STROKE} x="3.5" y="5" width="17" height="15.5" rx="2.5"/><path {STROKE} d="M3.5 10 H20.5 M8 3 V7 M16 3 V7"/><path {FILL} d="M7 13 H10 V16 H7 Z"/>',
    "play": f'<path {FILL} d="M7 4.5 L19.5 12 L7 19.5 Z"/>',
    "external": f'<path {STROKE} d="M14 4 H20 V10 M20 4 L11 13"/><path {STROKE} d="M18 14 V19 C18 19.6 17.6 20 17 20 H5 C4.4 20 4 19.6 4 19 V7 C4 6.4 4.4 6 5 6 H10"/>',
    "grid": f'<path {FILL} d="M4 4 H10 V10 H4 Z M14 4 H20 V10 H14 Z M4 14 H10 V20 H4 Z M14 14 H20 V20 H14 Z"/>',
    "refresh": f'<path {STROKE} d="M20 11 C19.5 7 16.1 4 12 4 C8.6 4 5.7 6.1 4.6 9 M4 13 C4.5 17 7.9 20 12 20 C15.4 20 18.3 17.9 19.4 15"/><path {STROKE} d="M20 4 V9 H15 M4 20 V15 H9"/>',
    "brain": f'<path {STROKE} d="M9 4 C6.8 4 5 5.6 5 7.6 C3.6 8.3 3 9.6 3 11 C3 12.3 3.6 13.4 4.6 14.1 C4.5 16.6 6.5 19 9 19 C10.4 19 11.4 18.4 12 17.6 V5.6 C11.4 4.6 10.3 4 9 4 Z"/><path {STROKE} d="M15 4 C17.2 4 19 5.6 19 7.6 C20.4 8.3 21 9.6 21 11 C21 12.3 20.4 13.4 19.4 14.1 C19.5 16.6 17.5 19 15 19 C13.6 19 12.6 18.4 12 17.6"/><path {STROKE} d="M12 5.6 C12.6 4.6 13.7 4 15 4"/>',
    "target": f'<circle {STROKE} cx="12" cy="12" r="9"/><circle {STROKE} cx="12" cy="12" r="5"/><circle {FILL} cx="12" cy="12" r="1.8"/>',
    "exam": f'<rect {STROKE} x="5" y="4" width="14" height="17" rx="2"/><path {STROKE} d="M9 4 V2.8 H15 V4"/><path {STROKE} d="M8.5 10 L10 11.5 L12.5 9 M8.5 15.5 L10 17 L12.5 14.5 M14 10.5 H16 M14 16 H16"/>',
    "volume": f'<path {FILL} d="M4 9 H8 L13 5 V19 L8 15 H4 Z"/><path {STROKE} d="M16.5 8.5 C17.5 9.5 18 10.7 18 12 C18 13.3 17.5 14.5 16.5 15.5 M19 6 C20.4 7.6 21.2 9.7 21.2 12 C21.2 14.3 20.4 16.4 19 18"/>',
    "lock": f'<rect {STROKE} x="5" y="11" width="14" height="10" rx="2"/><path {STROKE} d="M8 11 V8 C8 5.8 9.8 4 12 4 C14.2 4 16 5.8 16 8 V11"/>',
    "code": f'<path {STROKE} d="M8 7 L3 12 L8 17 M16 7 L21 12 L16 17 M14 4.5 L10 19.5"/>',
    "home": f'<path {STROKE} d="M3.5 11 L12 4 L20.5 11"/><path {STROKE} d="M6 9.5 V20 H10 V14.5 H14 V20 H18 V9.5"/>',
    "skip": f'<path {FILL} d="M5 5 L14 12 L5 19 Z"/><path {STROKE} stroke-width="2.5" d="M18 5 V19"/>',
}


def main():
    os.makedirs(OUT, exist_ok=True)
    for name, body in ICONS.items():
        svg = (
            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="64" height="64">'
            f"{body}</svg>\n"
        )
        with open(os.path.join(OUT, f"{name}.svg"), "w", encoding="utf-8", newline="\n") as fh:
            fh.write(svg)
    print(f"{len(ICONS)} icons written to {OUT}")


if __name__ == "__main__":
    main()
