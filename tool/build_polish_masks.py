"""Polish masks that follow the clipped nail plate, cuticle included."""

from __future__ import annotations

from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

REPO = Path(__file__).resolve().parent.parent
OUT = REPO / "assets" / "images"


def _plate(cell: Image.Image) -> np.ndarray:
    arr = np.asarray(cell.convert("RGBA"))
    rgb = arr[..., :3].astype(np.float32)
    r, g, bch = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    lum = 0.21 * r + 0.72 * g + 0.07 * bch
    sat = rgb.max(-1) - rgb.min(-1)
    alpha = arr[..., 3]
    h, w = lum.shape
    opaque = alpha > 24
    ys = np.where(opaque.any(1))[0]
    tip = int(ys.max())
    # Columns that belong to the plate: bright run on a mid-nail row.
    mid = tip - 90
    bright_mid = opaque[mid] & (lum[mid] > 155)
    cols = np.where(bright_mid)[0]
    if cols.size < 12:
        cols = np.where(opaque[tip - 12] & (lum[tip - 12] > 130))[0]
    if cols.size:
        lo = max(0, int(cols[0]) - 10)
        hi = min(w - 1, int(cols[-1]) + 10)
        cols = np.arange(lo, hi + 1)
    keep = np.zeros((h, w), dtype=bool)

    def cuticle(y: int, x: int) -> bool:
        if not opaque[y, x]:
            return True
        L, S = lum[y, x], sat[y, x]
        pink = r[y, x] > g[y, x] + 6 and r[y, x] > bch[y, x] + 4
        if L < 88:
            return True
        if S > 82 and L < 148 and pink:
            return True
        if S > 100 and L < 165 and pink:
            return True
        return False

    for x in cols:
        ys_col = np.where(opaque[:, x] & (lum[:, x] > 120))[0]
        if ys_col.size == 0:
            continue
        y = int(ys_col.max())
        if y < tip - 120:
            continue
        while y > 260:
            if cuticle(y, x):
                break
            keep[y, x] = True
            y -= 1

    # Fill 1px holes, then close the plate.
    for y in range(h):
        xs = np.where(keep[y])[0]
        if xs.size >= 8 and xs[-1] - xs[0] < 280:
            keep[y, xs[0] : xs[-1] + 1] = True
    return keep


def _mask_from_cell(cell: Image.Image) -> Image.Image:
    keep = _plate(cell)
    raw = Image.fromarray((keep.astype(np.uint8) * 255), "L")
    closed = (
        raw.filter(ImageFilter.MaxFilter(5))
        .filter(ImageFilter.MaxFilter(3))
        .filter(ImageFilter.MinFilter(3))
    )
    feather = closed.filter(ImageFilter.GaussianBlur(1.35))
    alpha = np.asarray(feather)
    out = np.zeros((cell.height, cell.width, 4), dtype=np.uint8)
    out[..., :3] = 255
    out[..., 3] = np.where(alpha > 14, np.clip(alpha.astype(np.int16) + 55, 0, 255), 0).astype(
        np.uint8
    )
    ys, xs = np.where(out[..., 3] > 40)
    print(
        "mask bbox",
        int(xs.min()),
        int(ys.min()),
        int(xs.max()) + 1,
        int(ys.max()) + 1,
        "size",
        int(xs.max() - xs.min() + 1),
        int(ys.max() - ys.min() + 1),
    )
    return Image.fromarray(out, "RGBA")


def _preview(cell: Image.Image, mask: Image.Image, path: Path) -> None:
    crop = (0, 300, 384, 680)
    base = cell.crop(crop).convert("RGBA")
    overlay = Image.new("RGBA", base.size, (255, 50, 110, 170))
    overlay.putalpha(mask.crop(crop).split()[-1].point(lambda v: int(v * 0.7)))
    Image.alpha_composite(base, overlay).save(path)


def main() -> None:
    short = Image.open(OUT / "short_nail.png").convert("RGBA")
    fourth = Image.open(OUT / "fourth_short_nail.png").convert("RGBA")
    pinky_cell = short.crop((1152, 0, 1536, 1024))
    ring_cell = fourth.crop((1152, 0, 1536, 1024))
    pinky = _mask_from_cell(pinky_cell)
    ring = _mask_from_cell(ring_cell)
    pinky.save(OUT / "Pink_nail_mask.png")
    ring.save(OUT / "ring_nail_mask.png")
    _preview(pinky_cell, pinky, REPO / "tool" / "_preview_pinky_mask.png")
    _preview(ring_cell, ring, REPO / "tool" / "_preview_ring_mask.png")
    print("wrote masks")


if __name__ == "__main__":
    main()
