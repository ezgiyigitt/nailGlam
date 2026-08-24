"""Composite sit frames onto the matching empty chair with keyed alpha."""

from pathlib import Path

import numpy as np
from PIL import Image

ASSETS = Path(r"C:\Users\Ezgi\.cursor\projects\c-Users-Ezgi-Documents-GitHub-nailGlam\assets")
SIT_CELLS = Path(r"C:\Users\Ezgi\Documents\GitHub\nailGlam\build\review_sprites\cells")
OUT = Path(r"C:\Users\Ezgi\Documents\GitHub\nailGlam\build\review_sprites")


def key_black(im, thresh=28):
    a = np.array(im.convert("RGBA"))
    rgb = a[:, :, :3].astype(np.int16)
    dark = rgb.sum(axis=2) < thresh * 3
    a[dark, 3] = 0
    return Image.fromarray(a)


def vis_mask(arr):
    return arr[:, :, 3] > 16


def extract(im):
    a = np.array(key_black(im))
    vis = vis_mask(a)
    ys, xs = np.where(vis)
    return Image.fromarray(a[int(ys.min()) : int(ys.max()) + 1, int(xs.min()) : int(xs.max()) + 1])


def pink_seat_y(chair):
    a = np.array(chair)
    vis = vis_mask(a)
    pink = vis & (a[:, :, 0] > 140) & (a[:, :, 1] < 130) & (a[:, :, 2] > 70)
    counts = pink.sum(axis=1)
    return int(np.argmax(counts))


chair = extract(Image.open(ASSETS / "salon_chair_match.png"))
sits = [extract(Image.open(SIT_CELLS / ("sit_%d.png" % i))) for i in range(4)]
planted = extract(Image.open(ASSETS / "sit_on_chair.png"))

seat_y = pink_seat_y(chair)
# Scale seated figure so hip/thigh band lands on the seat.
# Use sit_3 height from head to feet vs chair: seated person should be ~ chair height.
ratio = chair.height / sits[3].height
sits = [
    im.resize(
        (max(1, int(round(im.width * ratio))), max(1, int(round(im.height * ratio)))),
        Image.Resampling.LANCZOS,
    )
    for im in sits
]

pad = 40
cell_w = max(chair.width, max(im.width for im in sits)) + pad * 2
cell_h = max(chair.height, max(im.height for im in sits)) + pad * 2
chair_x = (cell_w - chair.width) // 2
chair_y = cell_h - pad - chair.height
ground = chair_y + chair.height

sheet = Image.new("RGBA", (cell_w * 4, cell_h), (0, 0, 0, 255))
for i, fig in enumerate(sits):
    cell = Image.new("RGBA", (cell_w, cell_h), (0, 0, 0, 255))
    cell.paste(chair, (chair_x, chair_y), chair)
    fx = (cell_w - fig.width) // 2
    fy = ground - fig.height
    cell.paste(fig, (fx, fy), fig)
    sheet.paste(cell, (i * cell_w, 0))

sheet.save(OUT / "customer_sit_with_chair.png")
chair.save(OUT / "customer_chair.png")
planted.save(OUT / "customer_seated_on_chair.png")
print("seat_y", seat_y, "chair", chair.size, "sit3", sits[3].size, "sheet", sheet.size)
