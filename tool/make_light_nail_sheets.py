"""Build light-skin cartoon finger sheets for Lila / Ezgi (shared hand).

Three locked stills: pinky, middle (also ring + index), thumb.
Clean / clip / polish only change the nail. Same cell size as Zeynep.
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "tool"))

import make_zeynep_nail_sheets as zsheets  # noqa: E402
from make_zeynep_nail_sheets import (  # noqa: E402
    PINKY_CELL,
    clip_left_to_right,
    clipped_nail_mask,
    even_cells,
    pack_strip,
    plate_region,
    polish_mask_from_nail,
    preview_strip,
    stain_nail,
    _luma,
)
from pack_zeynep_customer import _crop_to_content, _key_auto  # noqa: E402

CURSOR_ASSETS = Path(
    r"C:\Users\Ezgi\.cursor\projects\c-Users-Ezgi-Documents-GitHub-nailGlam\assets"
)
IMAGES = REPO / "assets" / "images"
REVIEW = REPO / "tool" / "review_light_nails"
STILLS = {
    "pinky": REVIEW / "light_pinky_cartoon.png",
    "middle": REVIEW / "light_middle_cartoon.png",
    "thumb": REVIEW / "light_thumb_cartoon.png",
}
SHARED_MIDDLE = ("ring", "middle", "index")


def fit_light_cell(frame: Image.Image, cell_size: tuple[int, int] = PINKY_CELL) -> Image.Image:
    keyed = _crop_to_content(frame.convert("RGBA"))
    cell_w, cell_h = cell_size
    scale = min((cell_w - 16) / max(1, keyed.width), (cell_h - 16) / max(1, keyed.height))
    scaled = keyed.resize(
        (max(1, round(keyed.width * scale)), max(1, round(keyed.height * scale))),
        Image.LANCZOS,
    )
    canvas = Image.new("RGBA", cell_size, (0, 0, 0, 0))
    x = (cell_w - scaled.width) // 2
    y = cell_h - scaled.height - 8
    canvas.paste(scaled, (x, y), scaled)
    return canvas


def nail_mask_light(cell: Image.Image) -> np.ndarray:
    """Glossy pale plate on fair cartoon skin. Tip is the bottom of the cell."""
    arr = np.asarray(cell.convert("RGBA"))
    alpha = arr[..., 3] > 8
    if not alpha.any():
        return np.zeros(arr.shape[:2], dtype=bool)
    rgb = arr[..., :3].astype(np.float32)
    lum = _luma(rgb)
    ys = np.flatnonzero(alpha.any(axis=1))
    y0, y1 = int(ys[0]), int(ys[-1])
    span = max(1, y1 - y0)
    # Nail plate sits on the distal tip only (matches C3 ~400px plate height).
    distal = np.zeros(alpha.shape, dtype=bool)
    distal[y0 + int(span * 0.58) : y1 + 1] = True
    proximal = alpha & ~distal
    skin = float(np.median(lum[proximal])) if proximal.any() else float(np.median(lum[alpha]))
    # Enamel is paler + glossier than peach shaft.
    bright = alpha & distal & (lum >= max(skin + 18, 198.0))
    if bright.sum() < 800:
        bright = alpha & distal & (lum >= skin + 12) & (lum >= 190)
    if not bright.any():
        return np.zeros(alpha.shape, dtype=bool)
    height, width = bright.shape
    rows = np.flatnonzero(bright.any(axis=1))
    tip_y = None
    seed_x = None
    for ty in reversed(rows):
        xs = np.flatnonzero(bright[int(ty)])
        if xs.size >= 8:
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
    if keep.sum() < 400:
        keep = np.zeros((height, width), dtype=bool)
        seen.fill(False)
        best_n = 0
        ys_b, xs_b = np.where(bright)
        for y, x in zip(ys_b, xs_b):
            if seen[y, x]:
                continue
            stack = [(int(x), int(y))]
            pixels: list[tuple[int, int]] = []
            while stack:
                cx, cy = stack.pop()
                if cx < 0 or cy < 0 or cx >= width or cy >= height or seen[cy, cx]:
                    continue
                seen[cy, cx] = True
                if not bright[cy, cx]:
                    continue
                pixels.append((cx, cy))
                stack.extend(((cx - 1, cy), (cx + 1, cy), (cx, cy - 1), (cx, cy + 1)))
            if len(pixels) > best_n:
                best_n = len(pixels)
                keep[:, :] = False
                pts = np.array(pixels)
                keep[pts[:, 1], pts[:, 0]] = True
        if keep.sum() < 400:
            return np.zeros(alpha.shape, dtype=bool)
    raw = Image.fromarray(keep.astype(np.uint8) * 255, "L")
    closed = raw.filter(ImageFilter.MaxFilter(3)).filter(ImageFilter.MinFilter(3))
    plate = (np.asarray(closed) > 127) & alpha & distal
    # Cap plate height so shaft skin never counts as enamel.
    pys = np.flatnonzero(plate.any(axis=1))
    if pys.size:
        tip = int(pys[-1])
        max_h = max(180, int(span * 0.34))
        plate[: max(0, tip - max_h), :] = False
    return plate


def _largest_blob(image: Image.Image) -> Image.Image:
    arr = np.asarray(image.convert("RGBA"))
    alpha = arr[..., 3] > 8
    if not alpha.any():
        return image
    h, w = alpha.shape
    seen = np.zeros((h, w), dtype=bool)
    best: np.ndarray | None = None
    best_n = 0
    ys, xs = np.where(alpha)
    for y, x in zip(ys, xs):
        if seen[y, x]:
            continue
        stack = [(int(x), int(y))]
        pixels: list[tuple[int, int]] = []
        while stack:
            cx, cy = stack.pop()
            if cx < 0 or cy < 0 or cx >= w or cy >= h or seen[cy, cx] or not alpha[cy, cx]:
                continue
            seen[cy, cx] = True
            pixels.append((cx, cy))
            stack.extend(((cx - 1, cy), (cx + 1, cy), (cx, cy - 1), (cx, cy + 1)))
        if len(pixels) > best_n:
            best_n = len(pixels)
            blob = np.zeros((h, w), dtype=bool)
            pts = np.array(pixels)
            blob[pts[:, 1], pts[:, 0]] = True
            best = blob
    if best is None:
        return image
    out = arr.copy()
    out[..., 3] = np.where(best, out[..., 3], 0)
    return _crop_to_content(Image.fromarray(out, "RGBA"))


def copy_cartoon_stills() -> None:
    REVIEW.mkdir(parents=True, exist_ok=True)
    for stem in ("pinky", "middle", "thumb"):
        src = CURSOR_ASSETS / f"light_{stem}_cartoon.png"
        dest = REVIEW / f"light_{stem}_cartoon.png"
        Image.open(src).save(dest)
        print("still", stem, dest.name, Image.open(src).size)


def orient_nail_down(keyed: Image.Image) -> Image.Image:
    """Zeynep clip expects the free edge at the bottom of the cell."""
    arr = np.asarray(keyed.convert("RGBA"))
    alpha = arr[..., 3] > 8
    if not alpha.any():
        return keyed
    lum = _luma(arr[..., :3].astype(np.float32))
    skin = float(np.median(lum[alpha]))
    bright = alpha & (lum >= skin + 8)
    if bright.sum() < 400:
        return keyed
    ys = np.flatnonzero(alpha.any(axis=1))
    mid = (int(ys[0]) + int(ys[-1])) / 2.0
    cy = float(np.where(bright)[0].mean())
    if cy < mid:
        return keyed.rotate(180, expand=True)
    return keyed


def build_from_still(still: Image.Image, stem: str) -> dict[str, tuple[int, int, int, int]]:
    zsheets.nail_mask = lambda cell, luma_min=145: nail_mask_light(cell)
    dirt = even_cells(Image.open(IMAGES / "pinky_clean_dark.png"))
    keyed = orient_nail_down(_largest_blob(_crop_to_content(_key_auto(still.convert("RGBA")))))
    cell = fit_light_cell(keyed)
    levels = (1.0, 0.62, 0.28, 0.0)
    clean_frames = [
        stain_nail(cell, level, dirt[min(i, len(dirt) - 1)])
        for i, level in enumerate(levels)
    ]
    clean_frames[-1] = cell.copy()
    short_frames = [clip_left_to_right(cell, stage) for stage in range(4)]
    nail0 = nail_mask_light(cell)
    if not nail0.any():
        raise RuntimeError(f"{stem}: nail mask empty")
    mask = polish_mask_from_nail(clipped_nail_mask(nail0, 3), short_frames[-1])
    REVIEW.mkdir(parents=True, exist_ok=True)
    pack_strip(clean_frames, REVIEW / f"{stem}_clean_light.png")
    pack_strip(short_frames, REVIEW / f"{stem}_short_light.png")
    mask.save(REVIEW / f"{stem}_nail_mask_light.png")
    pack_strip(clean_frames, IMAGES / f"{stem}_clean_light.png")
    pack_strip(short_frames, IMAGES / f"{stem}_short_light.png")
    mask.save(IMAGES / f"{stem}_nail_mask_light.png")
    preview_strip(
        Image.open(IMAGES / f"{stem}_clean_light.png"),
        REVIEW / f"preview_{stem}_clean.jpg",
    )
    preview_strip(
        Image.open(IMAGES / f"{stem}_short_light.png"),
        REVIEW / f"preview_{stem}_short.jpg",
    )
    overlay = Image.new("RGBA", short_frames[-1].size, (255, 70, 140, 0))
    overlay.putalpha(mask.split()[-1].point(lambda v: int(v * 0.92)))
    Image.alpha_composite(short_frames[-1], overlay).save(
        REVIEW / f"preview_{stem}_polish.png"
    )
    plate = plate_region(mask)
    print(
        stem,
        "cell",
        cell.size,
        "plate",
        plate,
        "nail px",
        int(nail0.sum()),
    )
    master = np.asarray(cell)
    for i, frame in enumerate(short_frames[1:], start=1):
        finger_lost = int(
            ((master[..., 3] > 8) & (np.asarray(frame)[..., 3] < 8) & (~nail0)).sum()
        )
        assert finger_lost < 400, f"{stem} short {i} clipped the finger ({finger_lost}px)"
    return {stem: plate}


def share_middle() -> dict[str, tuple[int, int, int, int]]:
    plate = plate_region(Image.open(IMAGES / "middle_nail_mask_light.png"))
    for stem in ("ring", "index"):
        for suffix in ("clean_light.png", "short_light.png", "nail_mask_light.png"):
            Image.open(IMAGES / f"middle_{suffix}").save(IMAGES / f"{stem}_{suffix}")
        print(stem, "reuses middle", "plate", plate)
    return {stem: plate for stem in SHARED_MIDDLE}


def _feather_nail_alpha(keep: np.ndarray) -> np.ndarray:
    from make_zeynep_nail_sheets import _fill_interior_gaps

    keep = _fill_interior_gaps(keep, max_gap=12)
    inset = Image.fromarray(keep.astype(np.uint8) * 255, "L").filter(
        ImageFilter.MinFilter(3)
    )
    feather = inset.filter(ImageFilter.GaussianBlur(1.6))
    alpha = np.asarray(feather).astype(np.float32)
    return np.clip(alpha * 1.05, 0, 255).astype(np.uint8)


def _rgba_mask(alpha: np.ndarray) -> Image.Image:
    out = np.zeros((*alpha.shape, 4), dtype=np.uint8)
    out[..., :3] = 255
    out[..., 3] = alpha
    return Image.fromarray(out, "RGBA")


def build_final_hand_nail_mask() -> Path:
    src = CURSOR_ASSETS / "light_final_hand_cartoon.png"
    keyed = _crop_to_content(_key_auto(Image.open(src).convert("RGBA")))
    keyed.save(IMAGES / "final_hand_light.png")
    print("final hand keyed", keyed.size)
    arr = np.asarray(keyed)
    rgb = arr[..., :3].astype(np.float32)
    lum = _luma(rgb)
    finger = arr[..., 3] > 8
    skin = float(np.median(lum[finger])) if finger.any() else 140.0
    chroma_rg = rgb[..., 0] - rgb[..., 1]
    ys = np.flatnonzero(finger.any(axis=1))
    y0, y1 = int(ys[0]), int(ys[-1])
    tip_band = np.zeros(finger.shape, dtype=bool)
    tip_band[y0 : y0 + int((y1 - y0) * 0.55)] = True
    bright = finger & tip_band & (lum >= skin + 6) & (lum >= 168) & (chroma_rg < 36)
    h, w = bright.shape
    seen = np.zeros((h, w), dtype=bool)
    blobs: list[np.ndarray] = []
    ys_b, xs_b = np.where(bright)
    for y, x in zip(ys_b, xs_b):
        if seen[y, x]:
            continue
        stack = [(int(x), int(y))]
        pixels: list[tuple[int, int]] = []
        while stack:
            cx, cy = stack.pop()
            if cx < 0 or cy < 0 or cx >= w or cy >= h or seen[cy, cx] or not bright[cy, cx]:
                continue
            seen[cy, cx] = True
            pixels.append((cx, cy))
            stack.extend(((cx - 1, cy), (cx + 1, cy), (cx, cy - 1), (cx, cy + 1)))
        if not (400 <= len(pixels) <= 80000):
            continue
        pts = np.array(pixels)
        blob = np.zeros((h, w), dtype=bool)
        blob[pts[:, 1], pts[:, 0]] = True
        blobs.append(blob)
    blobs.sort(key=lambda b: int(np.where(b)[1].mean()))
    blobs = blobs[:5]
    stems = ("pinky", "ring", "middle", "pointer", "thumb")
    keep = np.zeros((h, w), dtype=bool)
    for blob, stem in zip(blobs, stems):
        keep |= blob
        _rgba_mask(_feather_nail_alpha(blob)).save(IMAGES / f"final_hand_light_nail_{stem}.png")
        print("final nail", stem, "cx", round(float(np.where(blob)[1].mean()), 1), "n", int(blob.sum()))
    dest = IMAGES / "final_hand_light_nail_mask.png"
    _rgba_mask(_feather_nail_alpha(keep)).save(dest)
    preview = Image.new("RGBA", keyed.size, (0, 0, 0, 255))
    preview.alpha_composite(keyed)
    swatches = (
        (255, 107, 168),
        (208, 18, 58),
        (230, 184, 162),
        (244, 228, 236),
        (212, 160, 23),
    )
    for blob, rgb_s in zip(blobs, swatches):
        tint = Image.new("RGBA", keyed.size, (*rgb_s, 0))
        tint.putalpha(
            Image.fromarray(_feather_nail_alpha(blob), "L").point(lambda v: int(v * 0.88))
        )
        preview = Image.alpha_composite(preview, tint)
    preview.convert("RGB").save(REVIEW / "preview_final_hand_multicolor.jpg")
    print("final hand nails", int(keep.sum()), "digits", len(blobs), "skin", round(skin, 1))
    return dest


def main() -> None:
    copy_cartoon_stills()
    plates: dict[str, tuple[int, int, int, int]] = {}
    for stem in ("pinky", "middle", "thumb"):
        plates.update(build_from_still(Image.open(STILLS[stem]), stem))
    plates.update(share_middle())
    build_final_hand_nail_mask()
    print("plates", plates)


if __name__ == "__main__":
    main()
