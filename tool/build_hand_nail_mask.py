"""Trace the five fingernails on a finished-hand still into a polish mask.

The reveal paints lacquer by tinting through this mask (`_paintLacquerCoat`),
so it has to follow the nail outline exactly - a mask that is merely close
leaves pale notches at the tips, which is very visible on pointed stiletto
art.

Separators mirror tool/build_toenail_mask.py: luminance splits pale nails from
dark skin, while on light skin the nails are neutral pink against orange skin
and green-minus-blue is what tells them apart. Structure does the rest - a
hand has five nails, so the five largest blobs are the answer.

Usage:
    python tool/build_hand_nail_mask.py <hand.png> <out_mask.png> <light|dark>
"""

import sys

import numpy as np
from PIL import Image
from scipy import ndimage

NAILS_PER_HAND = 5
# Light skin is orange, the nails are near-neutral, so red-minus-blue splits
# them: measured against the dark hand's traced nails the two populations sit
# at nail<=55 and skin>=56, with no overlap. Green-minus-blue overlaps right
# at the boundary and tears bites out of the pink cuticle end.
LIGHT_RB_MAX = 55.0
DARK_LUMA_MIN = 150.0


def nail_field(rgb: np.ndarray, tone: str) -> tuple[np.ndarray, float]:
    if tone == "dark":
        return rgb.max(axis=2), DARK_LUMA_MIN
    return -(rgb[:, :, 0] - rgb[:, :, 2]), -LIGHT_RB_MAX


def build(hand_path: str, out_path: str, tone: str) -> None:
    src = Image.open(hand_path).convert("RGBA")
    data = np.asarray(src).astype(np.float32)
    rgb, alpha = data[:, :, :3], data[:, :, 3]
    inside = alpha > 200

    score, cut = nail_field(rgb, tone)
    rough = inside & (score > cut)
    rough = ndimage.binary_opening(rough, np.ones((3, 3)))
    # Bridge a french tip's smile line without welding neighbouring nails.
    rough = ndimage.binary_closing(rough, np.ones((11, 3)))
    rough = ndimage.binary_fill_holes(rough)

    labels, count = ndimage.label(rough)
    if not count:
        raise SystemExit(f"{hand_path}: no nails found")
    sizes = ndimage.sum(rough, labels, range(1, count + 1))
    chosen = np.argsort(sizes)[::-1][:NAILS_PER_HAND]

    keep = np.zeros_like(rough)
    for index in chosen:
        keep |= labels == (index + 1)
    picked = sorted((int(sizes[i]) for i in chosen), reverse=True)
    runner_up = int(np.sort(sizes)[::-1][NAILS_PER_HAND]) if count > NAILS_PER_HAND else 0
    print(f"  nails={picked} next_largest={runner_up}")
    if runner_up > picked[-1] * 0.6:
        print("  WARNING: rejected blob is close in size to a kept nail")

    soft = np.clip((score - cut) / (abs(cut) * 0.25 + 6.0), 0, 1)
    mask = np.where(keep, np.maximum(soft, 0.9), 0.0)
    mask = np.clip(ndimage.gaussian_filter(mask, 0.6), 0, 1)
    mask[keep & (mask > 0.8)] = 1.0

    out = np.zeros(data.shape, dtype=np.uint8)
    out[:, :, :3] = 255
    out[:, :, 3] = (mask * 255).astype(np.uint8)
    Image.fromarray(out, "RGBA").save(out_path)

    ys, xs = np.nonzero(mask > 0.03)
    print(
        f"{out_path}: {src.width}x{src.height} cover={float((mask > 0.03).mean()):.4f} "
        f"bbox=({xs.min()}, {ys.min()}, {xs.max() + 1}, {ys.max() + 1})"
    )


if __name__ == "__main__":
    if len(sys.argv) < 4:
        raise SystemExit(__doc__)
    build(sys.argv[1], sys.argv[2], sys.argv[3])
