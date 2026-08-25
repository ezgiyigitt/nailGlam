"""Key Zeynep stills, drop extra people, pack onto Lila's cell sizes.

Walk/turn/sit → 432×433 cells (1728×433).
Emotion → 372×402 cells (1860×402).
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "tool"))
from key_generated_art import _crop_to_content  # noqa: E402

SRC = Path(
    r"C:\Users\Ezgi\.cursor\projects\c-Users-Ezgi-Documents-GitHub-nailGlam\assets"
)
OUT = REPO / "assets" / "images"

CELL_W, CELL_H = 432, 433
EMO_W, EMO_H = 372, 402
PAD = 10
SENTINEL = (1, 254, 2)

# Studio black is luma ~0. Hair is also dark, so a wide RGB flood eats it and
# the holes read as white in-game. Only the near-zero field connected to the
# border is removed; anti-aliased hair rims sit above this floor.
BG_LUMA_MAX = 2.5
# Generator cannot emit alpha; light studio fills key cleanly on dark skin.
LIGHT_LUMA_MIN = 235.0
LIGHT_CHROMA_MAX = 22.0


def _luma(rgb: np.ndarray) -> np.ndarray:
    return (
        0.2126 * rgb[..., 0] + 0.7152 * rgb[..., 1] + 0.0722 * rgb[..., 2]
    )


def _flood_backdrop(backdrop: np.ndarray, fill_thresh: int = 0) -> np.ndarray:
    canvas = Image.fromarray(
        np.stack(
            [np.where(backdrop, 0, 255).astype(np.uint8)] * 3,
            axis=-1,
        )
    )
    width, height = canvas.size
    seeds: list[tuple[int, int]] = []
    for x in range(width):
        seeds.append((x, 0))
        seeds.append((x, height - 1))
    for y in range(height):
        seeds.append((0, y))
        seeds.append((width - 1, y))
    for seed in seeds:
        if canvas.getpixel(seed) == (0, 0, 0):
            ImageDraw.floodfill(canvas, seed, SENTINEL, thresh=fill_thresh)
    return np.all(np.asarray(canvas) == np.array(SENTINEL), axis=-1)


def _apply_alpha(image: Image.Image, filled: np.ndarray) -> Image.Image:
    rgba = np.asarray(image.convert("RGBA"), dtype=np.int32).copy()
    rgba[..., 3] = np.where(filled, 0, 255)
    alpha = Image.fromarray(rgba[..., 3].astype(np.uint8), "L")
    alpha = alpha.filter(ImageFilter.GaussianBlur(0.35))
    rgba[..., 3] = np.asarray(alpha, dtype=np.int32)
    return Image.fromarray(rgba.astype(np.uint8), "RGBA")


def _key_black(image: Image.Image, fill_tolerance: int = 0) -> Image.Image:
    rgb = np.asarray(image.convert("RGB"), dtype=np.float32)
    return _apply_alpha(image, _flood_backdrop(_luma(rgb) < BG_LUMA_MAX))


def _key_light(image: Image.Image) -> Image.Image:
    rgb = np.asarray(image.convert("RGB"), dtype=np.float32)
    luma = _luma(rgb)
    chroma = rgb.max(axis=2) - rgb.min(axis=2)
    backdrop = (luma >= LIGHT_LUMA_MIN) & (chroma <= LIGHT_CHROMA_MAX)
    return _apply_alpha(image, _flood_backdrop(backdrop))


def _key_pink_studio(image: Image.Image) -> Image.Image:
    """Key GenerateImage light-pink (#FFB6C1-ish) studio fills on dark skin."""
    rgb = np.asarray(image.convert("RGB"), dtype=np.float32)
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    luma = _luma(rgb)
    # Studio pink is cool (B>G). Nude nail plates are warm beige (G>B),
    # so they stay even when the field is grainy.
    pink = (r > 190) & (b > g + 6) & (luma > 160)
    closed = Image.fromarray(pink.astype(np.uint8) * 255, "L").filter(
        ImageFilter.MaxFilter(9)
    )
    field = np.asarray(closed) > 127
    return _apply_alpha(image, _flood_backdrop(field, fill_thresh=12))


def _key_auto(image: Image.Image) -> Image.Image:
    rgb = np.asarray(image.convert("RGB"), dtype=np.float32)
    corners = np.array(
        [rgb[0, 0], rgb[0, -1], rgb[-1, 0], rgb[-1, -1]],
        dtype=np.float32,
    )
    corner_luma = float(_luma(corners.reshape(4, 1, 3)).mean())
    cr, cg, cb = corners.mean(axis=0)
    if cr > 200 and cg > 140 and cb > 150 and cr > cg + 10:
        return _key_pink_studio(image)
    if corner_luma > 180:
        return _key_light(image)
    return _key_black(image)


def _column_runs(alpha: np.ndarray) -> list[tuple[int, int]]:
    col = alpha.sum(axis=0).astype(np.int32)
    floor = max(8, int(alpha.shape[0] * 0.015))
    active = col > floor
    runs: list[tuple[int, int]] = []
    start = None
    for i, on in enumerate(active):
        if on and start is None:
            start = i
        elif not on and start is not None:
            runs.append((start, i))
            start = None
    if start is not None:
        runs.append((start, len(active)))
    return runs


def _faces_right_profile(frame: Image.Image) -> bool:
    """True when the brighter face sits on the right of the head (walk right)."""
    rgba = np.asarray(frame)
    alpha = rgba[..., 3] > 12
    rows = np.flatnonzero(alpha.any(axis=1))
    if rows.size == 0:
        return True
    top = int(rows[0])
    band = rgba[top : top + max(8, frame.height // 4)]
    mask = band[..., 3] > 12
    if not mask.any():
        return True
    r = band[..., 0].astype(np.int32)
    b = band[..., 2].astype(np.int32)
    skin = mask & (r > 55) & (r > b + 8)
    all_cols = np.flatnonzero(mask.any(axis=0))
    skin_cols = np.flatnonzero(skin.any(axis=0))
    if all_cols.size == 0:
        return True
    mid = (int(all_cols[0]) + int(all_cols[-1])) / 2
    if skin_cols.size == 0:
        return True
    return float(skin_cols.mean()) >= mid - 4


def _keep_main_person(frame: Image.Image, *, prefer_right_facing: bool = False) -> Image.Image:
    """Keep one person. Walk strips prefer a right-facing profile."""
    alpha = np.asarray(frame.split()[3]) > 12
    if not alpha.any():
        return frame
    runs = _column_runs(alpha)
    if not runs:
        return _crop_to_content(frame)
    col = alpha.sum(axis=0).astype(np.int32)
    pad = 18

    def crop_run(run: tuple[int, int]) -> Image.Image:
        left = max(0, run[0] - pad)
        right = min(frame.width, run[1] + pad)
        return _crop_to_content(frame.crop((left, 0, right, frame.height)))

    if prefer_right_facing:
        scored: list[tuple[int, Image.Image]] = []
        for run in runs:
            crop = crop_run(run)
            if _faces_right_profile(crop):
                scored.append((int(col[run[0] : run[1]].sum()), crop))
        if scored:
            return max(scored, key=lambda item: item[0])[1]
    best = max(runs, key=lambda r: int(col[r[0] : r[1]].sum()))
    return crop_run(best)


def _head_anchor(frame: Image.Image) -> tuple[int, int]:
    alpha = np.asarray(frame.split()[3], dtype=np.int32) > 8
    rows = np.flatnonzero(alpha.any(axis=1))
    top = int(rows[0])
    band = alpha[top : top + max(1, frame.height // 4)]
    cols = np.flatnonzero(band.any(axis=0))
    return int((cols[0] + cols[-1]) // 2), top


def _fit_into_cell(
    frame: Image.Image,
    cell_w: int,
    cell_h: int,
    *,
    head_y_frac: float = 0.12,
) -> Image.Image:
    ax, ay = _head_anchor(frame)
    max_w = cell_w - PAD * 2
    max_h = cell_h - PAD * 2
    scale = min(max_w / frame.width, max_h / frame.height)
    scaled = frame.resize(
        (max(1, round(frame.width * scale)), max(1, round(frame.height * scale))),
        Image.LANCZOS,
    )
    sax = round(ax * scale)
    say = round(ay * scale)
    canvas = Image.new("RGBA", (cell_w, cell_h), (0, 0, 0, 0))
    target_head_y = int(cell_h * head_y_frac)
    x = (cell_w // 2) - sax
    y = target_head_y - say
    if y + scaled.height > cell_h - PAD:
        y = cell_h - PAD - scaled.height
    if y < PAD:
        y = PAD
    if x < PAD:
        x = PAD
    if x + scaled.width > cell_w - PAD:
        x = cell_w - PAD - scaled.width
    canvas.paste(scaled, (x, y), scaled)
    return canvas


def _punch_enclosed_light(frame: Image.Image) -> Image.Image:
    """Drop leftover studio white trapped between legs after the border flood."""
    rgba = np.asarray(frame.convert("RGBA")).copy()
    rgb = rgba[..., :3].astype(np.float32)
    luma = _luma(rgb)
    chroma = rgb.max(axis=2) - rgb.min(axis=2)
    rows = np.arange(rgba.shape[0])[:, None]
    leftover = (
        (rgba[..., 3] > 8)
        & (luma >= LIGHT_LUMA_MIN)
        & (chroma <= LIGHT_CHROMA_MAX)
        & (rows > rgba.shape[0] * 0.4)
    )
    if not leftover.any():
        return frame
    rgba[..., 3] = np.where(leftover, 0, rgba[..., 3])
    return Image.fromarray(rgba, "RGBA")


def _prep(
    path: Path,
    *,
    flip: bool = False,
    prefer_right_facing: bool = False,
) -> Image.Image:
    frame = _crop_to_content(
        _punch_enclosed_light(
            _keep_main_person(
                _key_auto(Image.open(path)),
                prefer_right_facing=prefer_right_facing,
            )
        )
    )
    if flip:
        frame = frame.transpose(Image.FLIP_LEFT_RIGHT)
    return frame


def _fit_locked(
    frame: Image.Image,
    cell_w: int,
    cell_h: int,
    scale: float,
    *,
    head_y_frac: float = 0.12,
) -> Image.Image:
    ax, ay = _head_anchor(frame)
    scaled = frame.resize(
        (max(1, round(frame.width * scale)), max(1, round(frame.height * scale))),
        Image.LANCZOS,
    )
    sax = round(ax * scale)
    say = round(ay * scale)
    canvas = Image.new("RGBA", (cell_w, cell_h), (0, 0, 0, 0))
    x = (cell_w // 2) - sax
    y = int(cell_h * head_y_frac) - say
    canvas.paste(scaled, (x, y), scaled)
    return canvas


def _match_body_height(frames: list[Image.Image]) -> list[Image.Image]:
    """Trim extra calves so full-body stills match waist-up contact frames."""
    if not frames:
        return frames
    target_h = min(frame.height for frame in frames)
    matched: list[Image.Image] = []
    for frame in frames:
        if frame.height <= target_h + 8:
            matched.append(frame)
            continue
        matched.append(frame.crop((0, 0, frame.width, target_h)))
    return matched


def pack_locked_cycle(
    names: list[str],
    cell_w: int,
    cell_h: int,
    out_name: str,
    *,
    head_y_frac: float = 0.12,
    prefer_right_facing: bool = True,
) -> None:
    """Same scale + head lock so the walk does not pop between cells."""
    prepped = _match_body_height(
        [
            _prep(SRC / name, prefer_right_facing=prefer_right_facing)
            for name in names
        ]
    )
    max_w = max(frame.width for frame in prepped)
    max_h = max(frame.height for frame in prepped)
    scale = min((cell_w - PAD * 2) / max_w, (cell_h - PAD * 2) / max_h)
    frames = [
        _fit_locked(frame, cell_w, cell_h, scale, head_y_frac=head_y_frac)
        for frame in prepped
    ]
    strip = Image.new("RGBA", (cell_w * len(frames), cell_h), (0, 0, 0, 0))
    for i, frame in enumerate(frames):
        strip.paste(frame, (i * cell_w, 0), frame)
    OUT.mkdir(parents=True, exist_ok=True)
    dest = OUT / out_name
    strip.save(dest)
    print(
        f"{out_name}: {strip.size[0]}x{strip.size[1]} "
        f"({len(frames)} frames, scale={scale:.3f})"
    )


def pack_stills(
    names: list[str],
    cell_w: int,
    cell_h: int,
    out_name: str,
    *,
    head_y_frac: float = 0.12,
    flip: bool = False,
    prefer_right_facing: bool = False,
) -> None:
    frames = [
        _fit_into_cell(
            _prep(
                SRC / name,
                flip=flip,
                prefer_right_facing=prefer_right_facing,
            ),
            cell_w,
            cell_h,
            head_y_frac=head_y_frac,
        )
        for name in names
    ]
    strip = Image.new("RGBA", (cell_w * len(frames), cell_h), (0, 0, 0, 0))
    for i, frame in enumerate(frames):
        strip.paste(frame, (i * cell_w, 0), frame)
    OUT.mkdir(parents=True, exist_ok=True)
    dest = OUT / out_name
    strip.save(dest)
    print(f"{out_name}: {strip.size[0]}x{strip.size[1]} ({len(frames)} frames)")


def _opaque_window(image: Image.Image) -> tuple[int, int, int, int]:
    alpha = np.asarray(image.split()[3]) > 8
    rows = np.flatnonzero(alpha.any(axis=1))
    cols = np.flatnonzero(alpha.any(axis=0))
    top, bottom = int(rows[0]), int(rows[-1]) + 1
    left, right = int(cols[0]), int(cols[-1]) + 1
    return left, top, right - left, bottom - top


def key_final_hand_dark() -> None:
    source = OUT / "final_hand_dark.png"
    keyed = _key_black(Image.open(source), fill_tolerance=18)
    keyed.save(source)
    x, y, w, h = _opaque_window(keyed)
    print(f"final_hand_dark.png: {keyed.size[0]}x{keyed.size[1]} window=({x},{y},{w},{h})")


def _crop_waist_up(frame: Image.Image) -> Image.Image:
    """Keep hair-to-mid-thigh so the walk matches Lila/Ezgi, not a full-body gait."""
    alpha = np.asarray(frame.split()[3]) > 12
    if not alpha.any():
        return frame
    rows = np.flatnonzero(alpha.any(axis=1))
    cols = np.flatnonzero(alpha.any(axis=0))
    top = int(rows[0])
    left, right = int(cols[0]), int(cols[-1]) + 1
    band_h = 90
    head_cols = np.flatnonzero(alpha[top : top + band_h].any(axis=0))
    if head_cols.size == 0:
        return _crop_to_content(frame)
    head_w = int(head_cols[-1] - head_cols[0] + 1)
    bottom = min(frame.height, top + int(head_w * 3.15))
    pad = 8
    return frame.crop(
        (
            max(0, left - pad),
            max(0, top - pad),
            min(frame.width, right + pad),
            min(frame.height, bottom + pad),
        )
    )


def _bilinear_rgba(src: np.ndarray, map_x: np.ndarray, map_y: np.ndarray) -> np.ndarray:
    height, width = src.shape[:2]
    premul = src.astype(np.float32)
    alpha = premul[..., 3:4] / 255.0
    premul[..., :3] *= alpha
    x0 = np.floor(map_x).astype(np.int32)
    y0 = np.floor(map_y).astype(np.int32)
    x1 = x0 + 1
    y1 = y0 + 1
    wx = (map_x - x0)[..., None]
    wy = (map_y - y0)[..., None]
    valid = (x0 >= 0) & (x1 < width) & (y0 >= 0) & (y1 < height)
    x0c = np.clip(x0, 0, width - 1)
    x1c = np.clip(x1, 0, width - 1)
    y0c = np.clip(y0, 0, height - 1)
    y1c = np.clip(y1, 0, height - 1)

    def at(xs: np.ndarray, ys: np.ndarray) -> np.ndarray:
        return premul[ys, xs]

    out = (
        (1 - wx) * (1 - wy) * at(x0c, y0c)
        + wx * (1 - wy) * at(x1c, y0c)
        + (1 - wx) * wy * at(x0c, y1c)
        + wx * wy * at(x1c, y1c)
    )
    rgb_a = out[..., 3:4]
    rgb = np.zeros_like(out[..., :3])
    np.divide(out[..., :3], np.maximum(rgb_a / 255.0, 1e-6), out=rgb, where=rgb_a > 1)
    out[..., :3] = rgb
    out[~valid] = 0
    return np.clip(out, 0, 255).astype(np.uint8)


def _arm_pendulum(cell: Image.Image, swing: float) -> Image.Image:
    """Lila/Ezgi walk: locked head + chest, only the near arm eases forward/back."""
    if abs(swing) < 0.05:
        return cell.copy()
    src = np.asarray(cell.convert("RGBA"))
    height, width = src.shape[:2]
    yy, xx = np.indices((height, width), dtype=np.float32)
    alpha = src[..., 3] > 8
    mid = alpha[int(height * 0.55)]
    cols = np.flatnonzero(mid)
    center_x = float((int(cols[0]) + int(cols[-1])) / 2) if cols.size else width / 2
    shoulder = height * 0.54
    falloff = np.clip((yy - shoulder) / max(1.0, height - shoulder), 0.0, 1.0) ** 2.4
    side = np.clip((xx - (center_x + 8.0)) / 42.0, 0.0, 1.0)
    map_x = xx - swing * falloff * side
    warped = _bilinear_rgba(src, map_x, yy)
    cut = int(shoulder)
    warped[:cut] = src[:cut]
    return Image.fromarray(warped, "RGBA")


def synthesize_walk_strip(source_name: str = "zeynep_cycle_pass_a.png") -> None:
    """Build a 4-frame walk from one still so the body never pops or shoves."""
    person = _crop_waist_up(
        _prep(SRC / source_name, prefer_right_facing=True)
    )
    master = _fit_into_cell(person, CELL_W, CELL_H, head_y_frac=0.12)
    swings = (14.0, 0.0, -14.0, 0.0)
    frames = [_arm_pendulum(master, swing) for swing in swings]
    strip = Image.new("RGBA", (CELL_W * 4, CELL_H), (0, 0, 0, 0))
    for i, frame in enumerate(frames):
        strip.paste(frame, (i * CELL_W, 0), frame)
    OUT.mkdir(parents=True, exist_ok=True)
    dest = OUT / "customer3_walk.png"
    strip.save(dest)
    arr = np.asarray(strip)
    assert strip.mode == "RGBA"
    assert tuple(arr[0, 0]) == (0, 0, 0, 0)
    cells = [arr[:, i * CELL_W : (i + 1) * CELL_W] for i in range(4)]
    head = slice(0, int(CELL_H * 0.40))
    for i, cell in enumerate(cells[1:], start=1):
        head_diff = np.abs(cell[head].astype(np.int16) - cells[0][head].astype(np.int16))
        assert float(head_diff.mean()) < 0.6, f"head popped on frame {i}"
    opaque = [(cell[..., 3] > 8).sum() for cell in cells]
    spread = (max(opaque) - min(opaque)) / max(opaque)
    assert spread < 0.08, f"silhouette jumped: {opaque}"
    print(
        f"customer3_walk.png: {strip.size[0]}x{strip.size[1]} "
        f"(synthesized pendulum, opaque={opaque})"
    )


def main() -> None:
    synthesize_walk_strip()
    # Profile → front. Skip the over-the-shoulder and "painting nails" stills.
    pack_stills(
        [
            "zeynep_walk_f0.png",
            "zeynep_turn_f1.png",
            "zeynep_turn_f2.png",
            "zeynep_turn_f2.png",
        ],
        CELL_W,
        CELL_H,
        "customer3_turn.png",
    )
    pack_stills(
        [
            "zeynep_turn_f3.png",
            "zeynep_sit_f0.png",
            "zeynep_sit_f0.png",
            "zeynep_sit_f1.png",
        ],
        CELL_W,
        CELL_H,
        "customer3_sit.png",
        head_y_frac=0.12,
    )
    pack_stills(
        [f"zeynep_emo_{i}.png" for i in range(5)],
        EMO_W,
        EMO_H,
        "customer3_emotion.png",
        head_y_frac=0.08,
    )
    key_final_hand_dark()


if __name__ == "__main__":
    main()
