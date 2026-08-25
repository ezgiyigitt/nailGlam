"""Build C1/C2 pinky sheets from the locked clean still.

Dirty→clean uses stain warped from the dirty still (finger never moves).
Cut is left→right bite on the same pose. Polish mask matches the short plate.
Writes approval files only.
"""

from __future__ import annotations

import shutil
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "tool"))
from make_zeynep_nail_sheets import (  # noqa: E402
    PINKY_CELL,
    clip_left_to_right,
    clipped_nail_mask,
    even_cells,
    fit_finger_cell,
    nail_mask as nail_mask_dark,
    pack_strip,
    polish_mask_from_nail,
    stain_nail,
    _luma,
)
import make_zeynep_nail_sheets as zsheets  # noqa: E402


def _pinky_plate(cell: Image.Image) -> np.ndarray:
    """Glossy stiletto plate on fair skin, cuticle to tip. Shaft stays out."""
    arr = np.asarray(cell.convert("RGBA"))
    alpha = arr[..., 3] > 8
    if not alpha.any():
        return np.zeros(arr.shape[:2], dtype=bool)
    lum = _luma(arr[..., :3].astype(np.float32))
    ys = np.flatnonzero(alpha.any(axis=1))
    y0, y1 = int(ys[0]), int(ys[-1])
    span = max(1, y1 - y0)
    distal = np.zeros(alpha.shape, dtype=bool)
    distal[y0 + int(span * 0.38) : y1 + 1] = True
    proximal = alpha & ~distal
    skin = float(np.median(lum[proximal])) if proximal.any() else 160.0
    bright = alpha & distal & (lum >= max(skin + 8, 168.0))
    if bright.sum() < 800:
        bright = alpha & distal & (lum >= skin + 4) & (lum >= 155)
    if not bright.any():
        return np.zeros(alpha.shape, dtype=bool)
    height, width = bright.shape
    rows = np.flatnonzero(bright.any(axis=1))
    tip_y = seed_x = None
    for ty in reversed(rows):
        xs = np.flatnonzero(bright[int(ty)])
        if xs.size >= 6:
            tip_y = int(ty)
            seed_x = int(xs[len(xs) // 2])
            break
    if tip_y is None:
        return np.zeros(alpha.shape, dtype=bool)
    keep = np.zeros((height, width), dtype=bool)
    seen = np.zeros((height, width), dtype=bool)
    stack = [(seed_x, tip_y)]
    while stack:
        x, y = stack.pop()
        if x < 0 or y < 0 or x >= width or y >= height or seen[y, x]:
            continue
        seen[y, x] = True
        if not bright[y, x]:
            continue
        keep[y, x] = True
        stack.extend(((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)))
    raw = Image.fromarray(keep.astype(np.uint8) * 255, "L")
    closed = raw.filter(ImageFilter.MaxFilter(3)).filter(ImageFilter.MinFilter(3))
    plate = (np.asarray(closed) > 127) & alpha & distal
    pys = np.flatnonzero(plate.any(axis=1))
    if pys.size:
        tip = int(pys[-1])
        max_h = max(220, int(span * 0.46))
        plate[: max(0, tip - max_h), :] = False
    return plate

CURSOR_ASSETS = Path(
    r"C:\Users\Ezgi\.cursor\projects\c-Users-Ezgi-Documents-GitHub-nailGlam\assets"
)
IMAGES = REPO / "assets" / "images"
SRC = REPO / "tool" / "review_light_nails" / "src"
OUT = REPO / "tool" / "review_light_nails" / "approval"
PINK = (255, 182, 193)
DIRT_LEVELS = (1.0, 0.62, 0.28, 0.0)


def _luma(rgb: np.ndarray) -> np.ndarray:
    return 0.2126 * rgb[..., 0] + 0.7152 * rgb[..., 1] + 0.0722 * rgb[..., 2]


def _preview(image: Image.Image, dest: Path) -> None:
    canvas = Image.new("RGBA", image.size, (*PINK, 255))
    canvas.alpha_composite(image.convert("RGBA"))
    dest.parent.mkdir(parents=True, exist_ok=True)
    canvas.convert("RGB").save(dest, quality=92)


def _add_cuticle_grime(cell: Image.Image, nail: np.ndarray, amt: float) -> Image.Image:
    if amt <= 0.05 or not nail.any():
        return cell
    out = np.asarray(cell.convert("RGBA")).copy()
    nys, nxs = np.where(nail)
    y0, y1 = int(nys.min()), int(nys.max()) + 1
    x0, x1 = int(nxs.min()), int(nxs.max()) + 1
    h = y1 - y0
    band = nail[y0 : y0 + max(1, int(h * 0.20)), x0:x1]
    if not band.any():
        return cell
    yy = np.linspace(1.0, 0.0, band.shape[0], dtype=np.float32)[:, None]
    xx = np.linspace(-1.0, 1.0, band.shape[1], dtype=np.float32)[None, :]
    edge = np.clip(1.0 - (np.abs(xx) - 0.55) / 0.35, 0.0, 1.0)
    cover = (yy ** 1.4) * (0.55 + 0.45 * edge) * band.astype(np.float32) * amt
    dirt = np.array([42.0, 28.0, 18.0], dtype=np.float32)
    base = out[y0 : y0 + band.shape[0], x0:x1, :3].astype(np.float32)
    w = cover[..., None]
    out[y0 : y0 + band.shape[0], x0:x1, :3] = np.clip(base * (1.0 - w) + dirt * w, 0, 255)
    return Image.fromarray(out, "RGBA")


def _contact(rows: list[tuple[str, list[Image.Image]]], dest: Path) -> None:
    cell_w, cell_h = 180, 440
    pad, label_h = 10, 24
    width = pad * 2 + 4 * cell_w + 3 * 6
    height = pad * 2 + len(rows) * (cell_h + label_h + 8)
    page = Image.new("RGB", (width, height), (36, 32, 38))
    draw = ImageDraw.Draw(page)
    try:
        font = ImageFont.truetype("arial.ttf", 14)
    except OSError:
        font = ImageFont.load_default()
    y = pad
    for title, frames in rows:
        draw.text((pad, y), title, fill=(255, 230, 240), font=font)
        y += label_h
        x = pad
        for fr in frames[:4]:
            fr = fr.convert("RGBA")
            scale = min(cell_w / fr.width, cell_h / fr.height)
            nw, nh = max(1, round(fr.width * scale)), max(1, round(fr.height * scale))
            scaled = fr.resize((nw, nh), Image.LANCZOS)
            bg = Image.new("RGBA", (cell_w, cell_h), (*PINK, 255))
            bg.paste(scaled, ((cell_w - nw) // 2, (cell_h - nh) // 2), scaled)
            page.paste(bg.convert("RGB"), (x, y))
            x += cell_w + 6
        y += cell_h + 8
    dest.parent.mkdir(parents=True, exist_ok=True)
    page.save(dest, quality=90)


def main() -> None:
    SRC.mkdir(parents=True, exist_ok=True)
    clean_src = CURSOR_ASSETS / "c12_pinky_clean_still.png"
    dirty_src = CURSOR_ASSETS / "c12_pinky_dirty_still.png"
    shutil.copy2(clean_src, SRC / clean_src.name)
    shutil.copy2(dirty_src, SRC / dirty_src.name)

    clean = fit_finger_cell(Image.open(clean_src), PINKY_CELL)
    dirty_ref = fit_finger_cell(Image.open(dirty_src), PINKY_CELL)
    nail0 = nail_mask_light(clean)
    if not nail0.any():
        raise RuntimeError("empty pinky nail mask on clean still")

    clean_frames: list[Image.Image] = []
    for i, level in enumerate(DIRT_LEVELS):
        if level <= 0.02:
            clean_frames.append(clean.copy())
            continue
        stained = stain_nail(clean, level, dirty_ref)
        stained = _add_cuticle_grime(stained, nail0, amt=level * 0.7)
        clean_frames.append(stained)

    short_frames = [clip_left_to_right(clean, stage) for stage in range(4)]
    mask = polish_mask_from_nail(clipped_nail_mask(nail0, 3), short_frames[-1])

    OUT.mkdir(parents=True, exist_ok=True)
    pack_strip(clean_frames, OUT / "pinky_clean_light_c12.png")
    pack_strip(short_frames, OUT / "pinky_short_light_c12.png")
    mask.save(OUT / "pinky_nail_mask_light_c12.png")

    _preview(Image.open(OUT / "pinky_clean_light_c12.png"), OUT / "pinky_clean_light_c12_preview.jpg")
    _preview(Image.open(OUT / "pinky_short_light_c12.png"), OUT / "pinky_short_light_c12_preview.jpg")

    last = short_frames[-1]
    overlay = Image.new("RGBA", last.size, (255, 70, 140, 0))
    overlay.putalpha(mask.split()[-1].point(lambda v: int(v * 0.92)))
    _preview(Image.alpha_composite(last, overlay), OUT / "pinky_polish_light_c12_preview.jpg")
    _preview(mask, OUT / "pinky_nail_mask_light_c12_preview.jpg")

    c3_clean = even_cells(Image.open(IMAGES / "pinky_clean_dark.png"))
    c3_short = even_cells(Image.open(IMAGES / "pinky_short_dark.png"))
    _contact(
        [
            ("C3 pinky dirty→clean (ref)", c3_clean),
            ("C12 pinky spray 0-1 + wipe 2-3", clean_frames),
            ("C3 pinky long→short (ref)", c3_short),
            ("C12 pinky long→short left→right", short_frames),
        ],
        OUT / "pinky_c12_CONTACT.jpg",
    )

    debug = np.asarray(clean.convert("RGBA")).copy()
    overlay = np.zeros_like(debug)
    overlay[nail0] = (0, 220, 80, 150)
    _preview(
        Image.alpha_composite(Image.fromarray(debug), Image.fromarray(overlay)),
        OUT / "pinky_c12_nail_mask_debug.jpg",
    )
    alpha = np.asarray(mask.split()[-1]) > 40
    ys, xs = np.where(alpha)
    print("cell", PINKY_CELL)
    print("nail px", int(nail0.sum()), "mask px", int(alpha.sum()))
    print(
        "plate",
        int(xs.min()),
        int(ys.min()),
        int(xs.max() - xs.min() + 1),
        int(ys.max() - ys.min() + 1),
    )
    print("wrote", OUT / "pinky_clean_light_c12.png")


if __name__ == "__main__":
    main()
