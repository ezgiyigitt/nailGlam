"""Key the cyan-backed logo and pillows, then copy the peach menu wallpaper."""

from __future__ import annotations

import shutil
import sys
from pathlib import Path

from PIL import Image

from key_generated_art import OUT_DIR, process

SOURCE_DIR = Path(
    r"C:\Users\Ezgi\.cursor\projects\c-Users-Ezgi-Documents-GitHub-nailGlam\assets"
)


def main() -> int:
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    process(SOURCE_DIR / "nail_glam_logo.png", "nail_glam_logo.png", crop=True)
    process(SOURCE_DIR / "manicure_pillow.png", "manicure_pillow.png", crop=True)
    process(
        SOURCE_DIR / "manicure_pillow_top.png",
        "manicure_pillow_top.png",
        crop=True,
    )

    wallpaper = SOURCE_DIR / "background.png"
    wood = SOURCE_DIR / "table_wood.png"
    for source, name in ((wallpaper, "background.png"), (wood, "table_surface.png")):
        if not source.exists():
            print(f"missing {source}", file=sys.stderr)
            return 1
        dest = OUT_DIR / name
        shutil.copy2(source, dest)
        with Image.open(dest) as image:
            print(f"{name}: {image.size[0]}x{image.size[1]}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
