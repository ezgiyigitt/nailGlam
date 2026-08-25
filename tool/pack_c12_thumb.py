"""Pack approved thumb clean + short strips into C12 light-hand cells + polish mask."""

from __future__ import annotations

import shutil
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "tool"))
from make_zeynep_nail_sheets import (  # noqa: E402
    PINKY_CELL,
    even_cells,
    pack_strip,
    plate_region,
    polish_mask_from_nail,
)
from pack_c12_pinky_cut import _defringe, _plate  # noqa: E402
from pack_c12_pinky_polish import short_nail_plate  # noqa: E402
from pack_c12_pinky_stages import _bbox, _place  # noqa: E402
from pack_zeynep_customer import _key_auto  # noqa: E402

CURSOR = Path(
    r"C:\Users\Ezgi\.cursor\projects\c-Users-Ezgi-Documents-GitHub-nailGlam\assets"
)
SRC = REPO / "tool" / "review_light_nails" / "src"
OUT = REPO / "tool" / "review_light_nails" / "approval"
IMG = REPO / "assets" / "images"
PINK = (255, 182, 193)

# Dedicated thumb strips — NOT the pinky strips shared by ring/middle/index/pinky.
CLEAN_SRC = CURSOR / "c12_thumb_clean_strip.jpg"
SHORT_SRC = CURSOR / "c12_thumb_short_strip.png"


def _preview(image: Image.Image, dest: Path) -> None:
    canvas = Image.new("RGBA", image.size, (*PINK, 255))
    canvas.alpha_composite(image.convert("RGBA"))
    dest.parent.mkdir(parents=True, exist_ok=True)
    canvas.convert("RGB").save(dest, quality=92)


def _split_strip(strip: Image.Image, n: int = 4) -> list[Image.Image]:
    w, h = strip.size
    cw = w // n
    return [strip.crop((i * cw, 0, (i + 1) * cw if i < n - 1 else w, h)) for i in range(n)]


def _pack_frames(raw_frames: list[Image.Image]) -> list[Image.Image]:
    keyed = [_defringe(_key_auto(f.convert("RGBA"))) for f in raw_frames]
    master = np.asarray(keyed[0])
    box = _bbox(master)
    cell = PINKY_CELL
    return [_place(frame, cell, box) for frame in keyed]


def _final_y_from_short(cell: Image.Image) -> int:
    """Short frame already shows the clipped nail — use its free edge."""
    plate = _plate(cell)
    ys = np.flatnonzero(plate.any(axis=1))
    if ys.size == 0:
        raise RuntimeError("no nail plate on short frame")
    return int(ys.max())


def _build_mask(short_strip: Image.Image) -> Image.Image:
    f3 = even_cells(short_strip)[3]
    final_y = _final_y_from_short(f3)
    plate = short_nail_plate(f3, final_y)
    mask = polish_mask_from_nail(plate, f3)
    ma = np.asarray(mask.convert("RGBA")).copy()
    solid = plate.copy()
    feather = Image.fromarray(solid.astype(np.uint8) * 255, "L").filter(
        ImageFilter.GaussianBlur(0.4)
    )
    soft = np.asarray(feather).astype(np.int16)
    ma[..., :3] = 255
    ma[..., 3] = np.where(solid, 255, np.where(soft > 24, soft, 0)).astype(np.uint8)
    return Image.fromarray(ma, "RGBA")


def main() -> None:
    if not CLEAN_SRC.exists() or not SHORT_SRC.exists():
        raise FileNotFoundError(f"missing thumb strips: {CLEAN_SRC} / {SHORT_SRC}")

    SRC.mkdir(parents=True, exist_ok=True)
    shutil.copy2(CLEAN_SRC, SRC / "c12_thumb_clean_user.jpg")
    shutil.copy2(SHORT_SRC, SRC / "c12_thumb_short_user.png")

    clean_frames = _pack_frames(_split_strip(Image.open(CLEAN_SRC)))
    short_frames = _pack_frames(_split_strip(Image.open(SHORT_SRC)))

    OUT.mkdir(parents=True, exist_ok=True)
    clean_dest = OUT / "thumb_clean_light_c12.png"
    short_dest = OUT / "thumb_short_light_c12.png"
    pack_strip(clean_frames, clean_dest)
    pack_strip(short_frames, short_dest)

    mask = _build_mask(Image.open(short_dest))
    mask_dest = OUT / "thumb_nail_mask_light_c12.png"
    mask.save(mask_dest)

    _preview(Image.open(clean_dest), OUT / "thumb_clean_light_c12_preview.jpg")
    _preview(Image.open(short_dest), OUT / "thumb_short_light_c12_preview.jpg")
    _preview(mask, OUT / "thumb_nail_mask_light_c12_preview.jpg")

    f3 = even_cells(Image.open(short_dest))[3]
    from pack_c12_pinky_polish import POLISH, _apply_polish, _zoom_box

    box = _zoom_box(f3)
    zw, zh = (box[2] - box[0]) * 2, (box[3] - box[1]) * 2
    zoom = f3.crop(box).resize((zw, zh), Image.NEAREST)
    zm = mask.crop(box).resize((zw, zh), Image.NEAREST)
    _preview(_apply_polish(zoom, zm, POLISH[0][1]), OUT / "thumb_cut_zoom_f3_polish.jpg")

    for name, src in (
        ("thumb_clean_light.png", clean_dest),
        ("thumb_short_light.png", short_dest),
        ("thumb_nail_mask_light.png", mask_dest),
    ):
        shutil.copy2(src, IMG / name)

    plate = plate_region(mask)
    print("clean", clean_dest, Image.open(clean_dest).size)
    print("short", short_dest, Image.open(short_dest).size)
    print("mask plate xywh", plate)
    print("installed", IMG / "thumb_clean_light.png")


if __name__ == "__main__":
    main()
