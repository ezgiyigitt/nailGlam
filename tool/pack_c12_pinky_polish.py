"""One-shot polish mask for the approved C12 pinky short nail (f3).

Fits the glossy nail plate 1:1 — cuticle arc, both side folds, straight free edge.
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "tool"))
from make_zeynep_nail_sheets import (  # noqa: E402
    even_cells,
    polish_mask_from_nail,
    _fill_interior_gaps,
    _luma,
)
from pack_c12_pinky_cut import _cut_line, _defringe, _plate  # noqa: E402

OUT = REPO / "tool" / "review_light_nails" / "approval"
PINK = (255, 182, 193)
CUT_STRIP = OUT / "pinky_short_light_c12.png"
CLEAN = REPO / "assets" / "images" / "pinky_clean_light.png"

POLISH = (
    ("blush", (255, 107, 168)),
    ("red", (208, 18, 58)),
    ("nude", (230, 184, 162)),
    ("pearl", (244, 228, 236)),
    ("gold", (212, 160, 23)),
)


def _preview(image: Image.Image, dest: Path) -> None:
    canvas = Image.new("RGBA", image.size, (*PINK, 255))
    canvas.alpha_composite(image.convert("RGBA"))
    dest.parent.mkdir(parents=True, exist_ok=True)
    canvas.convert("RGB").save(dest, quality=92)


def _zoom_box(cell: Image.Image) -> tuple[int, int, int, int]:
    arr = np.asarray(cell.convert("RGBA"))
    ys, xs = np.where(arr[..., 3] > 8)
    return (
        max(0, int(xs.min()) - 16),
        max(0, int(ys.min() + 0.38 * (ys.max() - ys.min()))),
        min(arr.shape[1], int(xs.max()) + 16),
        min(arr.shape[0], int(ys.max()) + 8),
    )


def _nail_candidates(arr: np.ndarray, final_y: int) -> np.ndarray:
    """Light-skin nail plate: pale / low-warm enamel, not peach side skin."""
    rgb = arr[..., :3].astype(np.float32)
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    lum = _luma(rgb)
    chroma = np.maximum(np.maximum(r, g), b) - np.minimum(np.minimum(r, g), b)
    warm = g - b
    alpha = arr[..., 3] > 10
    h = arr.shape[0]
    yy = np.arange(h)[:, None]

    # Nail enamel vs knuckle skin: nail is cooler (low warm) and brighter.
    enamel = (
        alpha
        & (yy <= final_y)
        & (lum >= 158)
        & (warm <= 24)
        & (chroma <= 95)
    )
    # Specular core (near-white highlight) always counts.
    enamel |= alpha & (yy <= final_y) & (lum >= 220) & (chroma <= 55)
    # Soft sidewall of the plate (still on nail, before the dark fold).
    enamel |= (
        alpha
        & (yy <= final_y)
        & (lum >= 150)
        & (warm <= 28)
        & (chroma <= 85)
    )
    return enamel


def _flood_from_tip(enamel: np.ndarray) -> np.ndarray:
    h, w = enamel.shape
    rows = np.flatnonzero(enamel.any(axis=1))
    if rows.size == 0:
        return np.zeros_like(enamel)
    tip_y = seed_x = None
    for ty in reversed(rows):
        xs = np.flatnonzero(enamel[int(ty)])
        if xs.size >= 4:
            tip_y, seed_x = int(ty), int(xs[len(xs) // 2])
            break
    if tip_y is None:
        return np.zeros_like(enamel)
    keep = np.zeros((h, w), dtype=bool)
    seen = np.zeros((h, w), dtype=bool)
    stack = [(seed_x, tip_y)]
    while stack:
        x, y = stack.pop()
        if x < 0 or y < 0 or x >= w or y >= h or seen[y, x]:
            continue
        seen[y, x] = True
        if not enamel[y, x]:
            continue
        keep[y, x] = True
        stack.extend(((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)))
    return keep


def _seal_rows(plate: np.ndarray, finger: np.ndarray, final_y: int) -> np.ndarray:
    out = plate.copy()
    for y in range(min(out.shape[0], final_y + 1)):
        xs = np.flatnonzero(out[y])
        if xs.size >= 2:
            out[y, int(xs[0]) : int(xs[-1]) + 1] = True
            out[y] &= finger[y]
        else:
            out[y] = False
    out[final_y + 1 :] = False
    return out


def _nudge_into_folds(
    plate: np.ndarray,
    arr: np.ndarray,
    final_y: int,
    *,
    px: int = 12,
) -> np.ndarray:
    """Grow through the dark lateral sulcus into the outer nail wall.

    Anatomy per row: plate → dark fold → brief bright wall → side skin.
    Polish must cover through the wall, not stop at the fold.
    """
    finger = arr[..., 3] > 10
    rgb = arr[..., :3].astype(np.float32)
    lum = _luma(rgb)
    warm = rgb[..., 1] - rgb[..., 2]
    h, w = plate.shape
    out = plate.copy()
    for y in range(min(h, final_y + 1)):
        xs = np.flatnonzero(out[y])
        if xs.size < 3:
            continue

        def _grow(start: int, step: int) -> None:
            nonlocal out
            x = start
            seen_fold = False
            for _ in range(px):
                nxt = x + step
                if nxt < 0 or nxt >= w or not finger[y, nxt]:
                    break
                L = float(lum[y, nxt])
                W = float(warm[y, nxt])
                if L < 135:
                    seen_fold = True
                if seen_fold and W > 29 and L < 158:
                    break
                if W > 32 and L < 152:
                    break
                if L < 112:
                    break
                x = nxt
                out[y, x] = True

        _grow(int(xs[-1]), +1)
        _grow(int(xs[0]), -1)
    return _seal_rows(out, finger, final_y)


def short_nail_plate(cell: Image.Image, final_y: int) -> np.ndarray:
    arr = np.asarray(cell.convert("RGBA"))
    finger = arr[..., 3] > 10
    enamel = _nail_candidates(arr, final_y)
    plate = _flood_from_tip(enamel)
    if int(plate.sum()) < 2000:
        raise RuntimeError(f"nail plate too small: {int(plate.sum())}")

    closed = (
        Image.fromarray(plate.astype(np.uint8) * 255, "L")
        .filter(ImageFilter.MaxFilter(5))
        .filter(ImageFilter.MinFilter(3))
    )
    plate = (np.asarray(closed) > 127) & finger
    plate = _fill_interior_gaps(plate, max_gap=20)
    plate = _seal_rows(plate, finger, final_y)
    plate = _nudge_into_folds(plate, arr, final_y, px=5)
    # Drop anything above the cuticle (proximal skin that leaked in).
    ys = np.flatnonzero(plate.any(axis=1))
    if ys.size:
        # Cuticle is the first solid run of plate rows; trim isolated crumbs above.
        run_start = int(ys[0])
        for i in range(1, len(ys)):
            if int(ys[i]) - int(ys[i - 1]) > 8:
                run_start = int(ys[i])
        plate[: max(0, run_start - 1)] = False
    return plate & finger


def _apply_polish(base: Image.Image, mask: Image.Image, rgb: tuple[int, int, int]) -> Image.Image:
    overlay = Image.new("RGBA", base.size, (*rgb, 0))
    overlay.putalpha(mask.split()[-1].point(lambda v: int(v * 0.92)))
    return Image.alpha_composite(base.convert("RGBA"), overlay)


def main() -> None:
    if not CUT_STRIP.exists():
        raise FileNotFoundError(CUT_STRIP)

    f3 = even_cells(Image.open(CUT_STRIP))[3]
    long_cell = _defringe(even_cells(Image.open(CLEAN))[-1])
    _, final_y = _cut_line(_plate(long_cell), 3)

    plate = short_nail_plate(f3, final_y)
    mask = polish_mask_from_nail(plate, f3)

    # Keep solid core fully opaque — no soft underfill that reads as a gap.
    ma = np.asarray(mask.convert("RGBA")).copy()
    solid = plate.copy()
    feather = Image.fromarray(solid.astype(np.uint8) * 255, "L").filter(
        ImageFilter.GaussianBlur(0.4)
    )
    soft = np.asarray(feather).astype(np.int16)
    ma[..., :3] = 255
    ma[..., 3] = np.where(solid, 255, np.where(soft > 24, soft, 0)).astype(np.uint8)
    mask = Image.fromarray(ma, "RGBA")

    OUT.mkdir(parents=True, exist_ok=True)
    mask.save(OUT / "pinky_nail_mask_light_c12.png")

    _preview(mask, OUT / "pinky_nail_mask_light_c12_preview.jpg")
    _preview(_apply_polish(f3, mask, POLISH[0][1]), OUT / "pinky_polish_light_c12_preview.jpg")

    box = _zoom_box(f3)
    zw, zh = (box[2] - box[0]) * 2, (box[3] - box[1]) * 2
    zoom_f3 = f3.crop(box).resize((zw, zh), Image.NEAREST)
    zoom_mask = mask.crop(box).resize((zw, zh), Image.NEAREST)
    _preview(_apply_polish(zoom_f3, zoom_mask, POLISH[0][1]), OUT / "pinky_cut_zoom_f3_polish.jpg")

    row = Image.new("RGBA", (zw * len(POLISH), zh), (*PINK, 255))
    for i, (_n, rgb) in enumerate(POLISH):
        row.alpha_composite(_apply_polish(zoom_f3, zoom_mask, rgb), (i * zw, 0))
    row.convert("RGB").save(OUT / "pinky_polish_swatches_c12.jpg", quality=92)

    # Green = exact plate on the nail (approval check).
    dbg = np.asarray(f3.convert("RGBA")).copy()
    ov = np.zeros_like(dbg)
    ov[plate] = (0, 220, 80, 160)
    _preview(
        Image.alpha_composite(Image.fromarray(dbg), Image.fromarray(ov)),
        OUT / "pinky_c12_short_plate_debug.jpg",
    )
    tip = f3.crop(box)
    tip_ov = Image.fromarray(ov).crop(box)
    _preview(
        Image.alpha_composite(tip, tip_ov).resize((zw, zh), Image.NEAREST),
        OUT / "pinky_plate_on_nail_zoom.jpg",
    )

    ys, xs = np.where(plate)
    print(
        "plate xywh",
        int(xs.min()),
        int(ys.min()),
        int(xs.max() - xs.min() + 1),
        int(ys.max() - ys.min() + 1),
        "px",
        int(plate.sum()),
    )
    print("final_y", final_y)
    print("wrote", OUT / "pinky_nail_mask_light_c12.png")


if __name__ == "__main__":
    main()
