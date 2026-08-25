"""Build Zeynep finger sheets from one locked still per digit.

Clean / clip / polish only change the nail. The finger never moves.
Background stays transparent.
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "tool"))
from pack_zeynep_customer import _crop_to_content, _key_auto, _keep_main_person  # noqa: E402

IMAGES = REPO / "assets" / "images"
REVIEW = REPO / "tool" / "review_zeynep_nails"
PINKY_CELL = (464, 1398)
SHORT_FRACS = (1.0, 0.86, 0.72, 0.58)
FINAL_KEEP = 0.58


def _luma(rgb: np.ndarray) -> np.ndarray:
    return 0.2126 * rgb[..., 0] + 0.7152 * rgb[..., 1] + 0.0722 * rgb[..., 2]


def _fill_interior_gaps(alpha: np.ndarray, max_gap: int = 10) -> np.ndarray:
    """Close small holes between opaque runs; do not grow the silhouette."""
    filled = alpha.copy()
    height, width = filled.shape
    for y in range(height):
        xs = np.flatnonzero(filled[y])
        if xs.size < 2:
            continue
        gaps = np.diff(xs)
        for i, gap in enumerate(gaps):
            if 1 < gap <= max_gap:
                filled[y, xs[i] + 1 : xs[i + 1]] = True
    return filled


def _sample_plate_color(arr: np.ndarray, nail: np.ndarray, x: int, cap_y: int) -> np.ndarray | None:
    """Nail enamel from the solid plate above the bite, not the dark outline."""
    y0 = max(0, cap_y - 90)
    y1 = max(y0 + 1, cap_y - 12)
    hits = np.flatnonzero(nail[y0:y1, x])
    if hits.size:
        sy = y0 + int(hits[len(hits) // 2])
        if arr[sy, x, 3] >= 16 and float(_luma(arr[sy, x, :3].astype(np.float32))) >= 130:
            return arr[sy, x].copy()
    nearby = []
    for dx in range(1, 18):
        for nx in (x - dx, x + dx):
            if nx < 0 or nx >= arr.shape[1]:
                continue
            hits = np.flatnonzero(nail[y0:y1, nx])
            if not hits.size:
                continue
            sy = y0 + int(hits[len(hits) // 2])
            if arr[sy, nx, 3] >= 16 and float(_luma(arr[sy, nx, :3].astype(np.float32))) >= 130:
                nearby.append(arr[sy, nx].astype(np.int16))
        if nearby:
            return np.clip(np.mean(nearby, axis=0), 0, 255).astype(np.uint8)
    return None


def _seal_clip(
    arr: np.ndarray,
    nail: np.ndarray,
    cut_line: np.ndarray,
    final_y: int,
    stage: int,
) -> None:
    """Fill side triangles on the short plate; only seal the bite face on later stages."""
    height, width = arr.shape[:2]
    lum = _luma(arr[..., :3].astype(np.float32))
    y_lo = max(0, final_y - 42)
    y_hi = min(height - 1, int(np.ceil(cut_line.max())) + 2)
    band = nail[y_lo : final_y + 1]
    if not band.any():
        return
    plate_l = int(np.flatnonzero(band.any(0))[0])
    plate_r = int(np.flatnonzero(band.any(0))[-1])
    colors: dict[int, np.ndarray] = {}
    for x in range(plate_l, plate_r + 1):
        sampled = _sample_plate_color(arr, nail, x, final_y)
        if sampled is not None:
            colors[x] = sampled
    last: np.ndarray | None = None
    for x in range(plate_l, plate_r + 1):
        if x in colors:
            last = colors[x]
        elif last is not None:
            colors[x] = last
    last = None
    for x in range(plate_r, plate_l - 1, -1):
        if x in colors:
            last = colors[x]
        elif last is not None:
            colors[x] = last

    for x in range(plate_l, plate_r + 1):
        color = colors.get(x)
        if color is None:
            continue
        y_cut = int(np.floor(cut_line[0, x]))
        if stage == 3:
            y_edge = y_cut
            # Only seal the cut face — do not repaint the whole plate (kills gloss).
            for y in range(max(0, y_edge - 4), y_edge + 1):
                if not nail[y, x]:
                    continue
                if arr[y, x, 3] < 20 or lum[y, x] < 125:
                    arr[y, x] = color
            below = nail[y_edge + 1 : y_hi + 1, x]
            if below.any():
                arr[y_edge + 1 : y_hi + 1, x][below] = 0
        else:
            # Only close the cut face. Do not paint hanging enamel under the diagonal.
            had_nail = nail[max(0, y_cut - 16) : y_cut + 1, x].any()
            if not had_nail:
                continue
            for y in range(max(0, y_cut - 6), y_cut + 1):
                if not nail[y, x]:
                    continue
                if arr[y, x, 3] < 20 or lum[y, x] < 120:
                    arr[y, x] = color

    # Seal holes only inside the original nail plate.
    kept = arr[..., 3] > 16
    sealed = _fill_interior_gaps(kept & nail, max_gap=14)
    yy = np.arange(height)[:, None]
    fill_hi = final_y + 2 if stage == 3 else int(np.ceil(cut_line.max()))
    band_m = nail & (yy >= y_lo) & (yy <= fill_hi)
    if stage != 3:
        band_m = band_m & (np.abs(yy - cut_line) <= 6)
    for y, x in zip(*np.where(sealed & (arr[..., 3] < 16) & band_m)):
        color = colors.get(int(x))
        if color is not None:
            arr[y, x] = color


def polish_mask_from_nail(nail: np.ndarray, cell: Image.Image) -> Image.Image:
    """Build polish alpha from a known nail plate mask (exact fit)."""
    keep = nail.copy()
    keep = _fill_interior_gaps(keep, max_gap=24)
    for y in range(keep.shape[0]):
        xs = np.flatnonzero(keep[y])
        if xs.size >= 3:
            keep[y, int(xs[0]) : int(xs[-1]) + 1] = True
    raw = Image.fromarray(keep.astype(np.uint8) * 255, "L")
    closed = raw.filter(ImageFilter.MaxFilter(3)).filter(ImageFilter.MinFilter(3))
    finger = np.asarray(cell.convert("RGBA"))[..., 3] > 8
    plate = (np.asarray(closed) > 127) & finger & keep
    plate = _fill_interior_gaps(plate, max_gap=14)
    for y in range(plate.shape[0]):
        xs = np.flatnonzero(plate[y])
        if xs.size >= 3:
            plate[y, int(xs[0]) : int(xs[-1]) + 1] = True
    plate &= finger
    feather = Image.fromarray(plate.astype(np.uint8) * 255, "L").filter(
        ImageFilter.GaussianBlur(0.35)
    )
    alpha = np.asarray(feather).astype(np.int16)
    alpha = np.where(plate, np.clip(alpha + 90, 0, 255), 0)
    out = np.zeros((cell.height, cell.width, 4), dtype=np.uint8)
    out[..., :3] = 255
    out[..., 3] = alpha.astype(np.uint8)
    return Image.fromarray(out, "RGBA")


def clip_left_to_right(cell: Image.Image, stage: int) -> Image.Image:
    """Clipper bite across the free edge, left → right. Finger stays put.

    0 full length, 1 left diagonal bite, 2 bite continues right, 3 short free edge.
    Only nail-plate pixels are removed — never finger skin.
    """
    arr = np.asarray(cell.convert("RGBA")).copy()
    if stage <= 0:
        return Image.fromarray(arr, "RGBA")
    nail = nail_mask(cell, luma_min=130)
    if not nail.any():
        return Image.fromarray(arr, "RGBA")
    ys, xs = np.where(nail)
    base_y, tip_y = int(ys.min()), int(ys.max())
    left, right = int(xs.min()), int(xs.max())
    final_y = int(round(base_y + (tip_y - base_y) * FINAL_KEEP))
    height, width = arr.shape[:2]
    yy, xx = np.indices((height, width))
    span = max(1, right - left)
    t = np.clip((xx - left) / span, 0.0, 1.0)
    extra = float(tip_y - final_y)
    if stage == 1:
        cut_line = final_y + 0.10 * extra + t * 0.90 * extra
    elif stage == 2:
        cut_line = final_y + t * 0.42 * extra
    else:
        cut_line = np.full((height, width), float(final_y), dtype=np.float32)
    # Hard cut: original nail plate only — never finger skin.
    tip_remove = nail & (yy > cut_line)
    # Soft AA fringe: 1px dilation that still looks like nail enamel, not skin.
    soft = np.asarray(
        Image.fromarray(nail.astype(np.uint8) * 255, "L").filter(ImageFilter.MaxFilter(3))
    ) > 40
    soft_m = soft & ~nail & (yy > cut_line)
    rgb = arr[..., :3].astype(np.float32)
    L = _luma(rgb)
    chroma = np.maximum(np.maximum(arr[..., 0], arr[..., 1]), arr[..., 2]).astype(
        np.int16
    ) - np.minimum(np.minimum(arr[..., 0], arr[..., 1]), arr[..., 2])
    soft_m &= (arr[..., 3] > 8) & (L > 100) & (chroma < 50)
    arr[tip_remove | soft_m] = 0
    _seal_clip(arr, nail, cut_line, final_y, stage)
    return Image.fromarray(arr, "RGBA")


def clipped_nail_mask(nail: np.ndarray, stage: int) -> np.ndarray:
    """Nail plate remaining after the same bite geometry as clip_left_to_right."""
    if stage <= 0 or not nail.any():
        return nail.copy()
    ys, xs = np.where(nail)
    base_y, tip_y = int(ys.min()), int(ys.max())
    left, right = int(xs.min()), int(xs.max())
    final_y = int(round(base_y + (tip_y - base_y) * FINAL_KEEP))
    height, width = nail.shape
    yy, xx = np.indices((height, width))
    span = max(1, right - left)
    t = np.clip((xx - left) / span, 0.0, 1.0)
    extra = float(tip_y - final_y)
    if stage == 1:
        cut_line = final_y + 0.10 * extra + t * 0.90 * extra
    elif stage == 2:
        cut_line = final_y + t * 0.42 * extra
    else:
        cut_line = np.full((height, width), float(final_y), dtype=np.float32)
    return nail & (yy <= cut_line)


def even_cells(image: Image.Image, frames: int = 4) -> list[Image.Image]:
    width, height = image.size
    cell_w = width // frames
    return [
        image.crop((i * cell_w, 0, (i + 1) * cell_w, height)).convert("RGBA")
        for i in range(frames)
    ]


def nail_mask(cell: Image.Image, luma_min: float = 145) -> np.ndarray:
    """Bright plate connected to the downward tip. Dark skin stays out."""
    arr = np.asarray(cell.convert("RGBA"))
    height, width = arr.shape[:2]
    alpha = arr[..., 3] > 8
    lum = _luma(arr[..., :3].astype(np.float32))
    if not alpha.any():
        return np.zeros((height, width), dtype=bool)
    bright = alpha & (lum >= luma_min)
    if not bright.any():
        return np.zeros((height, width), dtype=bool)
    tip_y = int(np.flatnonzero(bright.any(axis=1))[-1])
    tip_row = np.flatnonzero(bright[tip_y])
    seed_x = int(tip_row[len(tip_row) // 2])
    keep = np.zeros((height, width), dtype=bool)
    stack = [(seed_x, tip_y)]
    seen = np.zeros((height, width), dtype=bool)
    while stack:
        x, y = stack.pop()
        if x < 0 or y < 0 or x >= width or y >= height or seen[y, x]:
            continue
        seen[y, x] = True
        if not bright[y, x]:
            continue
        keep[y, x] = True
        stack.extend(((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)))
    if not keep.any():
        # Fallback: seed from the brightest pixel near the tip.
        band = bright[max(0, tip_y - 40) : tip_y + 1]
        if band.any():
            by, bx = np.unravel_index(int(np.argmax(lum[max(0, tip_y - 40) : tip_y + 1] * band)), band.shape)
            stack = [(int(bx), int(max(0, tip_y - 40) + by))]
            seen[:] = False
            while stack:
                x, y = stack.pop()
                if x < 0 or y < 0 or x >= width or y >= height or seen[y, x]:
                    continue
                seen[y, x] = True
                if not bright[y, x]:
                    continue
                keep[y, x] = True
                stack.extend(((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)))
    if not keep.any():
        return np.zeros((height, width), dtype=bool)
    # Close 1px holes inside the plate.
    from PIL import ImageFilter as F

    raw = Image.fromarray(keep.astype(np.uint8) * 255, "L")
    closed = raw.filter(F.MaxFilter(3)).filter(F.MinFilter(3))
    return np.asarray(closed) > 127


def polish_mask(cell: Image.Image) -> Image.Image:
    """Mask that matches this cell's nail plate 1:1 (for the clipped short tip)."""
    keep = nail_mask(cell, luma_min=130)
    keep = _fill_interior_gaps(keep, max_gap=24)
    for y in range(keep.shape[0]):
        xs = np.flatnonzero(keep[y])
        if xs.size >= 3:
            keep[y, int(xs[0]) : int(xs[-1]) + 1] = True
    raw = Image.fromarray(keep.astype(np.uint8) * 255, "L")
    closed = raw.filter(ImageFilter.MaxFilter(3)).filter(ImageFilter.MinFilter(3))
    finger = np.asarray(cell.convert("RGBA"))[..., 3] > 8
    lum = _luma(np.asarray(cell.convert("RGBA"))[..., :3].astype(np.float32))
    plate = (np.asarray(closed) > 127) & finger & (lum >= 118)
    plate = _fill_interior_gaps(plate, max_gap=14)
    for y in range(plate.shape[0]):
        xs = np.flatnonzero(plate[y])
        if xs.size >= 3:
            plate[y, int(xs[0]) : int(xs[-1]) + 1] = True
    # Clip to finger silhouette so mask never spills onto transparent.
    plate &= finger
    feather = Image.fromarray(plate.astype(np.uint8) * 255, "L").filter(
        ImageFilter.GaussianBlur(0.35)
    )
    alpha = np.asarray(feather).astype(np.int16)
    alpha = np.where(plate, np.clip(alpha + 90, 0, 255), 0)
    out = np.zeros((cell.height, cell.width, 4), dtype=np.uint8)
    out[..., :3] = 255
    out[..., 3] = alpha.astype(np.uint8)
    return Image.fromarray(out, "RGBA")


def plate_region(mask: Image.Image) -> tuple[int, int, int, int]:
    alpha = np.asarray(mask.split()[3]) > 40
    ys, xs = np.where(alpha)
    return int(xs.min()), int(ys.min()), int(xs.max() - xs.min() + 1), int(ys.max() - ys.min() + 1)


def pack_strip(frames: list[Image.Image], dest: Path) -> None:
    cell_w, cell_h = frames[0].size
    strip = Image.new("RGBA", (cell_w * len(frames), cell_h), (0, 0, 0, 0))
    for i, frame in enumerate(frames):
        strip.paste(frame, (i * cell_w, 0), frame)
    dest.parent.mkdir(parents=True, exist_ok=True)
    strip.save(dest)


def fit_finger_cell(frame: Image.Image, cell_size: tuple[int, int] = PINKY_CELL) -> Image.Image:
    keyed = _crop_to_content(_keep_main_person(_key_auto(frame)))
    cell_w, cell_h = cell_size
    scale = min((cell_w - 16) / keyed.width, (cell_h - 16) / keyed.height)
    scaled = keyed.resize(
        (max(1, round(keyed.width * scale)), max(1, round(keyed.height * scale))),
        Image.LANCZOS,
    )
    canvas = Image.new("RGBA", cell_size, (0, 0, 0, 0))
    x = (cell_w - scaled.width) // 2
    y = cell_h - scaled.height - 8
    canvas.paste(scaled, (x, y), scaled)
    return canvas


def stain_nail(clean: Image.Image, dirt_level: float, dirt_ref: Image.Image) -> Image.Image:
    """Warp pinky dirty-plate look onto this nail. Finger pixels stay put.

    Matches pinky_clean_dark: yellow-tan plate, brown blotches heavier toward
    the free edge, dirt recedes from cuticle to tip as dirt_level drops.
    Specular highlight from the clean still is kept.
    """
    if dirt_level <= 0.02:
        return clean.copy()
    out = np.asarray(clean.convert("RGBA")).copy()
    nail = nail_mask(clean, luma_min=130)
    ref = np.asarray(dirt_ref.convert("RGBA"))
    ref_nail = nail_mask(dirt_ref, luma_min=90)
    if not ref_nail.any():
        lum_r = _luma(ref[..., :3].astype(np.float32))
        ref_nail = (ref[..., 3] > 20) & (lum_r > 55)
    if not nail.any() or not ref_nail.any():
        return clean.copy()
    nys, nxs = np.where(nail)
    rys, rxs = np.where(ref_nail)
    src = ref[rys.min() : rys.max() + 1, rxs.min() : rxs.max() + 1]
    dest_h = int(nys.max() - nys.min() + 1)
    dest_w = int(nxs.max() - nxs.min() + 1)
    patch = np.asarray(
        Image.fromarray(src, "RGBA").resize((dest_w, dest_h), Image.LANCZOS)
    ).astype(np.float32)
    y0, x0 = int(nys.min()), int(nxs.min())
    region = nail[y0 : y0 + dest_h, x0 : x0 + dest_w]
    base = out[y0 : y0 + dest_h, x0 : x0 + dest_w].astype(np.float32)
    amt = float(np.clip(dirt_level, 0, 1))
    # Recede from cuticle (top of plate) toward the downward tip.
    yy = np.linspace(0.0, 1.0, dest_h, dtype=np.float32)[:, None]
    # amt 1.0 → whole plate dirty; 0.62 → lower ~70%; 0.28 → tip blotches only.
    recede = np.clip((yy - (1.0 - amt) * 0.72) / max(0.18, amt * 0.55), 0.0, 1.0)
    cover = recede * region.astype(np.float32) * (0.82 + 0.18 * amt)
    lum_c = _luma(base[..., :3])
    spec = np.clip((lum_c - 188.0) / 48.0, 0.0, 1.0) * region.astype(np.float32)
    mix_w = np.clip(cover * (1.0 - spec * 0.85), 0.0, 1.0)[..., None]
    dirt = patch[..., :3]
    mix = base.copy()
    mix[..., :3] = np.where(
        region[..., None],
        base[..., :3] * (1.0 - mix_w) + dirt * mix_w,
        base[..., :3],
    )
    out[y0 : y0 + dest_h, x0 : x0 + dest_w] = np.clip(mix, 0, 255).astype(np.uint8)
    return Image.fromarray(out, "RGBA")


def _key_navy_or_dark(image: Image.Image) -> Image.Image:
    """Drop solid dark/navy studio fills from a dirt reference crop."""
    arr = np.asarray(image.convert("RGBA")).copy()
    rgb = arr[..., :3].astype(np.float32)
    lum = _luma(rgb)
    # Navy / near-black field around the nail tip crop.
    dark = lum < 55
    arr[dark, 3] = 0
    return Image.fromarray(arr, "RGBA")


def stain_nail_speckle(
    clean: Image.Image,
    dirt_level: float,
    dirt_texture: Image.Image,
) -> Image.Image:
    """Mottled tip/edge speckles like the approved ring dirt still."""
    if dirt_level <= 0.02:
        return clean.copy()
    out = np.asarray(clean.convert("RGBA")).copy()
    nail = nail_mask(clean, luma_min=130)
    if not nail.any():
        return clean.copy()
    tex = _key_navy_or_dark(dirt_texture.convert("RGBA"))
    ta = np.asarray(tex)
    lum_t = _luma(ta[..., :3].astype(np.float32))
    t_op = (ta[..., 3] > 20) | (lum_t > 40)
    if not t_op.any():
        return clean.copy()
    tys, txs = np.where(t_op)
    patch = Image.fromarray(ta).crop(
        (int(txs.min()), int(tys.min()), int(txs.max()) + 1, int(tys.max()) + 1)
    )
    nys, nxs = np.where(nail)
    y0, y1 = int(nys.min()), int(nys.max()) + 1
    x0, x1 = int(nxs.min()), int(nxs.max()) + 1
    dest_h, dest_w = y1 - y0, x1 - x0
    warped = np.asarray(patch.resize((dest_w, dest_h), Image.LANCZOS).convert("RGBA")).astype(
        np.float32
    )
    base = out[y0:y1, x0:x1].astype(np.float32)
    region = nail[y0:y1, x0:x1]
    amt = float(np.clip(dirt_level, 0, 1))
    yy = np.linspace(0.35, 1.0, dest_h, dtype=np.float32)[:, None]
    xx = np.linspace(-1.0, 1.0, dest_w, dtype=np.float32)[None, :]
    pale = base[..., :3].copy()
    tex_lum = _luma(warped[..., :3])
    # Map only the dark grains from the reference onto the pale plate.
    grain = np.clip((155.0 - tex_lum) / 110.0, 0.0, 1.0)
    tip_w = 0.55 + 0.45 * yy
    side_w = 0.75 + 0.25 * np.abs(xx)
    cover = np.clip(grain * tip_w * side_w * (0.55 + 0.45 * amt), 0, 1) * region
    speck_col = np.array([58.0, 38.0, 26.0], dtype=np.float32)
    mid_col = np.array([118.0, 92.0, 68.0], dtype=np.float32)
    dirt = speck_col[None, None, :] * cover[..., None] + mid_col[None, None, :] * (
        (1.0 - cover)[..., None] * 0.35 * amt * region[..., None]
    )
    blend_w = np.clip(cover * (0.75 + 0.25 * amt) + 0.18 * amt * tip_w * region, 0, 1)[
        ..., None
    ]
    blended = pale * (1.0 - blend_w) + dirt * blend_w
    rng = np.random.default_rng(42)
    noise = rng.random((dest_h, dest_w), dtype=np.float32)
    dens = (0.22 + 0.55 * yy[:, 0][:, None] + 0.12 * np.abs(xx)) * amt
    dots = region & (noise < dens)
    blended[dots] = blended[dots] * (1.0 - 0.88 * amt) + speck_col * (0.88 * amt)
    out[y0:y1, x0:x1, :3] = np.where(
        region[..., None], np.clip(blended, 0, 255), base[..., :3]
    )
    return Image.fromarray(out, "RGBA")


def preview_strip(strip: Image.Image, dest: Path, bg: tuple[int, int, int] = (255, 182, 193)) -> None:
    canvas = Image.new("RGBA", strip.size, (*bg, 255))
    canvas.alpha_composite(strip.convert("RGBA"))
    dest.parent.mkdir(parents=True, exist_ok=True)
    canvas.convert("RGB").save(dest)


def _content_center_x(cell: Image.Image) -> float:
    op = np.asarray(cell.convert("RGBA"))[..., 3] > 8
    if not op.any():
        return cell.width / 2.0
    xs = np.where(op)[1]
    return float(xs.mean())


def widen_cell(cell: Image.Image, sx: float, center_x: float) -> Image.Image:
    """Scale a locked pose horizontally around [center_x]. Height stays put."""
    width, height = cell.size
    nw = max(1, int(round(width * sx)))
    scaled = cell.resize((nw, height), Image.LANCZOS)
    canvas = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    paste_x = int(round(center_x - center_x * sx))
    canvas.paste(scaled, (paste_x, 0), scaled)
    return canvas


def widen_strip(src: Path, dest: Path, sx: float, center_x: float) -> None:
    cells = even_cells(Image.open(src))
    pack_strip([widen_cell(cell, sx, center_x) for cell in cells], dest)


def copy_pinky_to_thin_digits() -> dict[str, tuple[int, int, int, int]]:
    """Ring / middle / index reuse the approved pinky sheets."""
    plate = plate_region(Image.open(IMAGES / "pinky_nail_mask_dark.png"))
    for stem in ("ring", "middle", "index"):
        for suffix in ("clean_dark.png", "short_dark.png", "nail_mask_dark.png"):
            src = IMAGES / f"pinky_{suffix}"
            dest = IMAGES / f"{stem}_{suffix}"
            Image.open(src).save(dest)
        REVIEW.mkdir(parents=True, exist_ok=True)
        Image.open(IMAGES / f"{stem}_clean_dark.png").save(REVIEW / f"{stem}_clean_dark.png")
        Image.open(IMAGES / f"{stem}_short_dark.png").save(REVIEW / f"{stem}_short_dark.png")
        Image.open(IMAGES / f"{stem}_nail_mask_dark.png").save(REVIEW / f"{stem}_nail_mask_dark.png")
        preview_strip(Image.open(IMAGES / f"{stem}_clean_dark.png"), REVIEW / f"preview_{stem}_clean.jpg")
        preview_strip(Image.open(IMAGES / f"{stem}_short_dark.png"), REVIEW / f"preview_{stem}_short.jpg")
        print(stem, "reuses pinky", "plate", plate)
    return {stem: plate for stem in ("ring", "middle", "index")}


def build_thumb_from_pinky(sx: float = 1.28) -> dict[str, tuple[int, int, int, int]]:
    """Wider locked pose of the approved pinky — same clip, dirt, and mask."""
    clean_cells = even_cells(Image.open(IMAGES / "pinky_clean_dark.png"))
    center_x = _content_center_x(clean_cells[-1])
    widen_strip(IMAGES / "pinky_clean_dark.png", IMAGES / "thumb_clean_dark.png", sx, center_x)
    widen_strip(IMAGES / "pinky_short_dark.png", IMAGES / "thumb_short_dark.png", sx, center_x)
    mask = widen_cell(Image.open(IMAGES / "pinky_nail_mask_dark.png"), sx, center_x)
    mask.save(IMAGES / "thumb_nail_mask_dark.png")
    plate = plate_region(mask)
    REVIEW.mkdir(parents=True, exist_ok=True)
    Image.open(IMAGES / "thumb_clean_dark.png").save(REVIEW / "thumb_clean_dark.png")
    Image.open(IMAGES / "thumb_short_dark.png").save(REVIEW / "thumb_short_dark.png")
    mask.save(REVIEW / "thumb_nail_mask_dark.png")
    preview_strip(Image.open(IMAGES / "thumb_clean_dark.png"), REVIEW / "preview_thumb_clean.jpg")
    preview_strip(Image.open(IMAGES / "thumb_short_dark.png"), REVIEW / "preview_thumb_short.jpg")
    short_last = even_cells(Image.open(IMAGES / "thumb_short_dark.png"))[-1]
    overlay = Image.new("RGBA", short_last.size, (255, 70, 140, 0))
    overlay.putalpha(mask.split()[-1].point(lambda v: int(v * 0.92)))
    Image.alpha_composite(short_last, overlay).save(REVIEW / "preview_thumb_polish.png")
    print("thumb from pinky", "sx", sx, "plate", plate)
    return {"thumb": plate}


def _feather_nail_alpha(keep: np.ndarray) -> np.ndarray:
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
    """Bright nail plates on Zeynep's finished hand, for polish-colored reveal."""
    from pack_zeynep_customer import _key_auto

    src = IMAGES / "final_hand_dark.png"
    keyed = _key_auto(Image.open(src).convert("RGBA"))
    arr = np.asarray(keyed)
    rgb = arr[..., :3].astype(np.float32)
    lum = _luma(rgb)
    finger = arr[..., 3] > 8
    bright = finger & (lum >= 125)
    h, w = bright.shape
    seen = np.zeros((h, w), dtype=bool)
    blobs: list[np.ndarray] = []
    ys, xs = np.where(bright)
    for y, x in zip(ys, xs):
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
        if len(pixels) < 5000:
            continue
        pts = np.array(pixels)
        if float(pts[:, 1].mean()) < 500:
            continue
        blob = np.zeros((h, w), dtype=bool)
        blob[pts[:, 1], pts[:, 0]] = True
        blobs.append(blob)
    blobs.sort(key=lambda b: int(np.where(b)[1].mean()))
    blobs = blobs[:5]
    # Left → right on the dorsal still: pinky, ring, middle, index, thumb.
    stems = ("pinky", "ring", "middle", "pointer", "thumb")
    keep = np.zeros((h, w), dtype=bool)
    for blob, stem in zip(blobs, stems):
        keep |= blob
        digit_mask = _rgba_mask(_feather_nail_alpha(blob))
        digit_mask.save(IMAGES / f"final_hand_dark_nail_{stem}.png")
        print("final nail", stem, "cx", round(float(np.where(blob)[1].mean()), 1))
    dest = IMAGES / "final_hand_dark_nail_mask.png"
    _rgba_mask(_feather_nail_alpha(keep)).save(dest)
    REVIEW.mkdir(parents=True, exist_ok=True)
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
    print("final hand nails", int(keep.sum()), "digits", len(blobs))
    return dest


def build_pinky() -> dict[str, tuple[int, int, int, int]]:
    pinky = Image.open(IMAGES / "pinky_clean_dark.png")
    cells = even_cells(pinky)
    clean = cells[-1]
    short_frames = [clip_left_to_right(clean, stage) for stage in range(4)]
    pack_strip(short_frames, IMAGES / "pinky_short_dark.png")
    nail0 = nail_mask(clean, luma_min=130)
    mask = polish_mask_from_nail(clipped_nail_mask(nail0, 3), short_frames[-1])
    mask.save(IMAGES / "pinky_nail_mask_dark.png")
    plate = plate_region(mask)
    REVIEW.mkdir(parents=True, exist_ok=True)
    pack_strip(short_frames, REVIEW / "pinky_short_dark.png")
    mask.save(REVIEW / "pinky_nail_mask_dark.png")
    preview_strip(Image.open(IMAGES / "pinky_short_dark.png"), REVIEW / "preview_pinky_short.jpg")
    preview_strip(
        Image.open(IMAGES / "pinky_clean_dark.png"),
        REVIEW / "preview_pinky_clean.jpg",
    )
    overlay = Image.new("RGBA", short_frames[-1].size, (255, 70, 140, 0))
    overlay.putalpha(mask.split()[-1].point(lambda v: int(v * 0.92)))
    Image.alpha_composite(short_frames[-1], overlay).save(REVIEW / "preview_pinky_polish.png")
    last = short_frames[-1]
    nys, nxs = np.where(nail_mask(last))
    tip_box = (
        max(0, int(nxs.min()) - 28),
        max(0, int(nys.max()) - 110),
        min(last.width, int(nxs.max()) + 28),
        min(last.height, int(nys.max()) + 18),
    )
    preview_strip(last.crop(tip_box), REVIEW / "preview_pinky_short_tip.jpg")
    print("pinky short", short_frames[0].size, "plate", plate)
    # lock check: finger pixels outside nail identical across short frames
    master = np.asarray(clean)
    nail0 = nail_mask(clean)
    for i, frame in enumerate(short_frames[1:], start=1):
        diff = np.abs(np.asarray(frame).astype(np.int16) - master.astype(np.int16))
        outside = ~nail0
        outside[: int(np.flatnonzero(nail0.any(axis=1))[0]) + 4] = True
        # Ignore the original free-edge band we intentionally clipped.
        below_cut = np.arange(master.shape[0])[:, None] > int(
            np.flatnonzero(nail0.any(axis=1))[0]
            + (np.flatnonzero(nail0.any(axis=1))[-1] - np.flatnonzero(nail0.any(axis=1))[0])
            * 0.5
        )
        check = outside & ~below_cut
        assert float(diff[check].mean()) < 1.5, f"pinky frame {i} moved the finger"
    return {"pinky": plate}


def build_from_still(
    still: Image.Image,
    stem: str,
    dirt_refs: list[Image.Image],
    *,
    write_assets: bool = False,
    dirt_texture: Image.Image | None = None,
) -> dict[str, tuple[int, int, int, int]]:
    from pack_zeynep_customer import _key_auto, _crop_to_content

    keyed = _crop_to_content(_key_auto(still.convert("RGBA")))
    cell = fit_finger_cell(keyed)
    # Same 4-step recede as pinky_clean_dark: dirty plate → tip blotches → clean.
    levels = (1.0, 0.62, 0.28, 0.0)
    clean_frames = [
        stain_nail(cell, level, dirt_refs[min(i, len(dirt_refs) - 1)])
        for i, level in enumerate(levels)
    ]
    # Last frame is the approved clean still itself.
    clean_frames[-1] = cell.copy()
    short_frames = [clip_left_to_right(cell, stage) for stage in range(4)]
    nail0 = nail_mask(cell, luma_min=130)
    mask = polish_mask_from_nail(clipped_nail_mask(nail0, 3), short_frames[-1])
    REVIEW.mkdir(parents=True, exist_ok=True)
    pack_strip(clean_frames, REVIEW / f"{stem}_clean_dark.png")
    pack_strip(short_frames, REVIEW / f"{stem}_short_dark.png")
    mask.save(REVIEW / f"{stem}_nail_mask_dark.png")
    if write_assets:
        pack_strip(clean_frames, IMAGES / f"{stem}_clean_dark.png")
        pack_strip(short_frames, IMAGES / f"{stem}_short_dark.png")
        mask.save(IMAGES / f"{stem}_nail_mask_dark.png")
    preview_strip(Image.open(REVIEW / f"{stem}_clean_dark.png"), REVIEW / f"preview_{stem}_clean.jpg")
    preview_strip(Image.open(REVIEW / f"{stem}_short_dark.png"), REVIEW / f"preview_{stem}_short.jpg")
    overlay = Image.new("RGBA", short_frames[-1].size, (255, 70, 140, 0))
    overlay.putalpha(mask.split()[-1].point(lambda v: int(v * 0.92)))
    Image.alpha_composite(short_frames[-1], overlay).save(REVIEW / f"preview_{stem}_polish.png")
    # Final hand reminder preview (already in game assets).
    if (IMAGES / "final_hand_dark.png").exists():
        preview_strip(
            Image.open(IMAGES / "final_hand_dark.png"),
            REVIEW / "preview_final_hand_dark.jpg",
        )
    plate = plate_region(mask)
    print(stem, "cell", cell.size, "plate", plate, "corner alpha", int(np.asarray(cell)[0, 0, 3]))
    master = np.asarray(cell)
    for i, frame in enumerate(clean_frames[:-1]):
        diff = np.abs(np.asarray(frame).astype(np.int16) - master.astype(np.int16))
        outside = ~nail0
        # Ignore a thin halo around the plate where stain sampling can bleed 1px.
        halo = Image.fromarray(nail0.astype(np.uint8) * 255, "L").filter(
            ImageFilter.MaxFilter(5)
        )
        outside = outside & (np.asarray(halo) < 127)
        assert float(diff[outside].mean()) < 2.0, f"{stem} clean {i} moved the finger"
    for i, frame in enumerate(short_frames[1:], start=1):
        diff = np.abs(np.asarray(frame).astype(np.int16) - master.astype(np.int16))
        outside = ~nail0
        tip0 = int(np.flatnonzero(nail0.any(axis=1))[0])
        tip1 = int(np.flatnonzero(nail0.any(axis=1))[-1])
        below_cut = np.arange(master.shape[0])[:, None] > tip0 + (tip1 - tip0) * 0.45
        # Finger must stay put; only original nail tip may change.
        check = outside & ~below_cut
        check[: tip0 + 4] = False
        assert float(diff[check].mean()) < 1.5, f"{stem} short {i} moved the finger"
        finger_lost = int(
            ((master[..., 3] > 8) & (np.asarray(frame)[..., 3] < 8) & outside).sum()
        )
        assert finger_lost < 200, f"{stem} short {i} clipped the finger ({finger_lost}px)"
    return {stem: plate}


def build_ring() -> dict[str, tuple[int, int, int, int]]:
    still_paths = [
        Path(r"C:\Users\Ezgi\.cursor\projects\c-Users-Ezgi-Documents-GitHub-nailGlam\assets\zeynep_ring_finger_still_v3.png"),
        REVIEW / "ring_clean_still_dark.png",
        REVIEW / "zeynep_ring_finger_still_v3.png",
    ]
    still = None
    for path in still_paths:
        if path.exists():
            still = Image.open(path)
            print("ring still", path)
            break
    if still is None:
        raise FileNotFoundError("approved ring still not found")
    dirt = even_cells(Image.open(IMAGES / "pinky_clean_dark.png"))
    return build_from_still(
        still,
        "ring",
        dirt,
        write_assets=True,
    )


def build_middle() -> dict[str, tuple[int, int, int, int]]:
    still_paths = [
        Path(r"C:\Users\Ezgi\.cursor\projects\c-Users-Ezgi-Documents-GitHub-nailGlam\assets\zeynep_middle_finger_still_v2.png"),
        REVIEW / "middle_clean_still_dark.png",
        REVIEW / "zeynep_middle_finger_still_v2.png",
    ]
    still = None
    for path in still_paths:
        if path.exists():
            still = Image.open(path)
            print("middle still", path)
            break
    if still is None:
        raise FileNotFoundError("middle finger still not found")
    dirt = even_cells(Image.open(IMAGES / "pinky_clean_dark.png"))
    return build_from_still(
        still,
        "middle",
        dirt,
        write_assets=True,
    )


def build_index() -> dict[str, tuple[int, int, int, int]]:
    still_paths = [
        Path(r"C:\Users\Ezgi\.cursor\projects\c-Users-Ezgi-Documents-GitHub-nailGlam\assets\zeynep_index_finger_still_v1.png"),
        REVIEW / "index_clean_still_dark.png",
        REVIEW / "zeynep_index_finger_still_v1.png",
    ]
    still = None
    for path in still_paths:
        if path.exists():
            still = Image.open(path)
            print("index still", path)
            break
    if still is None:
        raise FileNotFoundError("index finger still not found")
    dirt = even_cells(Image.open(IMAGES / "pinky_clean_dark.png"))
    return build_from_still(
        still,
        "index",
        dirt,
        write_assets=True,
    )


def build_thumb() -> dict[str, tuple[int, int, int, int]]:
    still_paths = [
        Path(r"C:\Users\Ezgi\.cursor\projects\c-Users-Ezgi-Documents-GitHub-nailGlam\assets\zeynep_thumb_still_v2.png"),
        REVIEW / "thumb_clean_still_dark.png",
        REVIEW / "zeynep_thumb_still_v2.png",
    ]
    still = None
    for path in still_paths:
        if path.exists():
            still = Image.open(path)
            print("thumb still", path)
            break
    if still is None:
        raise FileNotFoundError("thumb still not found")
    dirt = even_cells(Image.open(IMAGES / "pinky_clean_dark.png"))
    return build_from_still(
        still,
        "thumb",
        dirt,
        write_assets=True,
    )


def main() -> None:
    plates = {}
    if "--pinky" in sys.argv or "--all" in sys.argv:
        plates.update(build_pinky())
    if "--share-pinky" in sys.argv or "--all" in sys.argv or len(sys.argv) == 1:
        plates.update(copy_pinky_to_thin_digits())
        plates.update(build_thumb_from_pinky())
        build_final_hand_nail_mask()
    if "--ring" in sys.argv:
        plates.update(build_ring())
    if "--middle" in sys.argv:
        plates.update(build_middle())
    if "--index" in sys.argv:
        plates.update(build_index())
    if "--thumb-still" in sys.argv:
        plates.update(build_thumb())
    print("plates", plates)


if __name__ == "__main__":
    main()
