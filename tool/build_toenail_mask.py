"""Trace the toenails on a foot strip into a polish mask.

The nail-care renderer paints lacquer by tinting a rect and clipping it to a
mask (see `_paintLacquerCoat`), so a pedicure needs a mask registered to the
foot art exactly the way `final_hand_*_nail_mask.png` is registered to the
hands. The mask shares the art's full canvas and is cropped with the same
source rect, so every cell gets its own nails traced.

Two skin tones need two different separators:

* dark - the pale nails are far brighter than the skin, so luminance splits
  them cleanly.
* light - the skin is already bright, but it is *orange* while the nails are
  a neutral pink. Green-minus-blue separates them where luminance cannot;
  measured on this art the nails top out at 6 and the skin starts at 9.

Note the hand tool reaches for red-minus-blue instead. The feet and hands are
lit differently, and each separator was picked by measuring the two
populations on its own art - do not assume one transfers to the other.

Both then lean on structure: each cell holds exactly five toes, so the five
largest blobs in a cell are the nails and everything else is noise.

Usage:
    python tool/build_toenail_mask.py <strip.png> <out_mask.png> <light|dark> [cells]
"""

import sys

import numpy as np
from PIL import Image
from scipy import ndimage
from skimage.morphology import convex_hull_image

TOES_PER_FOOT = 5

# light: green-minus-blue below this is neutral-pink nail, not orange skin.
LIGHT_GB_MAX = 8.0
# Looser light cut that also catches a pale french-tip free edge. Too loose to
# select nails by directly - the shadowed crease between two toe bases reads
# the same as a free edge, so an omnidirectional grow (tried first: watershed
# from the confirmed nails) climbed straight up that crease into a tall spike.
# Restricting growth to straight-down-only (see _extend_downward) avoids the
# crease entirely, since it always sits above the nail, never below it.
LIGHT_GB_LOOSE = 16.0
# dark: pale nails sit far above the brown skin's luminance.
DARK_LUMA_MIN = 150.0
DARK_LUMA_LOOSE = 120.0
# Pixels a nail may reach straight down into the loose cut to pick up a
# french tip's free edge. Generous, but the direction restriction is what
# actually keeps this safe, not the distance.
DOWNWARD_GROW_PX = 30
# Toes occupy the bottom of the frame. Measured nail centroids land at
# 0.85-0.96 of the height on both feet, so 0.75 clears them with room while
# still cutting the ankle highlights that sit around 0.66.
TOE_BAND_TOP = 0.75
# Nails are stubby (roughly square); shin highlights are long streaks.
MAX_TOENAIL_ASPECT = 2.2



def nail_field(rgb: np.ndarray, tone: str) -> tuple[np.ndarray, float, float]:
    """Return a score image where nails are high, plus (strict, loose) cuts."""
    if tone == "dark":
        return rgb.max(axis=2), DARK_LUMA_MIN, DARK_LUMA_LOOSE
    # Invert so "more neutral than skin" reads as a high score.
    return (
        -(rgb[:, :, 1] - rgb[:, :, 2]),
        -LIGHT_GB_MAX,
        -LIGHT_GB_LOOSE,
    )


def _extend_downward(nail: np.ndarray, loose_region: np.ndarray) -> np.ndarray:
    """Grow [nail] straight down, never sideways or up, into [loose_region].

    A french tip's white edge fails the strict colour cut, truncating the
    nail before its real end - visible as an unpolished notch at the tip. The
    loose cut catches that edge but also the shadowed crease between two toe
    bases, which sits *above* every nail, never below - so a footprint that
    can only extend downward picks up the free edge and structurally cannot
    reach the crease, no matter how loose the colour cut is.
    """
    size = DOWNWARD_GROW_PX
    footprint = np.zeros((2 * size + 1, 1), dtype=bool)
    footprint[size:, 0] = True
    grown = ndimage.binary_dilation(nail, structure=footprint)
    return grown & loose_region


def _close_tip(blob: np.ndarray) -> np.ndarray:
    """Fill the notch a french tip leaves in an otherwise convex nail.

    The pale free edge reads as skin to the colour cut, biting a concave step
    out of the bottom of the nail. Growing back into a looser colour cut is not
    safe - the skin right at the nail border falls under it too, so the mask
    creeps onto the toe - but a toenail is convex, so its own convex hull
    recovers the tip without consulting colour at all.
    """
    ys, xs = np.nonzero(blob)
    if ys.size == 0:
        return blob
    y0, y1, x0, x1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
    hull = convex_hull_image(blob[y0:y1, x0:x1])
    out = blob.copy()
    out[y0:y1, x0:x1] |= hull
    return out


def _is_toenail(blob: np.ndarray, height: int) -> bool:
    """Reject the specular streaks that run up the shin and ankle.

    Both separators also fire on skin highlights, and on the dark foot those
    streaks are large enough to crowd real nails out of the top five. Toes sit
    at the bottom of the frame and are roughly as wide as they are tall, which
    is enough to tell them apart.
    """
    ys, xs = np.nonzero(blob)
    if ys.size == 0:
        return False
    if ys.mean() < height * TOE_BAND_TOP:
        return False
    span_y = ys.max() - ys.min() + 1
    span_x = xs.max() - xs.min() + 1
    return span_y <= span_x * MAX_TOENAIL_ASPECT


def build(strip_path: str, out_path: str, tone: str, cells: int) -> None:
    src = Image.open(strip_path).convert("RGBA")
    data = np.asarray(src).astype(np.float32)
    rgb, alpha = data[:, :, :3], data[:, :, 3]
    inside = alpha > 200

    score, cut, loose_cut = nail_field(rgb, tone)
    rough = inside & (score > cut)
    rough = ndimage.binary_opening(rough, np.ones((3, 3)))
    # A french tip's smile line cuts the nail into bed + white edge. Bridge it
    # vertically only: a square structure this tall would weld toes together.
    rough = ndimage.binary_closing(rough, np.ones((11, 3)))
    rough = ndimage.binary_fill_holes(rough)
    loose = inside & (score > loose_cut)

    keep = np.zeros_like(rough)
    width = src.width / cells
    for cell in range(cells):
        x0, x1 = int(round(cell * width)), int(round((cell + 1) * width))
        window = np.zeros_like(rough)
        window[:, x0:x1] = rough[:, x0:x1]
        labels, count = ndimage.label(window)
        if not count:
            print(f"  cell {cell}: no nails found")
            continue
        sizes = ndimage.sum(window, labels, range(1, count + 1))
        candidates = [
            index
            for index in range(count)
            if _is_toenail(labels == (index + 1), src.height)
        ]
        candidates.sort(key=lambda index: sizes[index], reverse=True)
        chosen = candidates[:TOES_PER_FOOT]

        cell_loose = np.zeros_like(loose)
        cell_loose[:, x0:x1] = loose[:, x0:x1]
        for index in chosen:
            nail = labels == (index + 1)
            nail = _extend_downward(nail, cell_loose | nail)
            keep |= _close_tip(nail)

        picked = sorted((int(sizes[i]) for i in chosen), reverse=True)
        print(f"  cell {cell}: {picked}")
        if len(chosen) < TOES_PER_FOOT:
            print(f"  cell {cell}: WARNING only {len(chosen)} nails")

    # Feather the rim so lacquer meets skin without a cut-out sticker edge.
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
        f"opaque={float((mask >= 0.999).mean()):.4f} "
        f"bbox=({xs.min()}, {ys.min()}, {xs.max() + 1}, {ys.max() + 1})"
    )


if __name__ == "__main__":
    if len(sys.argv) < 4:
        raise SystemExit(__doc__)
    build(
        sys.argv[1],
        sys.argv[2],
        sys.argv[3],
        int(sys.argv[4]) if len(sys.argv) > 4 else 6,
    )
