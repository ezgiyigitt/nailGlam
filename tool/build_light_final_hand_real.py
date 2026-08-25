"""Realistic fair-hand reveal + per-digit polish masks from approved art.

Uses the same nail-plate logic as finger close-ups. Output fits 833×1446.
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "tool"))
from make_zeynep_nail_sheets import (  # noqa: E402
    _feather_nail_alpha,
    _fill_interior_gaps,
    _luma,
)
from pack_zeynep_customer import _crop_to_content, _key_auto  # noqa: E402

IMAGES = REPO / "assets" / "images"
REVIEW = REPO / "tool" / "review_light_nails" / "approval"
CURSOR = Path(
    r"C:\Users\Ezgi\.cursor\projects\c-Users-Ezgi-Documents-GitHub-nailGlam\assets"
)
SRC = CURSOR / "final_hand_light_gen.png"
CANVAS = (833, 1446)
STEMS = ("pinky", "ring", "middle", "pointer", "thumb")


def _rgba_mask(alpha: np.ndarray) -> Image.Image:
    feather = Image.fromarray(alpha.astype(np.uint8) * 255, "L").filter(
        ImageFilter.GaussianBlur(1.4)
    )
    a = np.asarray(feather).astype(np.uint8)
    out = np.zeros((*a.shape, 4), dtype=np.uint8)
    out[..., :3] = 255
    out[..., 3] = np.where(a > 10, a, 0)
    return Image.fromarray(out, "RGBA")


def _fit_canvas(keyed: Image.Image, size: tuple[int, int] = CANVAS) -> Image.Image:
    cw, ch = size
    crop = _crop_to_content(keyed)
    scale = min((cw - 24) / crop.width, (ch - 24) / crop.height)
    nw = max(1, round(crop.width * scale))
    nh = max(1, round(crop.height * scale))
    scaled = crop.resize((nw, nh), Image.LANCZOS)
    canvas = Image.new("RGBA", size, (0, 0, 0, 0))
    x = (cw - nw) // 2
    y = ch - nh - 12
    canvas.alpha_composite(scaled, (x, y))
    return canvas


def _flood_blobs(mask: np.ndarray, min_px: int, max_px: int) -> list[np.ndarray]:
    h, w = mask.shape
    seen = np.zeros((h, w), dtype=bool)
    blobs: list[np.ndarray] = []
    ys, xs = np.where(mask)
    for y, x in zip(ys, xs):
        if seen[y, x]:
            continue
        stack = [(int(x), int(y))]
        pixels: list[tuple[int, int]] = []
        while stack:
            cx, cy = stack.pop()
            if cx < 0 or cy < 0 or cx >= w or cy >= h or seen[cy, cx] or not mask[cy, cx]:
                continue
            seen[cy, cx] = True
            pixels.append((cx, cy))
            stack.extend(((cx - 1, cy), (cx + 1, cy), (cx, cy - 1), (cx, cy + 1)))
        if not (min_px <= len(pixels) <= max_px):
            continue
        blob = np.zeros((h, w), dtype=bool)
        pts = np.array(pixels)
        blob[pts[:, 1], pts[:, 0]] = True
        blobs.append(blob)
    return blobs


def _nail_plates(arr: np.ndarray) -> list[np.ndarray]:
    finger = arr[..., 3] > 10
    rgb = arr[..., :3].astype(np.float32)
    lum = _luma(rgb)
    warm = rgb[..., 1] - rgb[..., 2]
    chroma = np.max(rgb, axis=2) - np.min(rgb, axis=2)
    ys, xs = np.where(finger)
    if ys.size == 0:
        raise RuntimeError("no hand pixels")
    y0, y1 = int(ys.min()), int(ys.max())
    x0, x1 = int(xs.min()), int(xs.max())
    span = max(1, y1 - y0)
    distal = np.zeros(finger.shape, dtype=bool)
    distal[y0 : y0 + int(span * 0.58)] = True
    skin = float(np.median(lum[finger & ~distal])) if (finger & ~distal).any() else 140.0
    enamel = (
        finger
        & distal
        & (lum >= max(skin + 10, 168))
        & (warm <= 30)
        & (chroma <= 95)
    )
    enamel |= finger & distal & (lum >= 215) & (chroma <= 55)
    blobs = _flood_blobs(enamel, min_px=600, max_px=45000)
    if len(blobs) < 5:
        enamel2 = finger & distal & (lum >= max(skin + 4, 155))
        blobs = _flood_blobs(enamel2, min_px=400, max_px=50000)
    if len(blobs) < 5:
        raise RuntimeError(f"only found {len(blobs)} nail blobs")
    blobs.sort(key=lambda b: float(np.where(b)[1].mean()))
    if len(blobs) > 5:
        # Keep five widest nail plates (drop specular crumbs).
        blobs.sort(key=lambda b: int(b.sum()), reverse=True)
        blobs = blobs[:5]
        blobs.sort(key=lambda b: float(np.where(b)[1].mean()))
    refined: list[np.ndarray] = []
    for blob in blobs:
        closed = (
            Image.fromarray(blob.astype(np.uint8) * 255, "L")
            .filter(ImageFilter.MaxFilter(5))
            .filter(ImageFilter.MinFilter(3))
        )
        plate = (np.asarray(closed) > 127) & finger
        plate = _fill_interior_gaps(plate, max_gap=14)
        refined.append(plate)
    return refined


def _preview_multicolor(hand: Image.Image, masks: dict[str, Image.Image]) -> Image.Image:
    preview = hand.copy()
    colors = {
        "pinky": (255, 107, 168),
        "ring": (208, 18, 58),
        "middle": (230, 184, 162),
        "pointer": (155, 90, 182),
        "thumb": (212, 160, 23),
    }
    for stem, rgb in colors.items():
        layer = Image.new("RGBA", hand.size, (*rgb, 0))
        alpha = masks[stem].split()[-1].point(lambda v: int(v * 0.92))
        layer.putalpha(alpha)
        # Color blend like in-game: tint then keep hand gloss via softLight pass
        tinted = Image.new("RGBA", hand.size, (*rgb, 0))
        tinted.putalpha(alpha)
        preview = Image.alpha_composite(preview, tinted)
        gloss = hand.copy()
        gloss.putalpha(alpha)
        preview = Image.alpha_composite(
            preview,
            Image.merge(
                "RGBA",
                (
                    gloss.split()[0],
                    gloss.split()[1],
                    gloss.split()[2],
                    alpha.point(lambda v: int(v * 0.35)),
                ),
            ),
        )
    bg = Image.new("RGBA", hand.size, (255, 182, 193, 255))
    bg.alpha_composite(preview)
    return bg.convert("RGB")


def _align_preview(hand: Image.Image, masks: dict[str, Image.Image]) -> Image.Image:
    bg = Image.new("RGBA", hand.size, (255, 182, 193, 255))
    bg.alpha_composite(hand)
    ov = np.zeros((*hand.size[::-1], 4), dtype=np.uint8)
    for i, stem in enumerate(STEMS):
        m = np.asarray(masks[stem])[..., 3] > 40
        hue = (40 + i * 45) % 255
        ov[m] = (60, 180 + hue // 3, 90, 170)
    bg = Image.alpha_composite(bg, Image.fromarray(ov, "RGBA"))
    return bg.convert("RGB")


def main() -> None:
    if not SRC.exists():
        raise FileNotFoundError(SRC)
    hand = _fit_canvas(_key_auto(Image.open(SRC).convert("RGBA")))
    hand.save(IMAGES / "final_hand_light.png")
    arr = np.asarray(hand)
    plates = _nail_plates(arr)
    masks: dict[str, Image.Image] = {}
    combined = np.zeros(arr.shape[:2], dtype=bool)
    for stem, plate in zip(STEMS, plates, strict=True):
        combined |= plate
        masks[stem] = _rgba_mask(_feather_nail_alpha(plate))
        masks[stem].save(IMAGES / f"final_hand_light_nail_{stem}.png")
        ys, xs = np.where(plate)
        print(
            stem,
            "bbox",
            (int(xs.min()), int(ys.min()), int(xs.max()), int(ys.max())),
            "px",
            int(plate.sum()),
        )
    _rgba_mask(_feather_nail_alpha(combined)).save(IMAGES / "final_hand_light_nail_mask.png")

    REVIEW.mkdir(parents=True, exist_ok=True)
    _preview_multicolor(hand, masks).save(
        REVIEW / "preview_final_hand_light_multicolor.jpg",
        quality=93,
    )
    _align_preview(hand, masks).save(
        REVIEW / "preview_final_hand_light_mask_align.jpg",
        quality=93,
    )
    print("installed", IMAGES / "final_hand_light.png", hand.size)


if __name__ == "__main__":
    main()
