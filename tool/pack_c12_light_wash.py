"""Lock the approved C1/C2 dirty hand and dissolve skin dirt across 4 cells.

Pose, scale and silhouette stay identical. Nails stay dirty. Background is
transparent. Writes approval files only — does not overwrite game assets.
"""

from __future__ import annotations

import shutil
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "tool"))
from pack_zeynep_customer import _key_auto  # noqa: E402

CURSOR_ASSETS = Path(
    r"C:\Users\Ezgi\.cursor\projects\c-Users-Ezgi-Documents-GitHub-nailGlam\assets"
)
SRC = REPO / "tool" / "review_light_nails" / "src"
OUT = REPO / "tool" / "review_light_nails" / "approval"
PINK = (255, 182, 193)
PAD = 36
DIRT_LEVELS = (1.0, 0.58, 0.22, 0.0)


def _luma(rgb: np.ndarray) -> np.ndarray:
    return 0.2126 * rgb[..., 0] + 0.7152 * rgb[..., 1] + 0.0722 * rgb[..., 2]


def _copy_sources() -> tuple[Path, Path]:
    SRC.mkdir(parents=True, exist_ok=True)
    dirty_src = CURSOR_ASSETS / "c12_wash_dirty_still.png"
    clean_src = CURSOR_ASSETS / "c12_wash_f3_clean.png"
    if not dirty_src.exists():
        raise FileNotFoundError(dirty_src)
    dirty = SRC / "c12_wash_dirty_still.png"
    clean = SRC / "c12_wash_f3_clean.png"
    shutil.copy2(dirty_src, dirty)
    if clean_src.exists():
        shutil.copy2(clean_src, clean)
    return dirty, clean


def _content_bbox(arr: np.ndarray, thresh: int = 10) -> tuple[int, int, int, int]:
    ys, xs = np.where(arr[..., 3] > thresh)
    if xs.size == 0:
        return 0, 0, arr.shape[1], arr.shape[0]
    return int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1


def _place_on_canvas(frame: Image.Image, cell: tuple[int, int], box: tuple[int, int, int, int]) -> Image.Image:
    """Scale content uniformly into [box] on a transparent cell. Same box → same pose."""
    arr = np.asarray(frame.convert("RGBA"))
    x0, y0, x1, y1 = _content_bbox(arr)
    crop = frame.crop((x0, y0, x1, y1))
    tw, th = box[2] - box[0], box[3] - box[1]
    scale = min(tw / crop.width, th / crop.height)
    nw, nh = max(1, round(crop.width * scale)), max(1, round(crop.height * scale))
    scaled = crop.resize((nw, nh), Image.LANCZOS)
    canvas = Image.new("RGBA", cell, (0, 0, 0, 0))
    px = box[0] + (tw - nw) // 2
    py = box[1] + (th - nh) // 2
    canvas.alpha_composite(scaled, (px, py))
    return canvas


def _nail_mask(arr: np.ndarray) -> np.ndarray:
    """Only the long plates + a thin cuticle/tip crust. Fingers stay washable."""
    alpha = arr[..., 3] > 10
    rgb = arr[..., :3].astype(np.float32)
    lum = _luma(rgb)
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    h, w = alpha.shape
    ys = np.where(alpha)[0]
    y0, y1 = int(ys.min()), int(ys.max())
    distal = np.zeros((h, w), dtype=bool)
    for x in range(w):
        hit = np.flatnonzero(alpha[:, x])
        if hit.size == 0:
            continue
        tip = int(hit[-1])
        if tip < y0 + int((y1 - y0) * 0.62):
            continue
        nail_h = max(48, int((tip - int(hit[0]) + 1) * 0.16))
        distal[max(0, tip - nail_h) : tip + 1, x] = True
    plate = (
        alpha
        & distal
        & (lum >= 125)
        & (r > 150)
        & (g > 120)
        & ((r + g) / 2.0 > b + 18)
        & ((r - b) > 22)
    )
    grown = Image.fromarray(plate.astype(np.uint8) * 255, "L").filter(
        ImageFilter.MaxFilter(7)
    )
    near_plate = (np.asarray(grown) > 40) & alpha
    tip_crust = near_plate & (lum < 95)
    nail = (plate | tip_crust) & alpha
    nail = (
        np.asarray(
            Image.fromarray(nail.astype(np.uint8) * 255, "L").filter(
                ImageFilter.MaxFilter(5)
            )
        )
        > 40
    ) & alpha
    nail[: y0 + int((y1 - y0) * 0.46), :] = False
    return nail


def _dirt_on_skin(arr: np.ndarray, nail: np.ndarray) -> np.ndarray:
    alpha = arr[..., 3] > 10
    lum = _luma(arr[..., :3].astype(np.float32))
    skin = alpha & ~nail
    if not skin.any():
        return np.zeros(alpha.shape, dtype=bool)
    # Soot is much darker than peach skin; keep the threshold tight so
    # knuckle shade is not treated as grime.
    floor = float(np.percentile(lum[skin], 28))
    dirt = skin & (lum <= floor)
    interior = (
        np.asarray(
            Image.fromarray((arr[..., 3] > 10).astype(np.uint8) * 255, "L").filter(
                ImageFilter.MinFilter(5)
            )
        )
        > 40
    )
    dirt = dirt & interior
    dirt = (
        np.asarray(
            Image.fromarray(dirt.astype(np.uint8) * 255, "L").filter(
                ImageFilter.MaxFilter(3)
            )
        )
        > 40
    )
    return dirt & skin & interior


def _clean_skin_color(arr: np.ndarray, skin: np.ndarray, dirt: np.ndarray) -> np.ndarray:
    """Inpaint peach skin from non-dirt neighbors. Pose stays pixel-locked."""
    rgb = arr[..., :3].astype(np.float32)
    lum = _luma(rgb)
    support = (skin & ~dirt & (lum >= float(np.percentile(lum[skin], 45)))).astype(
        np.float32
    )
    if float(support.sum()) < 80:
        support = skin.astype(np.float32)
    colored = np.dstack([rgb * support[..., None], support * 255.0]).astype(np.uint8)
    blur = np.asarray(
        Image.fromarray(colored, "RGBA").filter(ImageFilter.GaussianBlur(radius=18)),
        dtype=np.float32,
    )
    acc = blur[..., :3]
    weight = blur[..., 3] / 255.0
    return acc / np.clip(weight, 1e-3, None)[..., None]


def _dissolve(
    dirty: np.ndarray,
    _clean: np.ndarray,
    nail: np.ndarray,
    dirt: np.ndarray,
    remain: float,
) -> np.ndarray:
    out = dirty.copy()
    alpha = dirty[..., 3] > 10
    skin = alpha & ~nail
    filled = _clean_skin_color(dirty, skin, dirt)
    if remain < 0.999 and dirt.any():
        fade = 1.0 - remain
        mixed = dirty[..., :3].astype(np.float32) * remain + filled * fade
        out[..., :3] = np.where(dirt[..., None], np.clip(mixed, 0, 255), out[..., :3])
    if remain <= 0.02:
        out[..., :3] = np.where(dirt[..., None], np.clip(filled, 0, 255), out[..., :3])
    out[..., 3] = dirty[..., 3]
    return out.astype(np.uint8)


def _preview(strip: Image.Image, dest: Path) -> None:
    canvas = Image.new("RGBA", strip.size, (*PINK, 255))
    canvas.alpha_composite(strip)
    dest.parent.mkdir(parents=True, exist_ok=True)
    canvas.convert("RGB").save(dest, quality=92)


def main() -> None:
    dirty_path, clean_path = _copy_sources()
    dirty_keyed = _key_auto(Image.open(dirty_path))
    clean_keyed = _key_auto(Image.open(clean_path)) if clean_path.exists() else dirty_keyed

    darr = np.asarray(dirty_keyed.convert("RGBA"))
    x0, y0, x1, y1 = _content_bbox(darr)
    cell_w = (x1 - x0) + PAD * 2
    cell_h = (y1 - y0) + PAD * 2
    box = (PAD, PAD, PAD + (x1 - x0), PAD + (y1 - y0))
    cell = (cell_w, cell_h)

    dirty_cell = _place_on_canvas(dirty_keyed, cell, box)
    clean_cell = _place_on_canvas(clean_keyed, cell, box)
    dirty_arr = np.asarray(dirty_cell).copy()
    clean_arr = np.asarray(clean_cell).copy()
    # Force identical silhouette from the approved dirty hand.
    clean_arr[..., 3] = dirty_arr[..., 3]
    nail = _nail_mask(dirty_arr)
    dirt = _dirt_on_skin(dirty_arr, nail)

    frames: list[Image.Image] = []
    for remain in DIRT_LEVELS:
        frames.append(Image.fromarray(_dissolve(dirty_arr, clean_arr, nail, dirt, remain), "RGBA"))

    strip = Image.new("RGBA", (cell_w * 4, cell_h), (0, 0, 0, 0))
    for i, frame in enumerate(frames):
        strip.paste(frame, (i * cell_w, 0), frame)

    OUT.mkdir(parents=True, exist_ok=True)
    dest = OUT / "hand_wash_light_c12.png"
    strip.save(dest)
    _preview(strip, OUT / "hand_wash_light_c12_preview.jpg")
    for i, frame in enumerate(frames):
        _preview(frame, OUT / f"hand_wash_light_c12_f{i}.jpg")

    debug = dirty_arr.copy()
    overlay = np.zeros_like(debug)
    overlay[nail] = (0, 220, 80, 140)
    overlay[dirt & ~nail] = (220, 40, 40, 120)
    dbg = Image.alpha_composite(Image.fromarray(debug), Image.fromarray(overlay))
    _preview(dbg, OUT / "hand_wash_light_c12_nail_dirt_debug.jpg")

    print("cell", cell_w, cell_h)
    print("nail px", int(nail.sum()), "dirt px", int(dirt.sum()))
    print("wrote", dest)


if __name__ == "__main__":
    main()
