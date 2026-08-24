"""Pack review spritesheets with even cells, shared foot baseline, and gutters."""

from pathlib import Path

import numpy as np
from PIL import Image

ASSETS = Path(r"C:\Users\Ezgi\.cursor\projects\c-Users-Ezgi-Documents-GitHub-nailGlam\assets")
PREVIEW = Path(r"C:\Users\Ezgi\Documents\GitHub\nailGlam\build\frame_preview")
OUT = Path(r"C:\Users\Ezgi\Documents\GitHub\nailGlam\build\review_sprites")
OUT.mkdir(parents=True, exist_ok=True)

TARGET_HEIGHT = 780
GUTTER_X = 0.38  # extra empty width each side, as fraction of figure width
PAD_TOP = 48
PAD_BOTTOM = 36


def vis_mask(arr):
    rgb = arr[:, :, :3].astype(np.int16)
    alpha = arr[:, :, 3] if arr.shape[2] == 4 else np.full(arr.shape[:2], 255)
    return (alpha > 16) & (rgb.sum(axis=2) >= 40)


def extract_person(im: Image.Image) -> Image.Image:
    a = np.array(im.convert("RGBA"))
    vis = vis_mask(a)
    ys, xs = np.where(vis)
    if xs.size == 0:
        raise ValueError("empty sprite")
    x0, x1, y0, y1 = int(xs.min()), int(xs.max()), int(ys.min()), int(ys.max())
    return Image.fromarray(a[y0 : y1 + 1, x0 : x1 + 1])


def cell_from_sheet(path: Path, index: int, cols: int) -> Image.Image:
    im = Image.open(path).convert("RGBA")
    w = im.width // cols
    return extract_person(im.crop((index * w, 0, (index + 1) * w, im.height)))


def scale_to_height(im: Image.Image, height: int) -> Image.Image:
    ratio = height / im.height
    new_w = max(1, int(round(im.width * ratio)))
    return im.resize((new_w, height), Image.Resampling.LANCZOS)


def pack(name: str, figures: list[Image.Image], *, lock_scale_to_first: bool) -> Path:
    cropped = [extract_person(fig) for fig in figures]
    if lock_scale_to_first:
        ratio = TARGET_HEIGHT / cropped[0].height
        scaled = [
            im.resize(
                (max(1, int(round(im.width * ratio))), max(1, int(round(im.height * ratio)))),
                Image.Resampling.LANCZOS,
            )
            for im in cropped
        ]
    else:
        scaled = [scale_to_height(im, TARGET_HEIGHT) for im in cropped]

    max_w = max(im.width for im in scaled)
    max_h = max(im.height for im in scaled)
    cell_w = int(round(max_w * (1 + 2 * GUTTER_X)))
    cell_h = max_h + PAD_TOP + PAD_BOTTOM
    foot_y = cell_h - PAD_BOTTOM
    sheet = Image.new("RGBA", (cell_w * len(scaled), cell_h), (0, 0, 0, 255))
    for i, fig in enumerate(scaled):
        x = i * cell_w + (cell_w - fig.width) // 2
        y = foot_y - fig.height
        sheet.paste(fig, (x, y), fig)
    out = OUT / name
    sheet.save(out)
    print("%s  %dx%d  cells=%d  cell=%dx%d" % (name, sheet.width, sheet.height, len(scaled), cell_w, cell_h))
    return out


walk_figs = [
    extract_person(Image.open(ASSETS / "walk_01_contact_right.png")),
    cell_from_sheet(ASSETS / "walk_passing_pair.png", 0, 2),
    extract_person(Image.open(ASSETS / "walk_02_pass_left.png")),
    extract_person(Image.open(ASSETS / "walk_04_pass_right.png")),
]

stop_fig = extract_person(Image.open(ASSETS / "stop_stand.png"))

turn_figs = [
    stop_fig,
    extract_person(Image.open(ASSETS / "turn_02_mid.png")),
    extract_person(Image.open(ASSETS / "turn_03_almost_front.png")),
    extract_person(Image.open(ASSETS / "turn_04_front.png")),
]

sit_figs = [cell_from_sheet(ASSETS / "sheet_sit_4.png", i, 4) for i in range(4)]

pack("customer_walk.png", walk_figs, lock_scale_to_first=False)
pack("customer_stop.png", [stop_fig], lock_scale_to_first=False)
pack("customer_turn.png", turn_figs, lock_scale_to_first=False)
pack("customer_sit.png", sit_figs, lock_scale_to_first=True)

preview_dir = OUT / "cells"
preview_dir.mkdir(exist_ok=True)
for label, figs in [("walk", walk_figs), ("turn", turn_figs), ("sit", sit_figs)]:
    for i, fig in enumerate(figs):
        extract_person(fig).save(preview_dir / ("%s_%d.png" % (label, i)))
print("done", OUT)
