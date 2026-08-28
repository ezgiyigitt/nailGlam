"""Pack Asta walk/turn/sit with locked outfit+skin into assets/images.

Uses regenerated skin/outfit frames (navy ribbed crew + waist knot).
Head-locked; transparent; no Dart position changes.
"""

from __future__ import annotations

from pathlib import Path

import numpy as np
from PIL import Image

REPO = Path(__file__).resolve().parent.parent
GEN = Path(r"C:\Users\Ezgi\.cursor\projects\c-Users-Ezgi-Documents-GitHub-nailGlam\assets")
IMAGES = REPO / "assets" / "images"
REVIEW = REPO / "tool" / "review_asta_new_frames"
CELL_W, CELL_H = 432, 433
LOCK_HEAD_X, LOCK_HEAD_Y = 216, 11

SOURCES = {
    "walk": [GEN / f"asta_walk_f{i}_skin.png" for i in range(4)],
    "turn": [
        GEN / "asta_turn_f0_skin.png",
        GEN / "asta_turn_f1_skin.png",
        GEN / "asta_turn_f2_outfit3.png",
        GEN / "asta_turn_f3_outfit.png",
    ],
    "sit": [GEN / f"asta_sit_f{i}_outfit.png" for i in range(4)],
}


def chroma_key(im: Image.Image) -> Image.Image:
    arr = np.asarray(im.convert("RGB"), dtype=np.float32)
    r, g, b = arr[..., 0], arr[..., 1], arr[..., 2]
    magenta = (r > 140) & (b > 140) & (g < 0.72 * ((r + b) / 2)) & (((r + b) / 2) - g > 35)
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


def head_anchor(cell: Image.Image) -> tuple[int, int]:
    a = np.asarray(cell.convert("RGBA"))[..., 3] > 8
    ys, xs = np.where(a)
    top = int(ys.min())
    band = a[top : top + max(24, CELL_H // 6)]
    cols = np.where(band.any(axis=0))[0]
    return int((int(cols[0]) + int(cols[-1])) / 2), top


def place_head_locked(src: Image.Image) -> Image.Image:
    a = np.asarray(src.convert("RGBA"))[..., 3] > 8
    ys, xs = np.where(a)
    if ys.size == 0:
        return Image.new("RGBA", (CELL_W, CELL_H), (0, 0, 0, 0))
    x0, y0, x1, y1 = int(xs.min()), int(ys.min()), int(xs.max()), int(ys.max())
    fig = src.crop((x0, y0, x1 + 1, y1 + 1))
    hx, hy = head_anchor(src)
    # Fit height ~92% if oversized
    th = fig.height
    tw = fig.width
    if th > int(CELL_H * 0.94) or tw > CELL_W - 8:
        scale = min(int(CELL_H * 0.94) / th, (CELL_W - 8) / tw)
        tw = max(1, int(round(tw * scale)))
        th = max(1, int(round(th * scale)))
        fig = fig.resize((tw, th), Image.LANCZOS)
        hx = int(round((hx - x0) * scale)) + 0
        hy = int(round((hy - y0) * scale))
        local_hx, local_hy = hx, hy
    else:
        local_hx, local_hy = hx - x0, hy - y0
    cell = Image.new("RGBA", (CELL_W, CELL_H), (0, 0, 0, 0))
    cell.paste(fig, (LOCK_HEAD_X - local_hx, LOCK_HEAD_Y - local_hy), fig)
    return cell


def main() -> None:
    REVIEW.mkdir(parents=True, exist_ok=True)
    for group, paths in SOURCES.items():
        frames = []
        for i, path in enumerate(paths):
            assert path.exists(), path
            keyed = chroma_key(Image.open(path))
            cell = place_head_locked(keyed)
            cell.save(REVIEW / f"customer3_{group}_f{i}.png")
            hx, hy = head_anchor(cell)
            print(f"{group} f{i}: head=({hx},{hy}) from {path.name}")
            frames.append(cell)
        strip = Image.new("RGBA", (CELL_W * 4, CELL_H), (0, 0, 0, 0))
        for i, f in enumerate(frames):
            strip.paste(f, (i * CELL_W, 0), f)
        out = IMAGES / f"customer3_{group}.png"
        strip.save(out)
        print(f"wrote {out}")


if __name__ == "__main__":
    main()
