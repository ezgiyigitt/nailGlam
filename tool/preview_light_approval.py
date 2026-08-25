"""Build approval-only light-skin nail strips (Customer 1 / 2).

Matches Customer 3 pipeline:
  dirty → clean (yellow blotchy plate, locked finger)
  long → short (left-to-right tip clip only)
  polish mask on short tip

Writes ONLY under tool/review_light_nails/approval/. Does not touch game assets.
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "tool"))

import make_zeynep_nail_sheets as zsheets  # noqa: E402
from make_light_nail_sheets import (  # noqa: E402
    CURSOR_ASSETS,
    REVIEW,
    _largest_blob,
    fit_light_cell,
    nail_mask_light,
    orient_nail_down,
)
from make_zeynep_nail_sheets import (  # noqa: E402
    clip_left_to_right,
    clipped_nail_mask,
    even_cells,
    pack_strip,
    polish_mask_from_nail,
    stain_nail,
    _luma,
)
from pack_zeynep_customer import _crop_to_content, _key_auto  # noqa: E402

IMAGES = REPO / "assets" / "images"
OUT = REVIEW / "approval"
PINK = (255, 182, 193)


def _cell_from_cartoon(stem: str) -> Image.Image:
    still = Image.open(CURSOR_ASSETS / f"light_{stem}_cartoon.png")
    keyed = orient_nail_down(
        _largest_blob(_crop_to_content(_key_auto(still.convert("RGBA"))))
    )
    return fit_light_cell(keyed)


def _add_cuticle_grime(cell: Image.Image, nail: np.ndarray, amt: float) -> Image.Image:
    """Dark cuticle bead like hand_wash dirty nails — only on the nail plate."""
    if amt <= 0.05 or not nail.any():
        return cell
    out = np.asarray(cell.convert("RGBA")).copy()
    nys, nxs = np.where(nail)
    y0, y1 = int(nys.min()), int(nys.max()) + 1
    x0, x1 = int(nxs.min()), int(nxs.max()) + 1
    h = y1 - y0
    band = nail[y0 : y0 + max(1, int(h * 0.22)), x0:x1]
    if not band.any():
        return cell
    yy = np.linspace(1.0, 0.0, band.shape[0], dtype=np.float32)[:, None]
    xx = np.linspace(-1.0, 1.0, band.shape[1], dtype=np.float32)[None, :]
    edge = np.clip(1.0 - (np.abs(xx) - 0.55) / 0.35, 0.0, 1.0)
    cover = (yy ** 1.4) * (0.55 + 0.45 * edge) * band.astype(np.float32) * amt
    dirt = np.array([42.0, 28.0, 18.0], dtype=np.float32)
    base = out[y0 : y0 + band.shape[0], x0:x1, :3].astype(np.float32)
    w = cover[..., None]
    out[y0 : y0 + band.shape[0], x0:x1, :3] = np.clip(
        base * (1.0 - w) + dirt * w, 0, 255
    )
    return Image.fromarray(out, "RGBA")


def build_digit(stem: str) -> dict[str, Path]:
    zsheets.nail_mask = lambda cell, luma_min=145: nail_mask_light(cell)
    dirt_refs = even_cells(Image.open(IMAGES / "pinky_clean_dark.png"))
    cell = _cell_from_cartoon(stem)
    nail0 = nail_mask_light(cell)
    if not nail0.any():
        raise RuntimeError(f"{stem}: empty nail mask")

    # Same levels as Zeynep: whole plate → tip blotches → clean.
    levels = (1.0, 0.62, 0.28, 0.0)
    clean_frames: list[Image.Image] = []
    for i, level in enumerate(levels):
        if level <= 0.02:
            clean_frames.append(cell.copy())
            continue
        stained = stain_nail(cell, level, dirt_refs[min(i, len(dirt_refs) - 1)])
        # Light cuticle bead only on the dirtiest frames (hand-wash nail look).
        stained = _add_cuticle_grime(stained, nail0, amt=level * 0.55)
        clean_frames.append(stained)

    short_frames = [clip_left_to_right(cell, stage) for stage in range(4)]
    mask = polish_mask_from_nail(clipped_nail_mask(nail0, 3), short_frames[-1])

    OUT.mkdir(parents=True, exist_ok=True)
    clean_path = OUT / f"{stem}_clean_strip.png"
    short_path = OUT / f"{stem}_short_strip.png"
    mask_path = OUT / f"{stem}_polish_mask.png"
    pack_strip(clean_frames, clean_path)
    pack_strip(short_frames, short_path)
    mask.save(mask_path)

    def _bg(strip: Image.Image, name: str) -> Path:
        canvas = Image.new("RGBA", strip.size, (*PINK, 255))
        canvas.alpha_composite(strip.convert("RGBA"))
        dest = OUT / name
        canvas.convert("RGB").save(dest, quality=92)
        return dest

    clean_jpg = _bg(Image.open(clean_path), f"{stem}_clean.jpg")
    short_jpg = _bg(Image.open(short_path), f"{stem}_short.jpg")

    overlay = Image.new("RGBA", short_frames[-1].size, (255, 70, 140, 0))
    overlay.putalpha(mask.split()[-1].point(lambda v: int(v * 0.92)))
    polish = Image.alpha_composite(short_frames[-1], overlay)
    polish_jpg = _bg(polish, f"{stem}_polish.jpg")

    # Zoom tip of dirty vs clean for dirt style check.
    tip = _tip_zoom(clean_frames[0], nail0)
    tip.save(OUT / f"{stem}_dirt_zoom.png")
    tip_canvas = Image.new("RGBA", tip.size, (*PINK, 255))
    tip_canvas.alpha_composite(tip)
    tip_canvas.convert("RGB").save(OUT / f"{stem}_dirt_zoom.jpg", quality=92)

    tip_short = _tip_zoom(short_frames[-1], nail_mask_light(short_frames[-1]) | nail0)
    tip_short_c = Image.new("RGBA", tip_short.size, (*PINK, 255))
    tip_short_c.alpha_composite(tip_short)
    tip_short_c.convert("RGB").save(OUT / f"{stem}_short_zoom.jpg", quality=92)

    print(stem, "nail px", int(nail0.sum()), "->", clean_jpg.name)
    return {
        "clean": clean_jpg,
        "short": short_jpg,
        "polish": polish_jpg,
        "dirt_zoom": OUT / f"{stem}_dirt_zoom.jpg",
    }


def _tip_zoom(cell: Image.Image, nail: np.ndarray) -> Image.Image:
    if not nail.any():
        return cell.copy()
    nys, nxs = np.where(nail)
    box = (
        max(0, int(nxs.min()) - 24),
        max(0, int(nys.min()) - 20),
        min(cell.width, int(nxs.max()) + 24),
        min(cell.height, int(nys.max()) + 16),
    )
    return cell.crop(box)


def contact_sheet() -> Path:
    """One page: C3 pinky ref + light pinky/middle/thumb clean+short."""
    c3_clean = even_cells(Image.open(IMAGES / "pinky_clean_dark.png"))
    c3_short = even_cells(Image.open(IMAGES / "pinky_short_dark.png"))
    rows: list[tuple[str, list[Image.Image]]] = [
        ("C3 pinky dirty→clean (ref)", c3_clean),
        ("C3 pinky long→short (ref)", c3_short),
    ]
    for stem, label in (
        ("pinky", "Light pinky"),
        ("middle", "Light middle (ring+index share)"),
        ("thumb", "Light thumb"),
    ):
        rows.append((f"{label} dirty→clean", even_cells(Image.open(OUT / f"{stem}_clean_strip.png"))))
        rows.append((f"{label} long→short", even_cells(Image.open(OUT / f"{stem}_short_strip.png"))))

    cell_w, cell_h = 220, 520
    pad = 12
    label_h = 28
    cols = 4
    width = pad * 2 + cols * cell_w + (cols - 1) * 8
    height = pad * 2 + len(rows) * (cell_h + label_h + 10)
    page = Image.new("RGB", (width, height), (40, 36, 42))
    draw = ImageDraw.Draw(page)
    try:
        font = ImageFont.truetype("arial.ttf", 16)
    except OSError:
        font = ImageFont.load_default()

    y = pad
    for title, frames in rows:
        draw.text((pad, y), title, fill=(255, 230, 240), font=font)
        y += label_h
        x = pad
        for frame in frames[:4]:
            fr = frame.convert("RGBA")
            scale = min(cell_w / fr.width, cell_h / fr.height)
            nw, nh = max(1, round(fr.width * scale)), max(1, round(fr.height * scale))
            scaled = fr.resize((nw, nh), Image.LANCZOS)
            bg = Image.new("RGBA", (cell_w, cell_h), (*PINK, 255))
            bg.paste(scaled, ((cell_w - nw) // 2, (cell_h - nh) // 2), scaled)
            page.paste(bg.convert("RGB"), (x, y))
            x += cell_w + 8
        y += cell_h + 10

    dest = OUT / "CONTACT_SHEET_light_vs_c3.jpg"
    page.save(dest, quality=90)
    print("contact", dest)
    return dest


def main() -> None:
    REVIEW.mkdir(parents=True, exist_ok=True)
    for stem in ("pinky", "middle", "thumb"):
        build_digit(stem)
    contact_sheet()
    print("Approval folder:", OUT)


if __name__ == "__main__":
    main()
