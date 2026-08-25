"""Last hand_wash cell → one clean hand PNG, transparent background."""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "tool"))
from clean_hand_wash_skin import NAILS as WASH_NAILS_543, _inpaint, _lum, _morph  # noqa: E402
from pack_zeynep_customer import _crop_to_content, _key_black  # noqa: E402

WASH = REPO / "assets" / "images" / "hand_wash.png"
OUT = REPO / "tool" / "review_light_nails" / "approval" / "el_temiz_seffaf.png"

CELL_W, CELL_H = 979, 1473
SRC_W, SRC_H = 543, 724
NAIL = np.array([255, 246, 240], dtype=np.float32)
NAIL_TIP = np.array([255, 252, 250], dtype=np.float32)
CUTICLE = np.array([250, 228, 218], dtype=np.float32)


def _scale_nails() -> tuple:
    sx, sy = CELL_W / SRC_W, CELL_H / SRC_H
    s = (sx + sy) / 2
    return tuple(
        (x * sx, y * sy, ax, ay, length * s, tip_r * s, base_r * s)
        for x, y, ax, ay, length, tip_r, base_r in WASH_NAILS_543
    )


def _one_stadium(h: int, w: int, spec: tuple) -> np.ndarray:
    x, y, ax, ay, length, tip_r, base_r = spec
    yy, xx = np.mgrid[0:h, 0:w]
    n = (ax * ax + ay * ay) ** 0.5
    ax, ay = ax / n, ay / n
    px, py = -ay, ax
    along = (xx - x) * ax + (yy - y) * ay
    across = (xx - x) * px + (yy - y) * py
    t = np.clip(along / max(length, 1), 0, 1)
    radius = tip_r + (base_r - tip_r) * t
    return (along >= -6) & (along <= length + 6) & (np.abs(across) <= radius + 3)


def _detect_nail_plates(rgb: np.ndarray, opaque: np.ndarray) -> np.ndarray:
    h, w = rgb.shape[:2]
    lum = _lum(rgb)
    chroma = rgb.max(axis=2) - rgb.min(axis=2)
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]

    ys = np.flatnonzero(opaque.any(axis=1))
    y0, y1 = int(ys[0]), int(ys[-1])
    distal = np.zeros((h, w), dtype=bool)
    distal[y0 + int((y1 - y0) * 0.38) :] = True

    enamel = (
        opaque
        & distal
        & (
            ((lum > 100) & (chroma > 10) & (r > b + 6))
            | ((lum > 210) & (chroma < 50))
        )
    )

    combined = np.zeros((h, w), dtype=bool)
    for spec in _scale_nails():
        plate = _one_stadium(h, w, spec) & enamel & opaque
        plate = np.asarray(
            Image.fromarray(plate.astype(np.uint8) * 255, "L").filter(
                ImageFilter.MaxFilter(5)
            )
        ) > 127
        combined |= plate
    if int(combined.sum()) < 2000:
        raise RuntimeError("nail plates too small")
    return combined


def _paint_nails(rgb: np.ndarray, plate: np.ndarray, nails: tuple) -> np.ndarray:
    out = rgb.copy()
    h, w = plate.shape
    yy, xx = np.mgrid[0:h, 0:w]
    for spec in nails:
        x, y, ax, ay, length, tip_r, base_r = spec
        n = (ax * ax + ay * ay) ** 0.5
        ax, ay = ax / n, ay / n
        along = (xx - x) * ax + (yy - y) * ay
        t = np.clip(along / max(length, 1), 0, 1)
        on = plate & _one_stadium(h, w, spec)
        color = (
            CUTICLE * (1 - t[..., None]) * 0.35
            + NAIL * (1 - t[..., None] * 0.22)
            + NAIL_TIP * (t[..., None] * 0.38)
        )
        out = np.where(on[..., None], color, out)
    return out


def main() -> None:
    strip = Image.open(WASH).convert("RGBA")
    cell = strip.crop((3 * CELL_W, 0, 4 * CELL_W, CELL_H))
    arr = np.asarray(cell)
    rgb = arr[..., :3].astype(np.float32)
    opaque = arr[..., 3] > 20

    nails = _scale_nails()
    plate = _detect_nail_plates(rgb, opaque)
    interior = _morph(opaque, ImageFilter.MinFilter(7))

    lum = _lum(rgb)
    r, g = rgb[..., 0], rgb[..., 1]
    dark = interior & ~plate & (lum < 155) & ((r - g) > 26)
    rgb = _inpaint(rgb, dark, plate, interior)
    rgb = _paint_nails(rgb, plate, nails)

    out = arr.copy()
    out[..., :3] = np.clip(rgb, 0, 255).astype(np.uint8)
    keyed = _key_black(Image.fromarray(out, "RGBA"), fill_tolerance=20)
    clean = _crop_to_content(keyed)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    clean.save(OUT)
    print(OUT, clean.size)


if __name__ == "__main__":
    main()
