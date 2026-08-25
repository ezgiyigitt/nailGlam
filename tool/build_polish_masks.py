"""Polish masks that follow each clipped nail plate, cuticle included.

Mode: fill the full plate (no underfill) without dilating onto skin.
"""

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

    mid = tip - 90
    bright_mid = opaque[mid] & (lum[mid] > 155)
    cols = np.where(bright_mid)[0]
    if cols.size < 12:
        cols = np.where(opaque[tip - 12] & (lum[tip - 12] > 130))[0]
    if cols.size:
        lo = max(0, int(cols[0]) - 6)
        hi = min(w - 1, int(cols[-1]) + 6)
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
        if y < tip - 140:
            continue
        while y > 200:
            if cuticle(y, x):
                break
            keep[y, x] = True
            y -= 1

    # Fill horizontal gaps inside each row of the plate.
    for y in range(h):
        xs = np.where(keep[y])[0]
        if xs.size >= 6 and xs[-1] - xs[0] < 320:
            keep[y, xs[0] : xs[-1] + 1] = True
    return keep


def _mask_from_cell(cell: Image.Image) -> Image.Image:
    """Full plate fill: close tiny holes, soft edge, never expand onto skin."""
    keep = _plate(cell)
    raw = Image.fromarray((keep.astype(np.uint8) * 255), "L")
    # Close 1px holes without growing the silhouette.
    closed = raw.filter(ImageFilter.MaxFilter(3)).filter(ImageFilter.MinFilter(3))
    closed_arr = np.asarray(closed) > 127
    # Soften only inside the closed plate (no outer bloom).
    feather = closed.filter(ImageFilter.GaussianBlur(0.7))
    alpha = np.asarray(feather).astype(np.int16)
    alpha = np.where(closed_arr, np.clip(alpha + 40, 0, 255), 0)
    out = np.zeros((cell.height, cell.width, 4), dtype=np.uint8)
    out[..., :3] = 255
    out[..., 3] = alpha.astype(np.uint8)
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


def _last_even_cell(sheet: Image.Image, frames: int = 4) -> Image.Image:
    w, h = sheet.size
    cell_w = w / frames
    x0 = int(round((frames - 1) * cell_w))
    x1 = w
    return sheet.crop((x0, 0, x1, h))


def _preview(cell: Image.Image, mask: Image.Image, path: Path) -> None:
    h = cell.height
    top = max(0, h // 3)
    bottom = min(h, int(h * 0.72))
    crop = (0, top, cell.width, bottom)
    base = cell.crop(crop).convert("RGBA")
    overlay = Image.new("RGBA", base.size, (255, 50, 110, 170))
    overlay.putalpha(mask.crop(crop).split()[-1].point(lambda v: int(v * 0.7)))
    Image.alpha_composite(base, overlay).save(path)


def main() -> None:
    jobs = (
        ("short_nail.png", "Pink_nail_mask.png", "pinky"),
        ("fourth_short_nail.png", "ring_nail_mask.png", "ring"),
        ("third_nail_short.png", "third_nail_mask.png", "middle"),
        ("second_nail_short.png", "second_nail_mask.png", "index"),
        ("first_nail_short.png", "first_nail_mask.png", "thumb"),
    )
    plates: list[tuple[str, int, int, int, int]] = []
    for sheet_name, mask_name, label in jobs:
        sheet = Image.open(OUT / sheet_name).convert("RGBA")
        cell = _last_even_cell(sheet)
        print(f"\n=== {label} from {sheet_name} cell={cell.size} ===")
        mask = _mask_from_cell(cell)
        # Mask canvas must match the short-frame size used in game.
        if mask.size != cell.size:
            mask = mask.resize(cell.size, Image.Resampling.NEAREST)
        mask.save(OUT / mask_name)
        a = np.asarray(mask)[..., 3]
        ys, xs = np.where(a > 40)
        plates.append(
            (
                label,
                int(xs.min()),
                int(ys.min()),
                int(xs.max() - xs.min() + 1),
                int(ys.max() - ys.min() + 1),
            )
        )
        _preview(cell, mask, REPO / "tool" / f"_preview_{label}_mask.png")

    print("\nDart plate regions:")
    for label, x, y, w, h in plates:
        print(f"  {label}: Vector2({x}, {y}), Vector2({w}, {h})")
    print("wrote all polish masks")


if __name__ == "__main__":
    main()
