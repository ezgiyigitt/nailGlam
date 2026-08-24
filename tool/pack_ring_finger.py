"""Pack approved ring-finger frames into game sheets. Keys black backdrops."""

from __future__ import annotations

from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

REPO = Path(__file__).resolve().parent.parent
SRC = Path(
    r"C:\Users\Ezgi\.cursor\projects\c-Users-Ezgi-Documents-GitHub-nailGlam\assets"
)
OUT = REPO / "assets" / "images"

CLEAN_W, CLEAN_H = 355, 879
SHORT_W, SHORT_H = 384, 1024
TARGET_SHORT_W = 310


def _key_black(image: Image.Image, thresh: int = 28) -> Image.Image:
    rgb = image.convert("RGB")
    canvas = rgb.copy()
    sentinel = (1, 254, 2)
    w, h = canvas.size
    for seed in ((0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1), (w // 2, 0)):
        ImageDraw.floodfill(canvas, seed, sentinel, thresh=thresh)
    marked = np.asarray(canvas)
    bg = np.all(marked == np.array(sentinel), axis=-1)
    out = np.asarray(image.convert("RGBA")).copy()
    out[bg, 3] = 0
    return Image.fromarray(out, "RGBA")


def _opaque_bbox(im: Image.Image) -> tuple[int, int, int, int]:
    a = np.asarray(im)[..., 3]
    ys, xs = np.where(a > 12)
    return int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1


def _place(src: Image.Image, cell: tuple[int, int], target_w: int) -> Image.Image:
    cropped = src.crop(_opaque_bbox(src))
    scale = min(target_w / cropped.width, (cell[1] - 4) / cropped.height)
    new_w = max(1, int(round(cropped.width * scale)))
    new_h = max(1, int(round(cropped.height * scale)))
    resized = cropped.resize((new_w, new_h), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", cell, (0, 0, 0, 0))
    x = (cell[0] - new_w) // 2
    y = 0
    canvas.paste(resized, (x, y), resized)
    return canvas


def _nail_mask(frame: Image.Image) -> Image.Image:
    arr = np.asarray(frame.convert("RGBA"))
    rgb = arr[..., :3].astype(np.float32)
    a = arr[..., 3]
    lum = 0.21 * rgb[..., 0] + 0.72 * rgb[..., 1] + 0.07 * rgb[..., 2]
    opaque = a > 10
    h, w = lum.shape
    cx = w // 2
    ys = np.where(opaque.any(1))[0]
    tip_y = int(ys.max())
    wall = opaque & (lum < 128)
    keep = np.zeros((h, w), dtype=bool)
    for y in range(tip_y, 280, -1):
        xs = np.where(opaque[y])[0]
        if xs.size < 8:
            continue
        if xs.size < 52:
            keep[y, xs[0] + 1 : xs[-1]] = True
            continue
        lw = np.where(wall[y, :cx])[0]
        rw = np.where(wall[y, cx:])[0]
        if lw.size == 0 or rw.size == 0:
            if keep.any():
                break
            continue
        left = int(lw[-1])
        right = int(cx + rw[0])
        if xs[-1] - xs[0] > 220 and (left > cx - 36 or right < cx + 36):
            break
        if right - left < 40:
            continue
        keep[y, left + 1 : right] = True
    mask = Image.fromarray((keep.astype(np.uint8) * 255), "L")
    mask = (
        mask.filter(ImageFilter.MaxFilter(3))
        .filter(ImageFilter.MinFilter(3))
        .filter(ImageFilter.GaussianBlur(0.6))
    )
    m = np.asarray(mask)
    out = np.zeros((h, w, 4), dtype=np.uint8)
    out[..., :3] = 255
    out[..., 3] = np.where(m > 40, 255, 0)
    return Image.fromarray(out, "RGBA")


def _strip(cells: list[Image.Image], path: Path) -> None:
    w, h = cells[0].size
    sheet = Image.new("RGBA", (w * len(cells), h), (0, 0, 0, 0))
    for i, cell in enumerate(cells):
        sheet.paste(cell, (i * w, 0), cell)
    sheet.save(path)
    print("wrote", path.name, sheet.size)


def main() -> None:
    keyed = {
        name: _key_black(Image.open(SRC / name))
        for name in (
            *(f"ring_clean_{i}.png" for i in range(4)),
            *(f"ring_short_{i}.png" for i in range(4)),
        )
    }
    clean_cells = [
        _place(keyed[f"ring_clean_{i}.png"], (CLEAN_W, CLEAN_H), 330)
        for i in range(4)
    ]
    short_cells = [
        _place(keyed[f"ring_short_{i}.png"], (SHORT_W, SHORT_H), TARGET_SHORT_W)
        for i in range(4)
    ]
    _strip(clean_cells, OUT / "ring_nail_clean.png")
    _strip(short_cells, OUT / "ring_short_nail.png")
    mask_src = _key_black(Image.open(SRC / "ring_nail_mask.png"), thresh=40)
    # White plate only.
    arr = np.asarray(mask_src.convert("RGBA"))
    lum = arr[..., 0].astype(np.int16)
    plate = (arr[..., 3] > 20) & (lum > 180)
    ys, xs = np.where(plate)
    box = (int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1)
    plate_im = Image.fromarray(arr).crop(box)
    sx0, sy0, sx1, sy1 = _opaque_bbox(short_cells[3])
    target_h = max(90, int((sy1 - sy0) * 0.46))
    scale_m = target_h / plate_im.height
    mw = max(1, int(round(plate_im.width * scale_m)))
    mh = max(1, int(round(plate_im.height * scale_m)))
    plate_im = plate_im.resize((mw, mh), Image.Resampling.LANCZOS)
    mask = Image.new("RGBA", (SHORT_W, SHORT_H), (0, 0, 0, 0))
    mx = (SHORT_W - mw) // 2
    my = sy1 - mh - 4
    mask.paste(plate_im, (mx, my), plate_im)
    # Force white RGB, keep alpha.
    m = np.asarray(mask)
    out = np.zeros_like(m)
    out[..., :3] = 255
    out[..., 3] = np.where(m[..., 3] > 40, 255, 0)
    mask = Image.fromarray(out, "RGBA")
    mask.save(OUT / "ring_nail_mask.png")
    print("mask opaque", int(out[..., 3].sum() / 255), "at", mx, my, mw, mh)
    for i, cell in enumerate(short_cells):
        b = _opaque_bbox(cell)
        print("short", i, "bbox", b, "w", b[2] - b[0], "h", b[3] - b[1])
    for i, cell in enumerate(clean_cells):
        b = _opaque_bbox(cell)
        print("clean", i, "bbox", b, "w", b[2] - b[0], "h", b[3] - b[1])


if __name__ == "__main__":
    main()
