"""Cut the approved clean pinky left→right like C3, then mask the SHORT plate.

Long ghost outline is punched away. Polish preview sits on frame 4 only.
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "tool"))
from make_zeynep_nail_sheets import (  # noqa: E402
    FINAL_KEEP,
    even_cells,
    pack_strip,
    polish_mask_from_nail,
    _fill_interior_gaps,
    _luma,
)

IMAGES = REPO / "assets" / "images"
OUT = REPO / "tool" / "review_light_nails" / "approval"
PINK = (255, 182, 193)


def _preview(image: Image.Image, dest: Path) -> None:
    canvas = Image.new("RGBA", image.size, (*PINK, 255))
    canvas.alpha_composite(image.convert("RGBA"))
    dest.parent.mkdir(parents=True, exist_ok=True)
    canvas.convert("RGB").save(dest, quality=92)


def _plate(cell: Image.Image) -> np.ndarray:
    arr = np.asarray(cell.convert("RGBA"))
    alpha = arr[..., 3] > 10
    lum = _luma(arr[..., :3].astype(np.float32))
    rgb = arr[..., :3].astype(np.float32)
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    ys = np.flatnonzero(alpha.any(axis=1))
    y0, y1 = int(ys[0]), int(ys[-1])
    span = max(1, y1 - y0)
    distal = np.zeros(alpha.shape, dtype=bool)
    distal[y0 + int(span * 0.38) : y1 + 1] = True
    proximal = alpha & ~distal
    skin = float(np.median(lum[proximal])) if proximal.any() else 150.0
    enamel = alpha & distal & (lum >= max(skin + 8, 165.0))
    enamel |= alpha & distal & (lum >= 175) & ((r + g) / 2.0 > b + 6)
    if enamel.sum() < 800:
        enamel = alpha & distal & (lum >= skin + 2)
    h, w = enamel.shape
    rows = np.flatnonzero(enamel.any(axis=1))
    tip_y = seed_x = None
    for ty in reversed(rows):
        xs = np.flatnonzero(enamel[int(ty)])
        if xs.size >= 4:
            tip_y, seed_x = int(ty), int(xs[len(xs) // 2])
            break
    if tip_y is None:
        return np.zeros(alpha.shape, dtype=bool)
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
    closed = (
        Image.fromarray(keep.astype(np.uint8) * 255, "L")
        .filter(ImageFilter.MaxFilter(5))
        .filter(ImageFilter.MinFilter(3))
    )
    plate = (np.asarray(closed) > 127) & alpha & distal
    for y in range(h):
        xs = np.flatnonzero(plate[y])
        if xs.size >= 3:
            plate[y, int(xs[0]) : int(xs[-1]) + 1] = True
    pys = np.flatnonzero(plate.any(axis=1))
    if pys.size:
        tip = int(pys[-1])
        plate[: max(0, tip - max(260, int(span * 0.50))), :] = False
    return plate & alpha


def _cut_line(plate: np.ndarray, stage: int) -> tuple[np.ndarray, int]:
    ys, xs = np.where(plate)
    base_y, tip_y = int(ys.min()), int(ys.max())
    left, right = int(xs.min()), int(xs.max())
    final_y = int(round(base_y + (tip_y - base_y) * FINAL_KEEP))
    height, width = plate.shape
    yy, xx = np.indices((height, width))
    t = np.clip((xx - left) / max(1, right - left), 0.0, 1.0)
    extra = float(tip_y - final_y)
    if stage <= 0:
        line = np.full((height, width), float(tip_y + 4), dtype=np.float32)
    elif stage == 1:
        line = final_y + 0.10 * extra + t * 0.90 * extra
    elif stage == 2:
        line = final_y + t * 0.42 * extra
    else:
        line = np.full((height, width), float(final_y), dtype=np.float32)
    return line, final_y


def _defringe(cell: Image.Image) -> Image.Image:
    """Drop the black keyed halo; remaining rim tints toward interior peach."""
    arr = np.asarray(cell.convert("RGBA")).copy()
    lum = _luma(arr[..., :3].astype(np.float32))
    opaque = arr[..., 3] > 12
    if not opaque.any():
        return cell
    interior = (
        np.asarray(
            Image.fromarray(opaque.astype(np.uint8) * 255, "L").filter(
                ImageFilter.MinFilter(9)
            )
        )
        > 127
    )
    if not interior.any():
        interior = (
            np.asarray(
                Image.fromarray(opaque.astype(np.uint8) * 255, "L").filter(
                    ImageFilter.MinFilter(5)
                )
            )
            > 127
        )
    if not interior.any():
        return cell
    skin = np.median(arr[interior, :3].astype(np.float32), axis=0)
    skin_lum = float(0.2126 * skin[0] + 0.7152 * skin[1] + 0.0722 * skin[2])

    def _ring(px: int) -> np.ndarray:
        inner = (
            np.asarray(
                Image.fromarray(opaque.astype(np.uint8) * 255, "L").filter(
                    ImageFilter.MinFilter(px)
                )
            )
            > 127
        )
        return opaque & ~inner

    # Eat the near-black halo first so it cannot read as a nail outline.
    for px in (7, 5, 3):
        opaque = arr[..., 3] > 12
        lum = _luma(arr[..., :3].astype(np.float32))
        dark = _ring(px) & (lum < max(70.0, skin_lum * 0.48))
        arr[dark] = 0

    opaque = arr[..., 3] > 12
    lum = _luma(arr[..., :3].astype(np.float32))
    rim = _ring(5)
    # Pull leftover shade toward peach so the silhouette is skin, not charcoal.
    pull = np.clip((skin_lum * 0.92 - lum) / max(18.0, skin_lum * 0.45), 0.0, 1.0)
    w = (pull * 0.82 * rim.astype(np.float32))[..., None]
    rgb = arr[..., :3].astype(np.float32)
    rgb = rgb * (1.0 - w) + skin.reshape(1, 1, 3) * w
    arr[..., :3] = np.clip(rgb, 0, 255)
    outer = _ring(3)
    arr[outer, 3] = np.minimum(arr[outer, 3], 200)
    return Image.fromarray(arr, "RGBA")


def _clip(cell: Image.Image, plate: np.ndarray, long_alpha: np.ndarray, stage: int) -> Image.Image:
    arr = np.asarray(cell.convert("RGBA")).copy()
    if stage <= 0:
        return Image.fromarray(arr, "RGBA")
    line, final_y = _cut_line(plate, stage)
    height, width = arr.shape[:2]
    yy, xx = np.indices((height, width))
    nxs = np.where(plate)[1]
    left, right = int(nxs.min()) - 32, int(nxs.max()) + 32
    # Original long-tip occupancy, dilated, so the stiletto outline cannot survive.
    tip = long_alpha & (xx >= left) & (xx <= right) & (yy > line)
    tip = (
        np.asarray(
            Image.fromarray(tip.astype(np.uint8) * 255, "L").filter(
                ImageFilter.MaxFilter(13)
            )
        )
        > 40
    ) & (yy > line) & (xx >= left) & (xx <= right)
    arr[tip] = 0
    # Any leftover dark speck below the bite, even with weak alpha.
    lum = _luma(arr[..., :3].astype(np.float32))
    leftover = (yy > line) & (xx >= left) & (xx <= right) & (
        (arr[..., 3] > 4) | ((arr[..., 3] > 0) & (lum < 90))
    )
    arr[leftover] = 0

    if stage == 3:
        nys, nxs = np.where(plate)
        left_p, right_p = int(nxs.min()), int(nxs.max())
        for x in range(left_p, right_p + 1):
            col = plate[:, x] & (np.arange(height) <= final_y)
            hits = np.flatnonzero(col)
            if hits.size == 0:
                continue
            sample_y = int(hits[max(0, len(hits) - 8)])
            if arr[sample_y, x, 3] < 16:
                continue
            color = arr[sample_y, x]
            for y in range(max(0, final_y - 2), final_y + 1):
                if plate[y, x] and arr[y, x, 3] > 8:
                    arr[y, x] = color
            arr[final_y + 1 :, x] = 0
    return Image.fromarray(arr, "RGBA")


def _short_plate(short_cell: Image.Image, long_plate: np.ndarray, final_y: int) -> np.ndarray:
    """Remaining enamel after the bite — fill the short nail 1:1, not a inset."""
    arr = np.asarray(short_cell.convert("RGBA"))
    alpha = arr[..., 3] > 10
    yy = np.arange(arr.shape[0])[:, None]
    keep = long_plate & alpha & (yy <= final_y)
    keep = _fill_interior_gaps(keep, max_gap=20)
    for y in range(keep.shape[0]):
        xs = np.flatnonzero(keep[y])
        if xs.size >= 2:
            keep[y, int(xs[0]) : int(xs[-1]) + 1] = True
    grown = (
        np.asarray(
            Image.fromarray(keep.astype(np.uint8) * 255, "L").filter(
                ImageFilter.MaxFilter(5)
            )
        )
        > 40
    )
    keep = grown & alpha & (yy <= final_y)
    return keep


def main() -> None:
    long_cell = _defringe(even_cells(Image.open(IMAGES / "pinky_clean_light.png"))[-1])
    plate = _plate(long_cell)
    if int(plate.sum()) < 2500:
        raise RuntimeError(f"plate too small {int(plate.sum())}")
    long_alpha = np.asarray(long_cell.convert("RGBA"))[..., 3] > 8
    _, final_y = _cut_line(plate, 3)

    frames = [_defringe(_clip(long_cell, plate, long_alpha, stage)) for stage in range(4)]
    short_plate = _short_plate(frames[-1], plate, final_y)
    mask = polish_mask_from_nail(short_plate, frames[-1])

    OUT.mkdir(parents=True, exist_ok=True)
    pack_strip(frames, OUT / "pinky_short_light_c12.png")
    mask.save(OUT / "pinky_nail_mask_light_c12.png")
    _preview(Image.open(OUT / "pinky_short_light_c12.png"), OUT / "pinky_short_light_c12_preview.jpg")

    overlay = Image.new("RGBA", frames[-1].size, (255, 70, 140, 0))
    overlay.putalpha(mask.split()[-1].point(lambda v: int(v * 0.92)))
    _preview(Image.alpha_composite(frames[-1], overlay), OUT / "pinky_polish_light_c12_preview.jpg")
    _preview(mask, OUT / "pinky_nail_mask_light_c12_preview.jpg")
    _preview(frames[-1], OUT / "pinky_short_light_c12_f3.jpg")

    dbg = np.asarray(frames[-1].convert("RGBA")).copy()
    ov = np.zeros_like(dbg)
    ov[short_plate] = (0, 220, 80, 160)
    _preview(
        Image.alpha_composite(Image.fromarray(dbg), Image.fromarray(ov)),
        OUT / "pinky_c12_short_plate_debug.jpg",
    )

    ys, xs = np.where(short_plate)
    print("long", int(plate.sum()), "short", int(short_plate.sum()))
    print("short xywh", int(xs.min()), int(ys.min()), int(xs.max() - xs.min() + 1), int(ys.max() - ys.min() + 1))
    print("final_y", final_y)
    print("wrote", OUT / "pinky_short_light_c12.png")


if __name__ == "__main__":
    main()
