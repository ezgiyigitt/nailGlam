"""Key black backgrounds, pack even transparent sheets, write game assets."""

from __future__ import annotations

from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image

REVIEW = Path(r"C:\Users\Ezgi\Documents\GitHub\nailGlam\build\review_sprites")
CELLS = REVIEW / "cells"
OUT = Path(r"C:\Users\Ezgi\Documents\GitHub\nailGlam\assets\images")

WALK_TARGET_H = 780
GUTTER_X = 0.28
PAD_TOP = 20
PAD_BOTTOM = 28


def flood_key_black(im: Image.Image, luma_max: int = 36) -> Image.Image:
    arr = np.array(im.convert("RGBA"))
    h, w = arr.shape[:2]
    rgb = arr[:, :, :3].astype(np.int16)
    dark = (rgb.max(axis=2) <= luma_max) | (arr[:, :, 3] < 16)
    visited = np.zeros((h, w), dtype=np.uint8)
    q: deque[tuple[int, int]] = deque()

    def try_push(x: int, y: int) -> None:
        if dark[y, x] and not visited[y, x]:
            visited[y, x] = 1
            q.append((x, y))

    for x in range(w):
        try_push(x, 0)
        try_push(x, h - 1)
    for y in range(h):
        try_push(0, y)
        try_push(w - 1, y)

    while q:
        x, y = q.popleft()
        arr[y, x, 3] = 0
        if x > 0:
            try_push(x - 1, y)
        if x + 1 < w:
            try_push(x + 1, y)
        if y > 0:
            try_push(x, y - 1)
        if y + 1 < h:
            try_push(x, y + 1)

    return Image.fromarray(arr)


def opaque_bbox(im: Image.Image) -> tuple[int, int, int, int]:
    a = np.array(im)
    vis = a[:, :, 3] > 16
    ys, xs = np.where(vis)
    if xs.size == 0:
        raise ValueError("empty after key")
    return int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1


def crop_opaque(im: Image.Image, pad: int = 0) -> Image.Image:
    x0, y0, x1, y1 = opaque_bbox(im)
    cropped = im.crop((x0, y0, x1, y1))
    if pad <= 0:
        return cropped
    out = Image.new("RGBA", (cropped.width + pad * 2, cropped.height + pad * 2), (0, 0, 0, 0))
    out.paste(cropped, (pad, pad), cropped)
    return out


def load_cell(name: str) -> Image.Image:
    return crop_opaque(flood_key_black(Image.open(CELLS / name)))


def scale_by_ratio(im: Image.Image, ratio: float) -> Image.Image:
    new_w = max(1, int(round(im.width * ratio)))
    new_h = max(1, int(round(im.height * ratio)))
    return im.resize((new_w, new_h), Image.Resampling.LANCZOS)


def pack_sheet(
    figures: list[Image.Image],
    *,
    even_height: bool,
    target_h: int = WALK_TARGET_H,
) -> Image.Image:
    if even_height:
        scaled = [scale_by_ratio(fig, target_h / fig.height) for fig in figures]
    else:
        ratio = target_h / figures[0].height
        scaled = [scale_by_ratio(fig, ratio) for fig in figures]
    max_w = max(im.width for im in scaled)
    max_h = max(im.height for im in scaled)
    cell_w = int(round(max_w * (1 + 2 * GUTTER_X)))
    cell_h = max_h + PAD_TOP + PAD_BOTTOM
    foot_y = cell_h - PAD_BOTTOM
    sheet = Image.new("RGBA", (cell_w * len(scaled), cell_h), (0, 0, 0, 0))
    for i, fig in enumerate(scaled):
        x = i * cell_w + (cell_w - fig.width) // 2
        y = foot_y - fig.height
        sheet.paste(fig, (x, y), fig)
    return sheet


def save(im: Image.Image, name: str) -> Path:
    path = OUT / name
    im.save(path, format="PNG", compress_level=6)
    x0, y0, x1, y1 = opaque_bbox(im)
    print(
        "%s  %dx%d  opaque=(%d,%d)-(%d,%d)  content=%dx%d"
        % (name, im.width, im.height, x0, y0, x1, y1, x1 - x0, y1 - y0)
    )
    return path


walk = [load_cell("walk_%d.png" % i) for i in range(4)]
stop = [load_cell("turn_0.png")]
turn = [load_cell("turn_%d.png" % i) for i in range(4)]
sit = [load_cell("sit_%d.png" % i) for i in range(4)]

print("walk0=%dx%d  sit0=%dx%d" % (walk[0].width, walk[0].height, sit[0].width, sit[0].height))

walk_sheet = pack_sheet(walk, even_height=True)
stop_sheet = pack_sheet(stop, even_height=True)
turn_sheet = pack_sheet(turn, even_height=True)
sit_sheet = pack_sheet(sit, even_height=False)

save(walk_sheet, "customer-walk-v1.png")
save(stop_sheet, "customer1_stop.png")
save(turn_sheet, "customer1_sit.png")
save(sit_sheet, "customer1_wait.png")

chair = crop_opaque(flood_key_black(Image.open(REVIEW / "customer_chair.png")), pad=8)
table = crop_opaque(flood_key_black(Image.open(REVIEW / "customer_table.png")), pad=8)
save(chair, "salon_chair.png")
save(table, "table.png")

print("PAD_BOTTOM", PAD_BOTTOM)
print("walk cell", walk_sheet.width // 4, walk_sheet.height)
print("stop cell", stop_sheet.width, stop_sheet.height)
print("turn cell", turn_sheet.width // 4, turn_sheet.height)
print("sit cell", sit_sheet.width // 4, sit_sheet.height)
print("chair", chair.size)
print("table", table.size)
print("suggested displayScale", round(1110 / walk_sheet.height, 4))
