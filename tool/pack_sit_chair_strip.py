"""Pack the new sit-on-chair strip into even review cells."""

from pathlib import Path

import numpy as np
from PIL import Image

SRC = Path(r"C:\Users\Ezgi\.cursor\projects\c-Users-Ezgi-Documents-GitHub-nailGlam\assets\sheet_sit_on_chair_4.png")
OUT = Path(r"C:\Users\Ezgi\Documents\GitHub\nailGlam\build\review_sprites")
OUT.mkdir(parents=True, exist_ok=True)

TARGET_H = 820
GUTTER = 0.28
PAD_TOP = 36
PAD_BOTTOM = 40


def key_black(arr, thresh=32):
    rgb = arr[:, :, :3].astype(np.int16)
    dark = rgb.sum(axis=2) < thresh * 3
    arr = arr.copy()
    arr[dark, 3] = 0
    return arr


def extract_cell(arr):
    vis = arr[:, :, 3] > 16
    ys, xs = np.where(vis)
    if xs.size == 0:
        raise ValueError("empty")
    return Image.fromarray(arr[int(ys.min()) : int(ys.max()) + 1, int(xs.min()) : int(xs.max()) + 1])


im = Image.open(SRC).convert("RGBA")
a = key_black(np.array(im))
w = a.shape[1] // 4
figs = []
for i in range(4):
    figs.append(extract_cell(a[:, i * w : (i + 1) * w]))
    figs[-1].save(OUT / "cells" / ("sit_chair_%d.png" % i))

scaled = []
for fig in figs:
    ratio = TARGET_H / fig.height
    scaled.append(
        fig.resize(
            (max(1, int(round(fig.width * ratio))), TARGET_H),
            Image.Resampling.LANCZOS,
        )
    )

max_w = max(im.width for im in scaled)
cell_w = int(round(max_w * (1 + 2 * GUTTER)))
cell_h = TARGET_H + PAD_TOP + PAD_BOTTOM
sheet = Image.new("RGBA", (cell_w * 4, cell_h), (0, 0, 0, 255))
for i, fig in enumerate(scaled):
    x = i * cell_w + (cell_w - fig.width) // 2
    y = PAD_TOP
    sheet.paste(fig, (x, y), fig)

out = OUT / "customer_sit_with_chair.png"
sheet.save(out)
print(out, sheet.size, "cell", cell_w, cell_h)
