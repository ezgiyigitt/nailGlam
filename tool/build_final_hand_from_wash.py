"""One clean final hand + nail masks from hand_wash cell 3 (Lila/Ezgi).

Writes previews to tool/review_light_nails/approval/ only — install after user says koy.
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "tool"))
from clean_hand_wash_skin import (  # noqa: E402
    NAILS as WASH_NAILS_543,
    _inpaint,
    _lum,
    _morph,
)
from make_zeynep_nail_sheets import _feather_nail_alpha, _fill_interior_gaps  # noqa: E402
from pack_zeynep_customer import _crop_to_content, _key_black  # noqa: E402

IMAGES = REPO / "assets" / "images"
REVIEW = REPO / "tool" / "review_light_nails" / "approval"
WASH = IMAGES / "hand_wash.png"
USER_REF = Path(
    r"C:\Users\Ezgi\.cursor\projects\c-Users-Ezgi-Documents-GitHub-nailGlam\assets"
    r"\c__Users_Ezgi_AppData_Roaming_Cursor_User_workspaceStorage_9564a3c94e3063fd248743fa88c27cbd_images_hand_wash-3a70dfb8-1525-47d9-a222-b372a372670b.jpg"
)

CELL_W, CELL_H = 979, 1473
SRC_W, SRC_H = 543, 724
CANVAS = (833, 1446)
STEMS = ("pinky", "ring", "middle", "pointer", "thumb")
NAIL_CLEAN = np.array([255, 244, 238], dtype=np.float32)
NAIL_TIP = np.array([255, 252, 250], dtype=np.float32)
NAIL_CUTICLE = np.array([248, 220, 210], dtype=np.float32)
# Post-cut manicure: keep ~58% of the long wash nail plate.
SHORT_NAIL_FRAC = 0.58


def _shorten_nails(nails_param: tuple, frac: float = SHORT_NAIL_FRAC) -> tuple:
    """Move the free edge toward the cuticle — trimmed stiletto → short nail."""
    out = []
    for x, y, ax, ay, length, tip_r, base_r in nails_param:
        short_len = length * frac
        trim = length - short_len
        nx = x + ax * trim
        ny = y + ay * trim
        out.append(
            (
                nx,
                ny,
                ax,
                ay,
                short_len,
                tip_r * 1.08,
                base_r * 0.90,
            )
        )
    return tuple(out)


def _scale_nails() -> tuple:
    sx, sy = CELL_W / SRC_W, CELL_H / SRC_H
    s = (sx + sy) / 2
    scaled = []
    for x, y, ax, ay, length, tip_r, base_r in WASH_NAILS_543:
        scaled.append((x * sx, y * sy, ax, ay, length * s, tip_r * s, base_r * s))
    return tuple(scaled)


def _stadium_on(shape: tuple[int, ...], nails: tuple) -> np.ndarray:
    h, w = shape[:2]
    yy, xx = np.mgrid[0:h, 0:w]
    mask = np.zeros((h, w), dtype=bool)
    for x, y, ax, ay, length, tip_r, base_r in nails:
        n = (ax * ax + ay * ay) ** 0.5
        ax, ay = ax / n, ay / n
        px, py = -ay, ax
        relx = xx - x
        rely = yy - y
        along = relx * ax + rely * ay
        across = relx * px + rely * py
        t = np.clip(along / max(length, 1), 0, 1)
        radius = tip_r + (base_r - tip_r) * t
        mask |= (along >= -10) & (along <= length + 6) & (np.abs(across) <= radius + 2)
    return mask


def _load_wash_cell(index: int = 3) -> Image.Image:
    for path in (WASH, USER_REF):
        if path.exists():
            strip = Image.open(path).convert("RGBA")
            cols = strip.width // 4
            if cols != CELL_W or strip.height != CELL_H:
                # User JPG may be 4 equal cells with different size
                cw = strip.width // 4
                ch = strip.height
                return strip.crop((index * cw, 0, (index + 1) * cw, ch))
            return strip.crop((index * CELL_W, 0, (index + 1) * CELL_W, CELL_H))
    raise FileNotFoundError("hand_wash source missing")


def _clean_skin_and_nails(
    frame: Image.Image,
    nails_long: tuple,
    nails_short: tuple,
) -> Image.Image:
    original = np.asarray(frame.convert("RGBA"))
    rgb = original[..., :3].astype(np.float32)
    opaque = original[..., 3] > 24

    nails_protect = _stadium_on(rgb.shape, nails_long) & opaque

    lum = _lum(rgb)
    r, g = rgb[..., 0], rgb[..., 1]
    interior = _morph(opaque, ImageFilter.MinFilter(7))
    dark = interior & ~nails_protect & (lum < 150) & ((r - g) > 28)
    rgb = _inpaint(rgb, dark, nails_protect, interior)

    lum2 = _lum(rgb)
    from clean_hand_wash_skin import _blur_fill  # noqa: WPS433

    local, wloc = _blur_fill(
        rgb,
        interior & ~nails_protect & (lum2 > 160) & ((rgb[..., 0] - rgb[..., 1]) > 50),
        radius=11,
    )
    tan = (
        interior
        & ~nails_protect
        & (wloc > 0.08)
        & ((_lum(local) - lum2) > 8)
        & (lum2 < 198)
    )
    rgb = _inpaint(rgb, tan, nails_protect, interior)

    # Trimmed clean nail plates only (post-cut length).
    nail_mask = _stadium_on(rgb.shape, nails_short) & opaque
    yy, xx = np.mgrid[0 : rgb.shape[0], 0 : rgb.shape[1]]
    for x, y, ax, ay, length, tip_r, base_r in nails_short:
        n = (ax * ax + ay * ay) ** 0.5
        ax, ay = ax / n, ay / n
        along = (xx - x) * ax + (yy - y) * ay
        t = np.clip(along / max(length, 1), 0, 1)
        plate = nail_mask & (along >= 0) & (along <= length)
        color = (
            NAIL_CUTICLE * (1 - t[..., None]) * 0.35
            + NAIL_CLEAN * (0.65 + 0.35 * (1 - t[..., None]))
            + NAIL_TIP * (t[..., None] * 0.4)
        )
        rgb = np.where(plate[..., None], color, rgb)

    # Remove the clipped-off long nail tips → skin.
    long_mask = _stadium_on(rgb.shape, nails_long) & opaque
    short_mask = nail_mask
    extension = long_mask & ~short_mask
    rgb = _inpaint(rgb, extension, short_mask, interior)

    out = original.copy()
    out[..., :3] = np.clip(rgb, 0, 255).astype(np.uint8)
    return Image.fromarray(out, "RGBA")


def _fit_canvas(frame: Image.Image) -> tuple[Image.Image, tuple[float, float, float]]:
    """Return canvas image and (scale, offset_x, offset_y) from cell → canvas."""
    keyed = _key_black(frame, fill_tolerance=18)
    crop = _crop_to_content(keyed)
    cw, ch = CANVAS
    scale = min((cw - 24) / crop.width, (ch - 24) / crop.height)
    nw = max(1, round(crop.width * scale))
    nh = max(1, round(crop.height * scale))
    scaled = crop.resize((nw, nh), Image.LANCZOS)
    canvas = Image.new("RGBA", CANVAS, (0, 0, 0, 0))
    ox = (cw - nw) // 2
    oy = ch - nh - 12
    canvas.alpha_composite(scaled, (ox, oy))
    return canvas, (scale, float(ox), float(oy))


def _nails_on_canvas(nails_param: tuple, transform: tuple[float, float, float]) -> tuple:
    scale, ox, oy = transform
    out = []
    for x, y, ax, ay, length, tip_r, base_r in nails_param:
        out.append(
            (x * scale + ox, y * scale + oy, ax, ay, length * scale, tip_r * scale, base_r * scale)
        )
    return tuple(out)


def _digit_stadiums(nails: tuple) -> dict[str, np.ndarray]:
    """One stadium per nail, left→right = pinky…thumb in dorsal view."""
    h, w = CANVAS[1], CANVAS[0]
    per_nail: list[np.ndarray] = []
    for spec in nails:
        per_nail.append(_stadium_on((h, w), (spec,)))
    order = sorted(range(5), key=lambda i: float(np.where(per_nail[i])[1].mean()) if per_nail[i].any() else i)
    if len(order) != 5:
        raise RuntimeError("expected 5 nail masks")
    return {STEMS[i]: per_nail[order[i]] for i in range(5)}


def _rgba_mask(alpha: np.ndarray) -> Image.Image:
    feather = Image.fromarray(alpha.astype(np.uint8) * 255, "L").filter(
        ImageFilter.GaussianBlur(1.3)
    )
    a = np.asarray(feather).astype(np.uint8)
    out = np.zeros((*a.shape, 4), dtype=np.uint8)
    out[..., :3] = 255
    out[..., 3] = np.where(a > 8, a, 0)
    return Image.fromarray(out, "RGBA")


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
        tint = Image.new("RGBA", hand.size, (*rgb, 0))
        tint.putalpha(masks[stem].split()[-1].point(lambda v: int(v * 0.93)))
        preview = Image.alpha_composite(preview, tint)
    bg = Image.new("RGBA", hand.size, (255, 182, 193, 255))
    bg.alpha_composite(preview)
    return bg.convert("RGB")


def _preview_align(hand: Image.Image, masks: dict[str, Image.Image]) -> Image.Image:
    bg = Image.new("RGBA", hand.size, (255, 182, 193, 255))
    bg.alpha_composite(hand)
    ov = np.zeros((*hand.size[::-1], 4), dtype=np.uint8)
    for i, stem in enumerate(STEMS):
        m = np.asarray(masks[stem])[..., 3] > 40
        hue = (50 + i * 42) % 255
        ov[m] = (60, 180 + hue // 4, 90, 175)
    bg = Image.alpha_composite(bg, Image.fromarray(ov, "RGBA"))
    return bg.convert("RGB")


def main() -> None:
    REVIEW.mkdir(parents=True, exist_ok=True)
    nails_long = _scale_nails()
    nails_short = _shorten_nails(nails_long)
    raw = _load_wash_cell(3)
    raw.save(REVIEW / "final_hand_wash_cell3_before.png")

    cleaned = _clean_skin_and_nails(raw, nails_long, nails_short)
    cleaned.save(REVIEW / "final_hand_wash_cell3_cleaned.png")

    hand, xform = _fit_canvas(cleaned)
    hand.save(REVIEW / "final_hand_light_candidate.png")

    nails_canvas = _nails_on_canvas(nails_short, xform)
    digit_masks = _digit_stadiums(nails_canvas)
    masks: dict[str, Image.Image] = {}
    combined = np.zeros(CANVAS[::-1], dtype=bool)
    for stem, plate in digit_masks.items():
        plate = _fill_interior_gaps(plate, max_gap=10)
        masks[stem] = _rgba_mask(_feather_nail_alpha(plate))
        masks[stem].save(REVIEW / f"final_hand_light_nail_{stem}_candidate.png")
        combined |= plate
    _rgba_mask(_feather_nail_alpha(combined)).save(
        REVIEW / "final_hand_light_nail_mask_candidate.png"
    )

    _preview_multicolor(hand, masks).save(
        REVIEW / "preview_final_hand_wash_multicolor.jpg",
        quality=94,
    )
    _preview_align(hand, masks).save(
        REVIEW / "preview_final_hand_wash_mask_align.jpg",
        quality=94,
    )
    print("candidate hand", REVIEW / "final_hand_light_candidate.png", CANVAS)
    print("multicolor preview", REVIEW / "preview_final_hand_wash_multicolor.jpg")
    print("mask align preview", REVIEW / "preview_final_hand_wash_mask_align.jpg")
    print("Onay için bak — 'koy' dersen assets/images/ altına kurulur.")


if __name__ == "__main__":
    main()
