"""Crop C1/C2 wash pinky + C3 pinky cells as generation references."""

from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "tool"))
from make_zeynep_nail_sheets import even_cells  # noqa: E402

IMAGES = REPO / "assets" / "images"
OUT = REPO / "tool" / "review_light_nails" / "src"
OUT.mkdir(parents=True, exist_ok=True)


def main() -> None:
    wash = even_cells(Image.open(IMAGES / "hand_wash.png"))
    # Pinky is the leftmost finger (fingers down, thumb on the right).
    last = wash[-1].convert("RGBA")
    first = wash[0].convert("RGBA")
    w, h = last.size
    pinky_box = (int(w * 0.02), int(h * 0.50), int(w * 0.24), int(h * 0.995))
    last.crop(pinky_box).save(OUT / "c12_wash_pinky_clean_skin.png")
    first.crop(pinky_box).save(OUT / "c12_wash_pinky_dirty.png")

    c3 = even_cells(Image.open(IMAGES / "pinky_clean_dark.png"))
    c3[0].save(OUT / "c3_pinky_dirty.png")
    c3[-1].save(OUT / "c3_pinky_clean.png")
    print("wrote", OUT)


if __name__ == "__main__":
    main()
