"""Slice gait_profile_6 and measure pose variety."""

from pathlib import Path

import numpy as np
from PIL import Image

SRC = Path(r"C:\Users\Ezgi\.cursor\projects\c-Users-Ezgi-Documents-GitHub-nailGlam\assets\gait_profile_6.png")
OUT = Path(r"C:\Users\Ezgi\Documents\GitHub\nailGlam\build\review_sprites\cells")
OUT.mkdir(parents=True, exist_ok=True)

im = Image.open(SRC).convert("RGBA")
a = np.array(im)
rgb = a[:, :, :3].astype(np.int16)
vis = (a[:, :, 3] > 16) & (rgb.max(axis=2) > 36)
w = im.width // 6
print("sheet", im.size, "cell_w", w)
for i in range(6):
    cell = a[:, i * w : (i + 1) * w]
    v = vis[:, i * w : (i + 1) * w]
    ys, xs = np.where(v)
    x0, x1 = int(xs.min()), int(xs.max())
    y0, y1 = int(ys.min()), int(ys.max())
    fig = Image.fromarray(cell[y0 : y1 + 1, x0 : x1 + 1])
    dest = OUT / ("gait_%d.png" % (i + 1))
    fig.save(dest)
    print("gait_%d  content %dx%d  y0=%d" % (i + 1, fig.width, fig.height, y0))
