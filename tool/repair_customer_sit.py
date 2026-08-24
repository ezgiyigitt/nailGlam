"""Build a one-shot sit strip from the last turn pose plus keyed sit frames.

The original seated PNG was pocket-filled, which ate the hands. New sit
renders are cut with a border flood-fill only, then packed onto the same
432x433 cell as walk/turn so the head does not jump.
"""

from __future__ import annotations

from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
IMAGES = ROOT / "assets" / "images"


def _generated(name: str) -> Path:
    for folder in (
        ROOT / "tool" / "sit_gen",
        Path(
            r"C:\Users\Ezgi\.cursor\projects\c-Users-Ezgi-Documents-GitHub-nailGlam\assets"
        ),
    ):
        path = folder / name
        if path.exists():
            return path
    raise FileNotFoundError(name)
CELL_W = 432
CELL_H = 433
SENTINEL = (1, 254, 2)
FILL_TOLERANCE = 55


def key_magenta(image: Image.Image) -> Image.Image:
    canvas = image.convert("RGB")
    width, height = canvas.size
    for seed in (
        (0, 0),
        (width - 1, 0),
        (0, height - 1),
        (width - 1, height - 1),
        (width // 2, 0),
        (width // 2, height - 1),
    ):
        ImageDraw.floodfill(canvas, seed, SENTINEL, thresh=FILL_TOLERANCE)

    filled = np.all(
        np.asarray(canvas, dtype=np.int32) == np.array(SENTINEL, dtype=np.int32),
        axis=-1,
    )
    rgba = np.asarray(image.convert("RGBA"), dtype=np.int32).copy()
    rgb = rgba[..., :3]
    chroma = (rgb[..., 0] > 190) & (rgb[..., 2] > 190) & (rgb[..., 1] < 90)
    chroma = (
        np.asarray(
            Image.fromarray((chroma.astype(np.uint8) * 255), "L").filter(
                ImageFilter.MaxFilter(3)
            )
        )
        > 0
    )
    rgba[..., 3] = np.where(filled | chroma, 0, 255)

    alpha = Image.fromarray(rgba[..., 3].astype(np.uint8), "L")
    rgba[..., 3] = np.asarray(alpha.filter(ImageFilter.GaussianBlur(0.4)), dtype=np.int32)

    edge = rgba[..., 3] < 255
    cap = rgba[..., 1] + 40
    rgba[..., 0] = np.where(edge, np.minimum(rgba[..., 0], cap), rgba[..., 0])
    rgba[..., 2] = np.where(edge, np.minimum(rgba[..., 2], cap), rgba[..., 2])
    return Image.fromarray(rgba.astype(np.uint8), "RGBA")


def crop_content(image: Image.Image) -> Image.Image:
    alpha = np.asarray(image.split()[3]) > 8
    rows = np.flatnonzero(alpha.any(axis=1))
    cols = np.flatnonzero(alpha.any(axis=0))
    return image.crop(
        (int(cols[0]), int(rows[0]), int(cols[-1]) + 1, int(rows[-1]) + 1)
    )


def head_anchor(image: Image.Image) -> tuple[int, int]:
    alpha = np.asarray(image.split()[3]) > 8
    rows = np.flatnonzero(alpha.any(axis=1))
    top = int(rows[0])
    band = alpha[top : top + max(1, image.height // 4)]
    cols = np.flatnonzero(band.any(axis=0))
    return int((cols[0] + cols[-1]) // 2), top


def place_on_cell(figure: Image.Image, *, head_x: int, head_y: int) -> Image.Image:
    src_x, src_y = head_anchor(figure)
    cell = Image.new("RGBA", (CELL_W, CELL_H), (0, 0, 0, 0))
    cell.paste(figure, (head_x - src_x, head_y - src_y), figure)
    return cell


def scale_to_head(figure: Image.Image, target_head_height: int) -> Image.Image:
    _, top = head_anchor(figure)
    alpha = np.asarray(figure.split()[3]) > 8
    head_rows = np.flatnonzero(alpha[top : top + figure.height // 3].any(axis=1))
    head_h = max(1, int(head_rows[-1]) + 1)
    factor = target_head_height / head_h
    size = (
        max(1, round(figure.width * factor)),
        max(1, round(figure.height * factor)),
    )
    return figure.resize(size, Image.Resampling.LANCZOS)


def turn_last() -> Image.Image:
    strip = Image.open(IMAGES / "customer_turn.png").convert("RGBA")
    width = strip.width // 4
    return strip.crop((3 * width, 0, 4 * width, strip.height))


def main() -> None:
    standing = turn_last()
    stand_head_x, stand_head_y = head_anchor(standing)
    stand_alpha = np.asarray(standing.split()[3]) > 8
    stand_head_band = stand_alpha[
        stand_head_y : stand_head_y + standing.height // 3
    ]
    stand_head_h = int(np.flatnonzero(stand_head_band.any(axis=1))[-1]) + 1

    sit_paths = [_generated(f"sit_down_0{i}.png") for i in (1, 2, 3)]
    sits: list[Image.Image] = []
    for path in sit_paths:
        keyed = crop_content(key_magenta(Image.open(path)))
        sits.append(scale_to_head(keyed, stand_head_h))

    frames = [
        standing,
        place_on_cell(sits[0], head_x=stand_head_x, head_y=stand_head_y + 2),
        place_on_cell(sits[1], head_x=stand_head_x, head_y=stand_head_y + 4),
        place_on_cell(sits[2], head_x=stand_head_x, head_y=stand_head_y + 6),
    ]
    strip = Image.new("RGBA", (CELL_W * 4, CELL_H), (0, 0, 0, 0))
    for index, frame in enumerate(frames):
        strip.paste(frame, (index * CELL_W, 0), frame)
    out = IMAGES / "customer_sit.png"
    strip.save(out)
    print(out, strip.size)


if __name__ == "__main__":
    main()
