"""Cut the black studio backdrop off delivered art and write back RGBA.

The photographic sheets arrive as opaque RGB on pure black. Drawn straight
onto the manicure plate they stamp a black rectangle, so every sheet needs an
alpha channel derived from the backdrop before it can be used.

Frames are kept independent: strips hold several feet side by side, so this
never reduces to a single "largest" blob. Interior holes are filled, so dark
creases inside skin stay opaque, and the edge keeps the backdrop's own falloff
as antialiasing.

Usage:
    python tool/cutout_black_bg.py assets/images/toe_cutting_dark.png ...
"""

import sys

import numpy as np
from PIL import Image
from scipy import ndimage

# Backdrop is pure black; skin bottoms out around luma 20. Everything at or
# under SOLID_FLOOR is backdrop, everything over SOLID_CEIL is subject, and
# the band between them becomes the antialiased rim.
SOLID_FLOOR = 4.0
SOLID_CEIL = 20.0
CORE_THRESHOLD = 12
MIN_BLOB_PX = 2000


def cutout(path: str) -> None:
    src = Image.open(path).convert("RGB")
    rgb = np.asarray(src).astype(np.float32)
    luma = rgb.max(axis=2)

    core = luma > CORE_THRESHOLD
    core = ndimage.binary_fill_holes(core)

    # Drop specks (dust, compression noise) without merging separate subjects.
    labels, count = ndimage.label(core)
    if count:
        sizes = ndimage.sum(core, labels, range(1, count + 1))
        too_small = np.flatnonzero(sizes < MIN_BLOB_PX) + 1
        if too_small.size:
            core[np.isin(labels, too_small)] = False

    soft = np.clip((luma - SOLID_FLOOR) / (SOLID_CEIL - SOLID_FLOOR), 0, 1)
    alpha = np.where(core, np.maximum(soft, 0.85), np.minimum(soft, 0.15))
    alpha = np.clip(ndimage.gaussian_filter(alpha, 0.6), 0, 1)
    alpha[core & (alpha > 0.75)] = 1.0

    out = np.dstack([rgb, alpha * 255]).astype(np.uint8)
    Image.fromarray(out, "RGBA").save(path)

    ys, xs = np.nonzero(alpha > 0.03)
    print(
        f"{path}: cover={float((alpha > 0.03).mean()):.3f} "
        f"opaque={float((alpha >= 0.999).mean()):.3f} "
        f"bbox=({xs.min()}, {ys.min()}, {xs.max() + 1}, {ys.max() + 1})"
    )


if __name__ == "__main__":
    if len(sys.argv) < 2:
        raise SystemExit(__doc__)
    for arg in sys.argv[1:]:
        cutout(arg)
