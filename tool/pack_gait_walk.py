"""Pack the 6-frame profile walk: largest blob, shared feet, transparent."""

from __future__ import annotations

from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image

SRC = Path(r"C:\Users\Ezgi\.cursor\projects\c-Users-Ezgi-Documents-GitHub-nailGlam\assets\gait_profile_6.png")
OUT = Path(r"C:\Users\Ezgi\Documents\GitHub\nailGlam\assets\images\customer-walk-v1.png")
CELLS = Path(r"C:\Users\Ezgi\Documents\GitHub\nailGlam\build\review_sprites\cells")

WALK_TARGET_H = 780
GUTTER_X = 0.32
PAD_TOP = 24
PAD_BOTTOM = 32


def flood_key_black(im: Image.Image, luma_max: int = 36) -> np.ndarray:
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
        if x:
            try_push(x - 1, y)
        if x + 1 < w:
            try_push(x + 1, y)
        if y:
            try_push(x, y - 1)
        if y + 1 < h:
            try_push(x, y + 1)
    return arr


def largest_blob(arr: np.ndarray) -> Image.Image:
    vis = arr[:, :, 3] > 16
    h, w = vis.shape
    ys, xs = np.where(vis)
    if xs.size == 0:
        raise ValueError("empty")
    # BFS from the densest region: start at median of visible pixels.
    seed = (int(np.median(xs)), int(np.median(ys)))
    if not vis[seed[1], seed[0]]:
        seed = (int(xs[0]), int(ys[0]))
    seen = np.zeros((h, w), dtype=np.uint8)
    q: deque[tuple[int, int]] = deque([seed])
    seen[seed[1], seed[0]] = 1
    while q:
        x, y = q.popleft()
        for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
            if 0 <= nx < w and 0 <= ny < h and vis[ny, nx] and not seen[ny, nx]:
                seen[ny, nx] = 1
                q.append((nx, ny))
    keep = arr.copy()
    keep[seen == 0, 3] = 0
    ys, xs = np.where(seen == 1)
    return Image.fromarray(keep[int(ys.min()) : int(ys.max()) + 1, int(xs.min()) : int(xs.max()) + 1])


def scale(im: Image.Image, ratio: float) -> Image.Image:
    return im.resize(
        (max(1, int(round(im.width * ratio))), max(1, int(round(im.height * ratio)))),
        Image.Resampling.LANCZOS,
    )


sheet = Image.open(SRC)
keyed = flood_key_black(sheet)
cell_w = keyed.shape[1] // 6
figs: list[Image.Image] = []
for i in range(6):
    cell = keyed[:, i * cell_w : (i + 1) * cell_w]
    fig = largest_blob(cell)
    fig.save(CELLS / ("gait_%d.png" % (i + 1)))
    figs.append(fig)
    print("gait_%d  %dx%d" % (i + 1, fig.width, fig.height))

ratio = WALK_TARGET_H / figs[0].height
scaled = [scale(fig, ratio) for fig in figs]
max_w = max(im.width for im in scaled)
max_h = max(im.height for im in scaled)
cw = int(round(max_w * (1 + 2 * GUTTER_X)))
ch = max_h + PAD_TOP + PAD_BOTTOM
foot_y = ch - PAD_BOTTOM
out = Image.new("RGBA", (cw * 6, ch), (0, 0, 0, 0))
for i, fig in enumerate(scaled):
    x = i * cw + (cw - fig.width) // 2
    y = foot_y - fig.height
    out.paste(fig, (x, y), fig)
    print("  packed %d  y=%d  h=%d" % (i, y, fig.height))

tmp = OUT.with_suffix(".tmp.png")
out.save(tmp, format="PNG", compress_level=6)
try:
    OUT.unlink(missing_ok=True)
except OSError:
    pass
tmp.replace(OUT)
print("wrote", OUT, out.size, "cell", cw, ch, "ratio", round(ratio, 4))
print("displayScale", round(1110 / ch, 4), "footPad", PAD_BOTTOM)
