"""Build review polish art: keyed bottles/brush + a nail-plate mask.

Does not touch assets/images. Writes to tool/_review_polish only.
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "tool"))
from key_generated_art import _key  # noqa: E402

SRC_DIR = Path(
    r"C:\Users\Ezgi\.cursor\projects\c-Users-Ezgi-Documents-GitHub-nailGlam\assets"
)
OUT = REPO / "tool" / "_review_polish"
SHORT = REPO / "assets" / "images" / "short_nail.png"


def key_props() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for name in (
        "polish_brush.png",
        "polish_blush.png",
        "polish_red.png",
        "polish_nude.png",
        "polish_pearl.png",
        "polish_gold.png",
    ):
        keyed = _key(Image.open(SRC_DIR / name))
        keyed = keyed.crop(keyed.getbbox())
        keyed.save(OUT / name)
        print(f"{name}: {keyed.size[0]}x{keyed.size[1]}")


def last_short_frame() -> Image.Image:
    sheet = Image.open(SHORT).convert("RGBA")
    return sheet.crop((1152, 0, 1536, 1024))


def nail_mask(frame: Image.Image) -> Image.Image:
    """Full nail plate between the inner left/right folds, tip to cuticle."""
    arr = np.asarray(frame)
    rgb = arr[..., :3].astype(np.float32)
    alpha = arr[..., 3]
    opaque = alpha > 10
    lum = 0.21 * rgb[..., 0] + 0.72 * rgb[..., 1] + 0.07 * rgb[..., 2]
    h, w = lum.shape
    ys, _ = np.where(opaque)
    tip_y = int(ys.max())
    cx = w // 2
    wall = opaque & (lum < 128)
    keep = np.zeros((h, w), dtype=bool)

    for y in range(tip_y, 340, -1):
        xs = np.where(opaque[y])[0]
        if xs.size < 8:
            continue
        # Near the free edge the plate IS the silhouette.
        if xs.size < 52:
            keep[y, xs[0] + 1 : xs[-1]] = True
            continue
        left_walls = np.where(wall[y, :cx])[0]
        right_walls = np.where(wall[y, cx:])[0]
        if left_walls.size == 0 or right_walls.size == 0:
            if keep.any():
                break
            continue
        left_fold = int(left_walls[-1])
        right_fold = int(cx + right_walls[0])
        finger_w = int(xs[-1] - xs[0])
        # Knuckle crease runs through the center — only test once the finger is wide.
        if finger_w > 220 and (left_fold > cx - 36 or right_fold < cx + 36):
            break
        if right_fold - left_fold < 40:
            if keep.any() and finger_w > 180:
                break
            continue
        keep[y, left_fold + 1 : right_fold] = True

    rows = np.where(keep.any(axis=1))[0]
    if rows.size:
        left = np.array(
            [np.where(keep[y])[0][0] for y in rows], dtype=np.float32
        )
        right = np.array(
            [np.where(keep[y])[0][-1] for y in rows], dtype=np.float32
        )
        left = _smooth_1d(left, 13)
        right = _smooth_1d(right, 13)
        keep[:, :] = False
        for i, y in enumerate(rows):
            x0 = int(np.clip(np.floor(left[i]), 0, w - 1))
            x1 = int(np.clip(np.ceil(right[i]), 0, w - 1))
            if x1 > x0:
                keep[int(y), x0 : x1 + 1] = True

    mask = Image.fromarray((keep * 255).astype(np.uint8), "L")
    mask = (
        mask.filter(ImageFilter.MaxFilter(3))
        .filter(ImageFilter.MinFilter(3))
        .filter(ImageFilter.GaussianBlur(0.7))
    )
    m = np.asarray(mask)
    out = np.zeros((h, w, 4), dtype=np.uint8)
    out[..., 0:3] = 255
    out[..., 3] = np.where(m > 40, 255, 0)
    return Image.fromarray(out, "RGBA")


def _longest_run(row: np.ndarray) -> tuple[int, int] | None:
    best: tuple[int, int] | None = None
    start = None
    for i, on in enumerate(row.tolist() + [False]):
        if on and start is None:
            start = i
        elif not on and start is not None:
            span = (start, i - 1)
            if best is None or span[1] - span[0] > best[1] - best[0]:
                best = span
            start = None
    return best


def _smooth_1d(values: np.ndarray, radius: int) -> np.ndarray:
    if values.size == 0:
        return values
    padded = np.pad(values, (radius, radius), mode="edge")
    kernel = np.ones(radius * 2 + 1, dtype=np.float32) / (radius * 2 + 1)
    return np.convolve(padded, kernel, mode="valid")


def previews(frame: Image.Image, mask: Image.Image) -> None:
    frame.save(OUT / "short_nail_last_frame.png")
    mask.save(OUT / "Pink_nail_mask.png")
    mask.save(OUT / "pinky_nail_mask.png")

    # Layer 1: polish color clipped to the mask, same canvas as the finger.
    polish = Image.new("RGBA", frame.size, (255, 107, 168, 255))
    polish.putalpha(mask.split()[-1])
    polish.save(OUT / "Pink_nail_mask_tinted.png")

    stacked = Image.alpha_composite(frame, polish)
    stacked.save(OUT / "preview_layers.png")
    # Tight crop so the plate is easy to judge.
    box = mask.getbbox()
    if box is not None:
        pad = 24
        box = (
            max(0, box[0] - pad),
            max(0, box[1] - pad),
            min(frame.size[0], box[2] + pad),
            min(frame.size[1], box[3] + pad),
        )
        stacked.crop(box).save(OUT / "preview_layers_zoom.png")
        mask.crop(box).save(OUT / "Pink_nail_mask_zoom.png")

    cursor_assets = Path(
        r"C:\Users\Ezgi\.cursor\projects\c-Users-Ezgi-Documents-GitHub-nailGlam\assets"
    )
    if cursor_assets.is_dir():
        mask.save(cursor_assets / "Pink_nail_mask.png")
        stacked.save(cursor_assets / "preview_layers.png")

    print("mask opaque px", int((np.asarray(mask)[..., 3] > 20).sum()))


def main() -> int:
    OUT.mkdir(parents=True, exist_ok=True)
    if not (OUT / "polish_brush.png").exists():
        key_props()
    frame = last_short_frame()
    mask = nail_mask(frame)
    previews(frame, mask)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
