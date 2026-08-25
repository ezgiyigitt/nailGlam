"""Procedural fair-hand reveal still + per-digit polish masks for Lila / Ezgi.

Nails are drawn as flat pale plates so masks are exact — no photo segmentation.
Output: assets/images/final_hand_light.png + final_hand_light_nail_*.png
"""

from __future__ import annotations

import math
import sys
from dataclasses import dataclass
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "tool"))
from make_zeynep_nail_sheets import _fill_interior_gaps  # noqa: E402

IMAGES = REPO / "assets" / "images"
REVIEW = REPO / "tool" / "review_light_nails" / "approval"
CANVAS = (833, 1446)

SKIN = (245, 198, 168)
SKIN_SHADOW = (218, 158, 128)
SKIN_HIGH = (255, 224, 204)
SKIN_BLUSH = (255, 210, 188)
NAIL = (255, 244, 238)
NAIL_SHINE = (255, 255, 255)
OUTLINE = (200, 140, 110)


@dataclass(frozen=True)
class NailSpec:
    digit: str
    cx: float
    cy: float
    rx: float
    ry: float
    angle: float = 0.0


@dataclass(frozen=True)
class FingerSpec:
    base: tuple[float, float]
    tip: tuple[float, float]
    width: float


# Dorsal cartoon hand — nail ovals align exactly with polish masks.
NAILS: tuple[NailSpec, ...] = (
    NailSpec("pinky", 108, 332, 21, 30, -10),
    NailSpec("ring", 236, 182, 23, 34, -5),
    NailSpec("middle", 404, 128, 25, 38, 0),
    NailSpec("pointer", 572, 182, 23, 34, 5),
    NailSpec("thumb", 706, 528, 24, 30, 40),
)

FINGERS: tuple[FingerSpec, ...] = (
    FingerSpec((108, 690), (108, 358), 44),
    FingerSpec((236, 670), (236, 200), 48),
    FingerSpec((404, 660), (404, 150), 52),
    FingerSpec((572, 670), (572, 200), 48),
    FingerSpec((610, 770), (700, 548), 56),
)


def _lerp(a: float, b: float, t: float) -> float:
    return a + (b - a) * t


def _skin_color(t: float) -> tuple[int, int, int]:
    return (
        int(_lerp(SKIN_SHADOW[0], SKIN_HIGH[0], t)),
        int(_lerp(SKIN_SHADOW[1], SKIN_HIGH[1], t)),
        int(_lerp(SKIN_SHADOW[2], SKIN_HIGH[2], t)),
    )


def _draw_finger(
    draw: ImageDraw.ImageDraw,
    spec: FingerSpec,
    *,
    thumb: bool = False,
) -> None:
    bx, by = spec.base
    tx, ty = spec.tip
    w = spec.width
    dx, dy = tx - bx, ty - by
    length = max(1.0, math.hypot(dx, dy))
    nx, ny = -dy / length, dx / length
    steps = 12
    left: list[tuple[float, float]] = []
    right: list[tuple[float, float]] = []
    for i in range(steps + 1):
        t = i / steps
        cx = _lerp(bx, tx, t)
        cy = _lerp(by, ty, t)
        taper = _lerp(1.0, 0.72, t)
        left.append((cx + nx * w * 0.5 * taper, cy + ny * w * 0.5 * taper))
        right.append((cx - nx * w * 0.5 * taper, cy - ny * w * 0.5 * taper))
    poly = left + list(reversed(right))
    draw.polygon(poly, fill=(*SKIN, 255))
    for i in range(4):
        t = (i + 1) / 5
        shade = _skin_color(0.25 + 0.35 * t)
        inset = [(
            _lerp(poly[j][0], (bx + tx) / 2, t * 0.12),
            _lerp(poly[j][1], (by + ty) / 2, t * 0.12),
        ) for j in range(len(poly))]
        draw.polygon(inset, fill=(*shade, 80))
    if thumb:
        draw.arc((bx - 10, by - 6, bx + 36, by + 28), 210, 330, fill=(*SKIN_SHADOW, 100), width=3)
    else:
        draw.arc((bx - w * 0.3, by - 6, bx + w * 0.3, by + 12), 200, 340, fill=(*SKIN_SHADOW, 90), width=3)


def _draw_palm(draw: ImageDraw.ImageDraw) -> None:
    draw.polygon(
        [
            (120, 660),
            (90, 820),
            (150, 1180),
            (680, 1200),
            (740, 820),
            (700, 660),
            (620, 580),
            (404, 520),
            (180, 580),
        ],
        fill=(*SKIN, 255),
    )
    draw.ellipse((170, 700, 660, 1080), fill=(*SKIN_HIGH, 255))
    draw.ellipse((260, 760, 560, 940), fill=(*SKIN_BLUSH, 90))
    draw.arc((210, 760, 620, 980), 15, 165, fill=(*SKIN_SHADOW, 70), width=5)
    draw.ellipse((280, 1040, 560, 1380), fill=(*SKIN, 255))
    draw.arc((130, 640, 720, 900), 200, 340, fill=(*OUTLINE, 40), width=2)


def _draw_nail_layer(
    draw: ImageDraw.ImageDraw,
    spec: NailSpec,
) -> None:
    draw.ellipse(
        (
            spec.cx - spec.rx,
            spec.cy - spec.ry,
            spec.cx + spec.rx,
            spec.cy + spec.ry,
        ),
        fill=(*NAIL, 255),
    )
    # Soft vertical gloss
    gx0 = spec.cx - spec.rx * 0.22
    gx1 = spec.cx + spec.rx * 0.12
    gy0 = spec.cy - spec.ry * 0.75
    gy1 = spec.cy + spec.ry * 0.55
    draw.ellipse((gx0, gy0, gx1, gy1), fill=(*NAIL_SHINE, 140))


def _nail_mask_array(spec: NailSpec, shape: tuple[int, int]) -> np.ndarray:
    layer = Image.new("L", shape, 0)
    d = ImageDraw.Draw(layer)
    d.ellipse(
        (
            spec.cx - spec.rx,
            spec.cy - spec.ry,
            spec.cx + spec.rx,
            spec.cy + spec.ry,
        ),
        fill=255,
    )
    arr = np.asarray(layer) > 127
    arr = _fill_interior_gaps(arr, max_gap=6)
    closed = (
        Image.fromarray(arr.astype(np.uint8) * 255, "L")
        .filter(ImageFilter.MaxFilter(3))
    )
    return np.asarray(closed) > 127


def _rgba_mask(alpha: np.ndarray) -> Image.Image:
    feather = Image.fromarray(alpha.astype(np.uint8) * 255, "L").filter(
        ImageFilter.GaussianBlur(1.2)
    )
    a = np.asarray(feather).astype(np.uint8)
    out = np.zeros((*a.shape, 4), dtype=np.uint8)
    out[..., :3] = 255
    out[..., 3] = np.where(a > 8, a, 0)
    return Image.fromarray(out, "RGBA")


def build_hand() -> Image.Image:
    img = Image.new("RGBA", CANVAS, (0, 0, 0, 0))
    draw = ImageDraw.Draw(img, "RGBA")
    _draw_palm(draw)
    for i, finger in enumerate(FINGERS):
        _draw_finger(draw, finger, thumb=(i == 4))
    nail_layer = Image.new("RGBA", CANVAS, (0, 0, 0, 0))
    nd = ImageDraw.Draw(nail_layer, "RGBA")
    for nail in NAILS:
        _draw_nail_layer(nd, nail)
    img = Image.alpha_composite(img, nail_layer)
    return img


def build_masks(hand: Image.Image) -> dict[str, Image.Image]:
    h, w = hand.size[1], hand.size[0]
    masks: dict[str, Image.Image] = {}
    combined = np.zeros((h, w), dtype=bool)
    for spec in NAILS:
        plate = _nail_mask_array(spec, (w, h))
        combined |= plate
        masks[spec.digit] = _rgba_mask(plate)
    masks["all"] = _rgba_mask(combined)
    return masks


def _preview_multicolor(hand: Image.Image, masks: dict[str, Image.Image]) -> Image.Image:
    preview = hand.copy()
    colors = {
        "pinky": (255, 107, 168),
        "ring": (208, 18, 58),
        "middle": (230, 184, 162),
        "pointer": (244, 228, 236),
        "thumb": (212, 160, 23),
    }
    for digit, rgb in colors.items():
        tint = Image.new("RGBA", hand.size, (*rgb, 0))
        tint.putalpha(masks[digit].split()[-1].point(lambda v: int(v * 0.9)))
        preview = Image.alpha_composite(preview, tint)
    bg = Image.new("RGBA", hand.size, (255, 182, 193, 255))
    bg.alpha_composite(preview)
    return bg.convert("RGB")


def main() -> None:
    hand = build_hand()
    masks = build_masks(hand)

    hand.save(IMAGES / "final_hand_light.png")
    for spec in NAILS:
        masks[spec.digit].save(IMAGES / f"final_hand_light_nail_{spec.digit}.png")
    masks["all"].save(IMAGES / "final_hand_light_nail_mask.png")

    REVIEW.mkdir(parents=True, exist_ok=True)
    _preview_multicolor(hand, masks).save(
        REVIEW / "preview_final_hand_light_multicolor.jpg",
        quality=92,
    )
    # Mask alignment check
    check = Image.new("RGBA", hand.size, (255, 182, 193, 255))
    check.alpha_composite(hand)
    ov = np.zeros((*hand.size[::-1], 4), dtype=np.uint8)
    for spec in NAILS:
        m = np.asarray(masks[spec.digit])[..., 3] > 40
        ov[m] = (60, 220, 100, 160)
    check = Image.alpha_composite(check, Image.fromarray(ov, "RGBA"))
    check.convert("RGB").save(REVIEW / "preview_final_hand_light_mask_align.jpg", quality=92)

    for spec in NAILS:
        m = masks[spec.digit]
        bb = m.getbbox()
        print(spec.digit, "mask bbox", bb, "nail", spec)
    print("saved", IMAGES / "final_hand_light.png")


if __name__ == "__main__":
    main()
