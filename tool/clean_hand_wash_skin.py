"""Clean leftover skin dirt on the wash dissolve cell. Nails stay put.

Dark brown smears on peach skin are inpainted from neighboring clean skin.
Nail plates and cuticle crusts are covered by a stiletto stadium (narrow at
the tip, wide at the base) plus color, and are never rewritten.
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

REPO = Path(__file__).resolve().parent.parent
SHEET = REPO / "assets" / "images" / "hand_wash.png"
REVIEW = REPO / "tool" / "_review_wash"
BACKUP = REVIEW / "frame_2.png"

CELL_W = 543
CELL_H = 724

# tip x, tip y, axis x, axis y, length, tip radius, base radius
NAILS = (
    (15, 556, 0.616, -0.788, 102, 7, 24),
    (111, 670, 0.412, -0.911, 144, 8, 30),
    (238, 714, 0.061, -0.998, 150, 9, 34),
    (393, 677, -0.363, -0.932, 130, 8, 30),
    (490, 479, -0.500, -0.866, 110, 7, 24),
)


def _lum(rgb: np.ndarray) -> np.ndarray:
    return 0.21 * rgb[..., 0] + 0.72 * rgb[..., 1] + 0.07 * rgb[..., 2]


def _stadium_mask(shape: tuple[int, ...]) -> np.ndarray:
    h, w = shape[:2]
    yy, xx = np.mgrid[0:h, 0:w]
    mask = np.zeros((h, w), dtype=bool)
    for x, y, ax, ay, length, tip_r, base_r in NAILS:
        n = (ax * ax + ay * ay) ** 0.5
        ax, ay = ax / n, ay / n
        px, py = -ay, ax
        relx = xx - x
        rely = yy - y
        along = relx * ax + rely * ay
        across = relx * px + rely * py
        t = (along / max(length, 1)).clip(0, 1)
        radius = tip_r + (base_r - tip_r) * t
        mask |= (along >= -8) & (along <= length) & (np.abs(across) <= radius)
    return mask


def _morph(mask: np.ndarray, filt: ImageFilter.Filter) -> np.ndarray:
    img = Image.fromarray((mask.astype(np.uint8) * 255), "L")
    return np.asarray(img.filter(filt)) > 127


def _protect_nails(rgb: np.ndarray, opaque: np.ndarray) -> np.ndarray:
    lum = _lum(rgb)
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    stadium = _stadium_mask(rgb.shape)
    peach = (lum > 150) & ((r - g) > 60) & (r > 190) & ((g - b) < 45)
    protect = opaque & stadium & ~peach
    return _morph(protect, ImageFilter.MaxFilter(3))


def _blur_fill(rgb: np.ndarray, support: np.ndarray, radius: int) -> tuple[np.ndarray, np.ndarray]:
    weight = support.astype(np.float32)
    colored = rgb * weight[..., None]
    rgba = np.dstack([colored, weight * 255.0]).astype(np.uint8)
    blur = np.asarray(
        Image.fromarray(rgba, "RGBA").filter(ImageFilter.GaussianBlur(radius=radius)),
        dtype=np.float32,
    )
    acc = blur[..., :3]
    w = blur[..., 3] / 255.0
    filled = acc / np.clip(w, 1e-3, None)[..., None]
    return filled, w


def _feather(mask: np.ndarray, radius: int) -> np.ndarray:
    img = Image.fromarray((mask.astype(np.uint8) * 255), "L")
    blur = np.asarray(img.filter(ImageFilter.GaussianBlur(radius=radius)), dtype=np.float32)
    return np.clip(blur / 255.0, 0, 1)


def _inpaint(rgb: np.ndarray, dirt: np.ndarray, nails: np.ndarray, interior: np.ndarray) -> np.ndarray:
    lum = _lum(rgb)
    r, g = rgb[..., 0], rgb[..., 1]
    support = interior & ~nails & ~dirt & (lum > 155) & ((r - g) > 48)
    skin_est, weight = _blur_fill(rgb, support, radius=22)
    fade = _feather(dirt, 2)
    fade = np.where(nails | (weight < 0.05), 0.0, fade)
    return rgb * (1.0 - fade[..., None]) + skin_est * fade[..., None]


def main() -> int:
    original = np.asarray(Image.open(BACKUP).convert("RGBA"))
    rgb = original[..., :3].astype(np.float32)
    opaque = original[..., 3] > 24
    lum = _lum(rgb)
    r, g = rgb[..., 0], rgb[..., 1]
    nails = _protect_nails(rgb, opaque)
    interior = _morph(opaque, ImageFilter.MinFilter(7))

    dark = interior & ~nails & (lum < 150) & ((r - g) > 28)
    dark = dark & interior & ~nails
    rgb = _inpaint(rgb, dark, nails, interior)

    lum2 = _lum(rgb)
    local, wloc = _blur_fill(
        rgb,
        interior & ~nails & (lum2 > 160) & ((rgb[..., 0] - rgb[..., 1]) > 50),
        radius=11,
    )
    tan = (
        interior
        & ~nails
        & (wloc > 0.08)
        & ((_lum(local) - lum2) > 8)
        & (lum2 < 198)
    )
    tan = tan & interior & ~nails
    rgb = _inpaint(rgb, tan, nails, interior)

    # Soft grain lift on the back of the hand; fades out before the nails.
    yy = np.arange(rgb.shape[0])[:, None].astype(np.float32)
    palm_w = np.clip((360.0 - yy) / 60.0, 0.0, 1.0)
    grain_support = interior & ~nails & (_lum(rgb) > 165)
    grain_est, _gw = _blur_fill(rgb, grain_support, radius=8)
    grain = (0.48 * palm_w) * interior.astype(np.float32)
    grain = np.where(nails, 0.0, grain)
    rgb = rgb * (1.0 - grain[..., None]) + grain_est * grain[..., None]

    out = original.copy()
    out[..., :3] = np.clip(rgb, 0, 255).astype(np.uint8)

    nail_delta = np.abs(out[..., :3].astype(np.int16) - original[..., :3].astype(np.int16))
    nail_change = int(nail_delta[nails].max()) if nails.any() else 0
    dirt = dark | tan
    palm = opaque & (np.arange(CELL_H)[:, None] < 340) & (np.arange(CELL_W) > 120) & (
        np.arange(CELL_W) < 400
    )
    print("coverage (dark near tips protected):")
    for name, x, y, box in (
        ("thumb", 15, 556, (470, 580, 0, 90)),
        ("index", 111, 670, (520, 724, 60, 180)),
        ("mid", 238, 714, (560, 724, 180, 300)),
        ("ring", 393, 677, (520, 724, 320, 450)),
        ("pinky", 490, 479, (380, 530, 430, 543)),
    ):
        y0, y1, x0, x1 = box
        region = np.zeros(original.shape[:2], dtype=bool)
        region[y0:y1, x0:x1] = True
        darkp = opaque & region & (lum < 125)
        ok = int((darkp & nails).sum())
        tot = int(darkp.sum())
        print(f"  {name:5s} {ok}/{tot}")

    leftover = interior & ~nails & (_lum(rgb) < 155) & ((rgb[..., 0] - rgb[..., 1]) > 30)
    mag = out.copy()
    mag[leftover] = (255, 0, 255, 255)
    Image.fromarray(mag).crop((120, 140, 400, 380)).save(REVIEW / "zoom_palm_leftover.png")
    print(
        f"dark {int(dark.sum())} tan {int(tan.sum())} nails {int(nails.sum())} "
        f"nail_delta_max {nail_change} "
        f"palm_lum {float(lum[palm].mean()):.1f} -> {float(_lum(rgb)[palm].mean()):.1f} "
        f"palm_dark {int((palm & (lum < 140)).sum())} -> {int((palm & (_lum(rgb) < 140)).sum())} "
        f"dirt_px(299,332) {tuple(original[332, 299, :3])} -> {tuple(out[332, 299, :3])}"
    )

    REVIEW.mkdir(parents=True, exist_ok=True)
    cleaned = Image.fromarray(out, "RGBA")
    cleaned.save(REVIEW / "cell2_cleaned.png")
    Image.fromarray(original).crop((120, 140, 400, 380)).save(REVIEW / "zoom_palm_before.png")
    cleaned.crop((120, 140, 400, 380)).save(REVIEW / "zoom_palm_after.png")
    Image.fromarray(original).crop((160, 540, 330, 724)).save(REVIEW / "zoom_midnail_before.png")
    cleaned.crop((160, 540, 330, 724)).save(REVIEW / "zoom_midnail_after.png")
    Image.fromarray(original).crop((0, 430, 150, 580)).save(REVIEW / "zoom_thumb_before.png")
    cleaned.crop((0, 430, 150, 580)).save(REVIEW / "zoom_thumb_after.png")

    overlay = original.copy()
    overlay[..., 0] = np.where(nails, 255, overlay[..., 0])
    overlay[..., 1] = np.where(dirt, 220, overlay[..., 1])
    Image.fromarray(overlay).save(REVIEW / "debug_overlay.png")

    write_sheet = "--write" in sys.argv
    if write_sheet:
        sheet = Image.open(SHEET).convert("RGBA")
        result = sheet.copy()
        result.paste(cleaned, (2 * CELL_W, 0))
        result.save(SHEET)
        print("wrote sheet cell 2")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
