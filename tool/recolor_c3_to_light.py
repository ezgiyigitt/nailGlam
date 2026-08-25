"""Recolor Customer 3 (dark) nail sheets to fair skin for Customer 1 / 2.

Keeps dirt / clip / polish geometry identical — only skin tone changes.
Writes approval previews only (does not overwrite game light assets unless --write-assets).
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image

REPO = Path(__file__).resolve().parent.parent
IMAGES = REPO / "assets" / "images"
OUT = REPO / "tool" / "review_light_nails" / "approval_recolor"
PINK = (255, 182, 193)

# Fair peach target (cartoon light still vibe).
TARGET_SKIN = np.array([236.0, 186.0, 158.0], dtype=np.float32)


def _luma(rgb: np.ndarray) -> np.ndarray:
    return 0.2126 * rgb[..., 0] + 0.7152 * rgb[..., 1] + 0.0722 * rgb[..., 2]


def nail_keep_mask(arr: np.ndarray, polish_mask: Image.Image | None = None) -> np.ndarray:
    """Only the nail plate stays — everything else is fair skin."""
    alpha = arr[..., 3] > 8
    h, w = alpha.shape
    keep = np.zeros((h, w), dtype=bool)
    if polish_mask is None:
        rgb = arr[..., :3].astype(np.float32)
        lum = _luma(rgb)
        # Fallback: pale tip enamel only.
        return alpha & (lum >= 145)
    m = np.asarray(polish_mask.convert("RGBA").resize((w, h), Image.NEAREST))[..., 3] > 40
    from PIL import ImageFilter

    # Grow short-tip mask up the plate so long dirty frames stay protected.
    grown = Image.fromarray(m.astype(np.uint8) * 255, "L")
    for _ in range(14):
        grown = grown.filter(ImageFilter.MaxFilter(7))
    keep = (np.asarray(grown) > 40) & alpha
    # Never let the keep blob climb into the knuckle half.
    ys = np.flatnonzero(alpha.any(axis=1))
    if ys.size:
        y0, y1 = int(ys[0]), int(ys[-1])
        cut = y0 + int((y1 - y0) * 0.48)
        keep[:cut, :] = False
    return keep


def recolor_skin(image: Image.Image, polish_mask: Image.Image | None = None) -> Image.Image:
    arr = np.asarray(image.convert("RGBA")).copy()
    rgb = arr[..., :3].astype(np.float32)
    alpha = arr[..., 3] > 8
    keep_nail = nail_keep_mask(arr, polish_mask)
    skin = alpha & ~keep_nail
    if not skin.any():
        return image.convert("RGBA")

    lum = _luma(rgb)
    skin_lum = lum[skin]
    lo = float(np.percentile(skin_lum, 3))
    hi = float(np.percentile(skin_lum, 97))
    span = max(10.0, hi - lo)
    t = np.clip((lum - lo) / span, 0.0, 1.0)
    t2 = t * t * (3 - 2 * t)

    deep = np.array([198.0, 140.0, 118.0], dtype=np.float32)
    mid = TARGET_SKIN
    hi_c = np.array([250.0, 220.0, 205.0], dtype=np.float32)
    shade = deep * (1 - t2)[..., None] + mid * t2[..., None]
    hi_w = np.clip((t - 0.55) / 0.45, 0, 1)[..., None]
    shade = shade * (1 - hi_w) + hi_c * hi_w

    # Full replace on skin — do not keep dark chroma.
    arr[..., :3] = np.where(skin[..., None], np.clip(shade, 0, 255), rgb).astype(np.uint8)
    return Image.fromarray(arr, "RGBA")


def preview_strip(strip: Image.Image, dest: Path) -> None:
    canvas = Image.new("RGBA", strip.size, (*PINK, 255))
    canvas.alpha_composite(strip.convert("RGBA"))
    dest.parent.mkdir(parents=True, exist_ok=True)
    canvas.convert("RGB").save(dest, quality=92)


def process_stem(stem: str, write_assets: bool) -> None:
    clean_src = IMAGES / f"{stem}_clean_dark.png"
    short_src = IMAGES / f"{stem}_short_dark.png"
    mask_src = IMAGES / f"{stem}_nail_mask_dark.png"
    if not clean_src.exists():
        clean_src = IMAGES / "pinky_clean_dark.png"
        short_src = IMAGES / "pinky_short_dark.png"
        mask_src = IMAGES / "pinky_nail_mask_dark.png"
    if not mask_src.exists():
        mask_src = IMAGES / "pinky_nail_mask_dark.png"
    mask_cell = Image.open(mask_src).convert("RGBA")

    # Tile one-cell mask across the 4-frame strip.
    clean_img = Image.open(clean_src).convert("RGBA")
    short_img = Image.open(short_src).convert("RGBA")
    frames = clean_img.size[0] // max(1, mask_cell.size[0])
    if frames < 1:
        frames = 4
    strip_mask = Image.new("RGBA", clean_img.size, (0, 0, 0, 0))
    for i in range(frames):
        strip_mask.paste(mask_cell, (i * mask_cell.size[0], 0), mask_cell)

    clean = recolor_skin(clean_img, strip_mask)
    short = recolor_skin(short_img, strip_mask)
    polish_mask = mask_cell

    OUT.mkdir(parents=True, exist_ok=True)
    clean.save(OUT / f"{stem}_clean_light_recolor.png")
    short.save(OUT / f"{stem}_short_light_recolor.png")
    polish_mask.save(OUT / f"{stem}_nail_mask_light_recolor.png")

    preview_strip(clean, OUT / f"{stem}_clean.jpg")
    preview_strip(short, OUT / f"{stem}_short.jpg")
    w, h = short.size
    cell_w = w // 4
    last = short.crop((cell_w * 3, 0, w, h))
    mcell = polish_mask.resize(last.size, Image.NEAREST) if polish_mask.size != last.size else polish_mask
    overlay = Image.new("RGBA", last.size, (255, 70, 140, 0))
    overlay.putalpha(mcell.split()[-1].point(lambda v: int(v * 0.92)))
    preview_strip(Image.alpha_composite(last, overlay), OUT / f"{stem}_polish.jpg")

    if write_assets:
        clean.save(IMAGES / f"{stem}_clean_light.png")
        short.save(IMAGES / f"{stem}_short_light.png")
        polish_mask.save(IMAGES / f"{stem}_nail_mask_light.png")
    print(stem, "ok", clean.size)


def contact_sheet() -> None:
    from make_zeynep_nail_sheets import even_cells

    rows = [
        ("C3 pinky dirty->clean", even_cells(Image.open(IMAGES / "pinky_clean_dark.png"))),
        ("Light pinky recolor dirty->clean", even_cells(Image.open(OUT / "pinky_clean_light_recolor.png"))),
        ("C3 pinky long->short", even_cells(Image.open(IMAGES / "pinky_short_dark.png"))),
        ("Light pinky recolor long->short", even_cells(Image.open(OUT / "pinky_short_light_recolor.png"))),
        ("Light middle recolor dirty->clean", even_cells(Image.open(OUT / "middle_clean_light_recolor.png"))),
        ("Light thumb recolor dirty->clean", even_cells(Image.open(OUT / "thumb_clean_light_recolor.png"))),
    ]
    cell_w, cell_h = 200, 480
    pad, label_h = 10, 26
    width = pad * 2 + 4 * cell_w + 3 * 6
    height = pad * 2 + len(rows) * (cell_h + label_h + 8)
    page = Image.new("RGB", (width, height), (36, 32, 38))
    from PIL import ImageDraw, ImageFont

    draw = ImageDraw.Draw(page)
    try:
        font = ImageFont.truetype("arial.ttf", 15)
    except OSError:
        font = ImageFont.load_default()
    y = pad
    for title, frames in rows:
        draw.text((pad, y), title, fill=(255, 230, 240), font=font)
        y += label_h
        x = pad
        for fr in frames[:4]:
            fr = fr.convert("RGBA")
            scale = min(cell_w / fr.width, cell_h / fr.height)
            nw, nh = max(1, round(fr.width * scale)), max(1, round(fr.height * scale))
            scaled = fr.resize((nw, nh), Image.LANCZOS)
            bg = Image.new("RGBA", (cell_w, cell_h), (*PINK, 255))
            bg.paste(scaled, ((cell_w - nw) // 2, (cell_h - nh) // 2), scaled)
            page.paste(bg.convert("RGB"), (x, y))
            x += cell_w + 6
        y += cell_h + 8
    dest = OUT / "CONTACT_recolor_vs_c3.jpg"
    page.save(dest, quality=90)
    print("contact", dest)


def main() -> None:
    write_assets = "--write-assets" in sys.argv
    for stem in ("pinky", "middle", "thumb"):
        process_stem(stem, write_assets=write_assets)
    # ring/index share middle art in game; still emit copies for review clarity
    for stem in ("ring", "index"):
        for suffix in ("clean_light_recolor.png", "short_light_recolor.png", "nail_mask_light_recolor.png"):
            src = OUT / f"middle_{suffix}"
            if src.exists():
                Image.open(src).save(OUT / f"{stem}_{suffix}")
    contact_sheet()
    print("Approval folder:", OUT)
    if not write_assets:
        print("Preview only — pass --write-assets to copy into assets/images/")


if __name__ == "__main__":
    main()
