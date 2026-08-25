"""Install shared light-hand cut + polish for ring / middle / index.

Ring, middle, and index share one close-up sprite on the fair hand.
Copy the approved pinky strip + mask so all three digits use the same art.
"""

from __future__ import annotations

import shutil
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "tool"))
from make_zeynep_nail_sheets import plate_region  # noqa: E402
from PIL import Image

APPROVAL = REPO / "tool" / "review_light_nails" / "approval"
IMG = REPO / "assets" / "images"

PAIRS = (
    ("pinky_short_light_c12.png", "middle_short_light.png"),
    ("pinky_short_light_c12.png", "pinky_short_light.png"),
    ("pinky_nail_mask_light_c12.png", "middle_nail_mask_light.png"),
    ("pinky_nail_mask_light_c12.png", "pinky_nail_mask_light.png"),
    ("pinky_clean_light.png", "middle_clean_light.png"),
)


def main() -> None:
    for src_name, dest_name in PAIRS:
        src = APPROVAL / src_name if (APPROVAL / src_name).exists() else IMG / src_name.replace("_c12", "")
        if not src.exists():
            raise FileNotFoundError(src)
        dest = IMG / dest_name
        shutil.copy2(src, dest)
        print("copied", src.name, "->", dest)

    mask = Image.open(IMG / "middle_nail_mask_light.png")
    plate = plate_region(mask)
    print("middle plate xywh", plate)
    print("done — ring / middle / index share middle_* assets")


if __name__ == "__main__":
    main()
