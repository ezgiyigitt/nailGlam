"""Key Ezgi magenta strips and pack onto Lila's cell sizes.

Walk/turn/sit → 432×433 cells (1728×433).
Emotion → 372×402 cells (1860×402).
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "tool"))
from key_generated_art import _crop_to_content, _key  # noqa: E402

SRC = Path(
    r"C:\Users\Ezgi\.cursor\projects\c-Users-Ezgi-Documents-GitHub-nailGlam\assets"
)
OUT = REPO / "assets" / "images"

CELL_W, CELL_H = 432, 433
EMO_W, EMO_H = 372, 402
PAD = 10


def _split_row(image: Image.Image, columns: int) -> list[Image.Image]:
    keyed = _key(image)
    cell_w = keyed.width // columns
    return [
        _crop_to_content(
            keyed.crop((i * cell_w, 0, (i + 1) * cell_w, keyed.height))
        )
        for i in range(columns)
    ]


def _head_anchor(frame: Image.Image) -> tuple[int, int]:
    alpha = np.asarray(frame.split()[3], dtype=np.int32) > 8
    rows = np.flatnonzero(alpha.any(axis=1))
    top = int(rows[0])
    band = alpha[top : top + max(1, frame.height // 4)]
    cols = np.flatnonzero(band.any(axis=0))
    return int((cols[0] + cols[-1]) // 2), top


def _fit_into_cell(
    frame: Image.Image,
    cell_w: int,
    cell_h: int,
    *,
    head_y_frac: float = 0.12,
) -> Image.Image:
    """Scale so the character fits, lock head near [head_y_frac]."""
    ax, ay = _head_anchor(frame)
    # Leave margin; scale to fit width and remaining depth under head.
    max_w = cell_w - PAD * 2
    max_h = cell_h - PAD * 2
    scale = min(max_w / frame.width, max_h / frame.height)
    scaled = frame.resize(
        (max(1, round(frame.width * scale)), max(1, round(frame.height * scale))),
        Image.LANCZOS,
    )
    sax = round(ax * scale)
    say = round(ay * scale)
    canvas = Image.new("RGBA", (cell_w, cell_h), (0, 0, 0, 0))
    target_head_y = int(cell_h * head_y_frac)
    x = (cell_w // 2) - sax
    y = target_head_y - say
    # Keep feet inside cell if scale left overflow at bottom.
    if y + scaled.height > cell_h - PAD:
        y = cell_h - PAD - scaled.height
    if y < PAD:
        y = PAD
    canvas.paste(scaled, (x, y), scaled)
    return canvas


def pack_strip(
    source: Path,
    columns: int,
    cell_w: int,
    cell_h: int,
    out_name: str,
    *,
    head_y_frac: float = 0.12,
) -> None:
    frames = [
        _fit_into_cell(cell, cell_w, cell_h, head_y_frac=head_y_frac)
        for cell in _split_row(Image.open(source), columns)
    ]
    strip = Image.new("RGBA", (cell_w * columns, cell_h), (0, 0, 0, 0))
    for i, frame in enumerate(frames):
        strip.paste(frame, (i * cell_w, 0), frame)
    OUT.mkdir(parents=True, exist_ok=True)
    dest = OUT / out_name
    strip.save(dest)
    print(f"{out_name}: {strip.size[0]}x{strip.size[1]} ({columns} frames)")


def main() -> None:
    pack_strip(SRC / "ezgi_walk_strip_magenta.png", 4, CELL_W, CELL_H, "customer2_walk.png")
    pack_strip(SRC / "ezgi_turn_strip_magenta.png", 4, CELL_W, CELL_H, "customer2_turn.png")
    pack_strip(SRC / "ezgi_sit_strip_magenta.png", 4, CELL_W, CELL_H, "customer2_sit.png")
    pack_strip(
        SRC / "ezgi_emotion_strip_magenta.png",
        5,
        EMO_W,
        EMO_H,
        "customer2_emotion.png",
        head_y_frac=0.08,
    )


if __name__ == "__main__":
    main()
