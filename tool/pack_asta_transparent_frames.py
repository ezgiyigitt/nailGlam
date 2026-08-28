"""Chroma-key Asta magenta frames -> transparent review cells/strips.

Does NOT write into assets/images — review only.
"""

from __future__ import annotations

from pathlib import Path

import numpy as np
from PIL import Image

SRC = Path(r"C:\Users\Ezgi\.cursor\projects\c-Users-Ezgi-Documents-GitHub-nailGlam\assets")
OUT = Path(__file__).resolve().parent / "review_asta_new_frames"
CELL_W, CELL_H = 432, 433


def chroma_key(im: Image.Image) -> Image.Image:
    """Remove magenta/pink chroma key -> RGBA transparent."""
    arr = np.asarray(im.convert("RGB"), dtype=np.float32)
    r, g, b = arr[..., 0], arr[..., 1], arr[..., 2]
    magenta = (
        (r > 140)
        & (b > 140)
        & (g < 0.72 * ((r + b) / 2))
        & (((r + b) / 2) - g > 35)
    )
    hot = (r > 200) & (b > 160) & (g < 120)
    key = magenta | hot
    dist = np.sqrt((r - 255.0) ** 2 + (g - 0.0) ** 2 + (b - 255.0) ** 2)
    soft = np.clip((dist - 90.0) / 70.0, 0.0, 1.0)
    soft = np.where(key, 0.0, soft)
    lum = 0.2126 * r + 0.7152 * g + 0.0722 * b
    keep_dark = (lum < 90) & (g + 40 >= np.minimum(r, b))
    soft = np.where(keep_dark, np.maximum(soft, 0.85), soft)
    alpha = (soft * 255.0).astype(np.uint8)
    rgba = np.dstack([arr.astype(np.uint8), alpha])
    rgba[alpha < 8, :3] = 0
    return Image.fromarray(rgba, "RGBA")


def place_in_cell(fig: Image.Image) -> Image.Image:
    alpha = np.asarray(fig.split()[3]) > 8
    ys, xs = np.where(alpha)
    if ys.size == 0:
        return Image.new("RGBA", (CELL_W, CELL_H), (0, 0, 0, 0))
    cropped = fig.crop(
        (int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1)
    )
    target_h = int(CELL_H * 0.92)
    scale = target_h / cropped.height
    tw = max(1, int(round(cropped.width * scale)))
    th = max(1, int(round(cropped.height * scale)))
    if tw > CELL_W - 16:
        scale = (CELL_W - 16) / cropped.width
        tw = max(1, int(round(cropped.width * scale)))
        th = max(1, int(round(cropped.height * scale)))
    resized = cropped.resize((tw, th), Image.LANCZOS)
    cell = Image.new("RGBA", (CELL_W, CELL_H), (0, 0, 0, 0))
    x = (CELL_W - tw) // 2
    y = max(4, CELL_H - th - 6)
    cell.paste(resized, (x, y), resized)
    return cell


def checker_preview(cell: Image.Image) -> Image.Image:
    yy, xx = np.indices((CELL_H, CELL_W))
    lite = ((xx // 16) + (yy // 16)) % 2 == 0
    base = np.zeros((CELL_H, CELL_W, 4), dtype=np.uint8)
    base[lite] = (230, 230, 238, 255)
    base[~lite] = (190, 190, 205, 255)
    chk = Image.fromarray(base, "RGBA")
    chk.alpha_composite(cell)
    return chk


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    groups = {
        "walk": [f"asta_walk_f{i}_key.png" for i in range(4)],
        "turn": [f"asta_turn_f{i}_key.png" for i in range(4)],
        "sit": [f"asta_sit_f{i}_key.png" for i in range(4)],
    }
    for group, names in groups.items():
        cells: list[Image.Image] = []
        for i, name in enumerate(names):
            keyed = chroma_key(Image.open(SRC / name))
            cell = place_in_cell(keyed)
            cell.save(OUT / f"customer3_{group}_f{i}.png")
            checker_preview(cell).save(OUT / f"preview_{group}_f{i}.png")
            opaque = int((np.asarray(cell.split()[3]) > 8).sum())
            print(f"{group} f{i}: opaque={opaque} rgba ok")
            cells.append(cell)
        strip = Image.new("RGBA", (CELL_W * 4, CELL_H), (0, 0, 0, 0))
        for i, cell in enumerate(cells):
            strip.paste(cell, (i * CELL_W, 0), cell)
        strip.save(OUT / f"customer3_{group}_strip.png")
        print(f"strip {group}: {strip.size}")
    print("OUT", OUT)


if __name__ == "__main__":
    main()
