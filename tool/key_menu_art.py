"""Cut the magenta field off the menu art and crop it to its sticker.

The logo and the two menu labels are laid out by the widget tree, so unlike the
scene props they need no fixed aspect: trimming to the artwork lets the overlay
size them straight off their own bounds.

Usage:
    python tool/key_menu_art.py <source-dir>
"""

from __future__ import annotations

import sys
from pathlib import Path

from key_generated_art import OUT_DIR, process

MENU_ART = (
    "nail_glam_logo.png",
    "btn_start.png",
    "btn_how_to_play.png",
)

# The bubble letters are shaded with dusty pinks and ringed with a deep magenta
# contour, both close enough to the backdrop that the tolerances the scene props
# use eat into the type. The only gaps still worth cutting are the letter
# counters, and those sit on the exact backdrop colour.
POCKET_TOLERANCE = 40
POCKET_MIN_SPAN = 7


def main() -> int:
    if len(sys.argv) != 2:
        print(__doc__)
        return 2

    source_dir = Path(sys.argv[1])
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for name in MENU_ART:
        process(
            source_dir / name,
            name,
            crop=True,
            pocket_tolerance=POCKET_TOLERANCE,
            pocket_min_span=POCKET_MIN_SPAN,
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
