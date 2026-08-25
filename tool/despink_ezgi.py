"""Neutralize magenta key leftovers in Ezgi sprites.

Near-pure #FF00FF pockets become transparent. Remaining pink rim light in
hair is recast to dark brown. Warm skin and the plum blouse are left alone.
"""

from __future__ import annotations

from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
IMAGES = ROOT / "assets" / "images"

TARGETS = (
    "customer2_walk.png",
    "customer2_turn.png",
    "customer2_sit.png",
    "customer2_emotion.png",
)


def despink(image: Image.Image) -> Image.Image:
    arr = np.asarray(image.convert("RGBA"), dtype=np.int16)
    r = arr[..., 0].astype(np.float32)
    g = arr[..., 1].astype(np.float32)
    b = arr[..., 2].astype(np.float32)
    a = arr[..., 3]
    lum = (r + g + b) / 3.0
    mag = (r + b) / 2.0 - g
    brown_r = np.clip(g * 0.80 + 10, 0, 255)
    brown_g = np.clip(g * 0.62 + 6, 0, 255)
    brown_b = np.clip(g * 0.40 + 4, 0, 255)

    # Studio magenta the border flood-fill missed (hair gaps, fingertips).
    punch = (a > 8) & (
        ((r > 140) & (b > 120) & (g < 95) & (mag > 70))
        | ((mag > 48) & (b > g + 12) & (r > g + 10) & (lum > 70))
    )
    r = np.where(punch, 0, r)
    g = np.where(punch, 0, g)
    b = np.where(punch, 0, b)
    alpha = np.where(punch, 0, a).astype(np.int16)

    # Recolor leftover pink rim in hair. Skin is red-forward, low blue.
    skin = (r > b + 22) & (r > g) & (b < g + 18)
    pink = (alpha > 18) & (mag > 16) & (b + 6 >= g) & (r > g + 8) & ~skin
    blend = np.clip((mag - 10) / 55.0, 0.45, 1.0)
    r = np.where(pink, r * (1.0 - blend) + brown_r * blend, r)
    g = np.where(pink, g * (1.0 - blend) + brown_g * blend, g)
    b = np.where(pink, b * (1.0 - blend) + brown_b * blend, b)

    out = np.stack(
        [r, g, b, alpha.astype(np.float32)],
        axis=-1,
    )
    return Image.fromarray(np.clip(out, 0, 255).astype(np.uint8), "RGBA")


def main() -> None:
    for name in TARGETS:
        path = IMAGES / name
        despink(Image.open(path)).save(path)
        print(f"despinked {name}")


if __name__ == "__main__":
    main()
