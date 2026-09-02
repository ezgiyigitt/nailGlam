"""Trace the single nail on a finger close-up cell into a polish mask.

Used for the stiletto clip sheets (`pinky_stiletto_mask_dark.png` and
friends): each is a 4-cell strip like the square short sheets, but several of
the delivered masks stop short of the sharp tip or bleed onto the skin at the
sides, leaving lacquer that visibly doesn't reach the point (see
`_paintPolish` in nail_workspace.dart, which clips strictly to this mask).

Same method as build_toenail_mask.py: luminance splits pale nails from dark
skin; on light skin, green-minus-blue is what splits neutral nail from
orange skin. On these close-ups the nail fades into skin over a genuinely
soft few-pixel gradient (unlike the flatter-lit whole-hand reveal photos,
where red-minus-blue was the better split), so a strict colour cut alone
leaves a visible rim - a small dilation reclaims that rim, and the nail's
convex hull recovers the tip the colour cut underestimates most.

Usage:
    python tool/build_finger_nail_mask.py <sheet.png> <out_mask.png> <light|dark> [frame] [cell_w]
"""

import sys

import numpy as np
from PIL import Image
from scipy import ndimage
from skimage.morphology import convex_hull_image

# The nail itself drifts from G-B ~7 at the cuticle up to ~13 right at a
# stiletto point (still anti-aliasing toward the surrounding tone, not skin) -
# skin proper does not start until the low 20s, so 16 clears the tip with
# margin to spare on both sides.
LIGHT_GB_MAX = 16.0
DARK_LUMA_MIN = 160.0
# Pixels the strict colour cut may grow by to reclaim the soft transition rim.
RIM_GROW_PX = 2


def nail_field(rgb: np.ndarray, tone: str) -> tuple[np.ndarray, float]:
    if tone == "dark":
        return rgb.max(axis=2), DARK_LUMA_MIN
    return -(rgb[:, :, 1] - rgb[:, :, 2]), -LIGHT_GB_MAX


def build(
    sheet_path: str, out_path: str, tone: str, frame: int, cell_w: int
) -> None:
    src = Image.open(sheet_path).convert("RGBA")
    cell = src.crop((frame * cell_w, 0, (frame + 1) * cell_w, src.height))
    data = np.asarray(cell).astype(np.float32)
    rgb, alpha = data[:, :, :3], data[:, :, 3]
    inside = alpha > 200

    score, cut = nail_field(rgb, tone)
    rough = inside & (score > cut)
    rough = ndimage.binary_opening(rough, np.ones((3, 3)))
    rough = ndimage.binary_fill_holes(rough)

    labels, count = ndimage.label(rough)
    if not count:
        raise SystemExit(f"{sheet_path}: no nail found in frame {frame}")
    sizes = ndimage.sum(rough, labels, range(1, count + 1))
    biggest = int(np.argmax(sizes)) + 1
    nail = labels == biggest
    runner_up = int(np.sort(sizes)[::-1][1]) if count > 1 else 0
    print(f"  nail={int(sizes[biggest - 1])}px  next_largest={runner_up}px")

    # Grow a few pixels to reclaim the soft transition rim the strict cut
    # left outside, then cap it to the frame's alpha so it can't leak past
    # the finger's own silhouette.
    nail = ndimage.binary_dilation(nail, np.ones((RIM_GROW_PX * 2 + 1,) * 2))
    nail &= inside

    # A stiletto tip narrows past where the colour cut confidently separates
    # nail from skin; the nail itself is convex, so its hull recovers the
    # point without guessing at colour thresholds down there.
    ys, xs = np.nonzero(nail)
    y0, y1, x0, x1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
    hull = convex_hull_image(nail[y0:y1, x0:x1])
    nail = nail.copy()
    nail[y0:y1, x0:x1] |= hull

    soft = np.clip((score - cut) / (abs(cut) * 0.25 + 6.0), 0, 1)
    mask = np.where(nail, np.maximum(soft, 0.9), 0.0)
    mask = np.clip(ndimage.gaussian_filter(mask, 0.6), 0, 1)
    mask[nail & (mask > 0.8)] = 1.0

    out = np.zeros(data.shape, dtype=np.uint8)
    out[:, :, :3] = 255
    out[:, :, 3] = (mask * 255).astype(np.uint8)
    Image.fromarray(out, "RGBA").save(out_path)

    ys, xs = np.nonzero(mask > 0.03)
    print(
        f"{out_path}: {cell.width}x{cell.height} cover={float((mask > 0.03).mean()):.4f} "
        f"bbox=({xs.min()}, {ys.min()}, {xs.max() + 1}, {ys.max() + 1})"
    )


if __name__ == "__main__":
    if len(sys.argv) < 4:
        raise SystemExit(__doc__)
    build(
        sys.argv[1],
        sys.argv[2],
        sys.argv[3],
        int(sys.argv[4]) if len(sys.argv) > 4 else 3,
        int(sys.argv[5]) if len(sys.argv) > 5 else 384,
    )
