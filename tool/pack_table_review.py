"""Extract the new table and fit-check onto black review sprites."""

from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(r"C:\Users\Ezgi\.cursor\projects\c-Users-Ezgi-Documents-GitHub-nailGlam\assets")
OUT = Path(r"C:\Users\Ezgi\Documents\GitHub\nailGlam\build\review_sprites")
OUT.mkdir(parents=True, exist_ok=True)


def key_black(im, thresh=28):
    arr = np.array(im.convert("RGBA"))
    rgb = arr[:, :, :3].astype(np.int16)
    dark = rgb.sum(axis=2) < thresh * 3
    arr[dark, 3] = 0
    return arr


def extract(arr):
    vis = arr[:, :, 3] > 16
    ys, xs = np.where(vis)
    return Image.fromarray(arr[int(ys.min()) : int(ys.max()) + 1, int(xs.min()) : int(xs.max()) + 1])


def pad_on_black(fig, pad=48):
    sheet = Image.new("RGBA", (fig.width + pad * 2, fig.height + pad * 2), (0, 0, 0, 255))
    sheet.paste(fig, (pad, pad), fig)
    return sheet


jobs = {
    "customer_table.png": ROOT / "manicure_table_empty.png",
    "sit_chair_table_fit.png": ROOT / "sit_chair_table_fit.png",
}

for name, src in jobs.items():
    fig = extract(key_black(Image.open(src)))
    out = pad_on_black(fig)
    dest = OUT / name
    out.save(dest)
    print(dest, out.size, "content", fig.size)
