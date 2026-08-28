"""Integrate Asta review frames into assets/images with locked head position.

Head lock matches the previous customer3 strips (top ~11, center x ~216)
so GameConfig.customerTopY / seat X stay visually unchanged.
Does not modify any Dart position code.
"""

from __future__ import annotations

from pathlib import Path

import numpy as np
from PIL import Image

REPO = Path(__file__).resolve().parent.parent
REVIEW = REPO / "tool" / "review_asta_new_frames"
IMAGES = REPO / "assets" / "images"
CELL_W, CELL_H = 432, 433

# Match old Asta walk head lock so salon placement stays put.
LOCK_HEAD_X = 216
LOCK_HEAD_Y = 11


def _content_bbox(cell: Image.Image) -> tuple[int, int, int, int] | None:
    alpha = np.asarray(cell.convert("RGBA"))[..., 3] > 8
    ys, xs = np.where(alpha)
    if ys.size == 0:
        return None
    return int(xs.min()), int(ys.min()), int(xs.max()), int(ys.max())


def _head_anchor(cell: Image.Image) -> tuple[int, int]:
    alpha = np.asarray(cell.convert("RGBA"))[..., 3] > 8
    ys, xs = np.where(alpha)
    if ys.size == 0:
        return CELL_W // 2, 0
    top = int(ys.min())
    band_h = max(24, CELL_H // 6)
    band = alpha[top : top + band_h]
    cols = np.where(band.any(axis=0))[0]
    if cols.size == 0:
        return int(xs.mean()), top
    return int((int(cols[0]) + int(cols[-1])) / 2), top


def _place_head_locked(src: Image.Image) -> Image.Image:
    """Paste figure so its head anchor lands on LOCK_HEAD_X/Y; clip overflow."""
    src = src.convert("RGBA")
    bbox = _content_bbox(src)
    if bbox is None:
        return Image.new("RGBA", (CELL_W, CELL_H), (0, 0, 0, 0))
    x0, y0, x1, y1 = bbox
    fig = src.crop((x0, y0, x1 + 1, y1 + 1))
    # Anchor relative to cropped figure
    hx, hy = _head_anchor(src)
    local_hx = hx - x0
    local_hy = hy - y0

    cell = Image.new("RGBA", (CELL_W, CELL_H), (0, 0, 0, 0))
    paste_x = LOCK_HEAD_X - local_hx
    paste_y = LOCK_HEAD_Y - local_hy
    cell.paste(fig, (paste_x, paste_y), fig)
    return cell


def _load_review_cell(group: str, index: int) -> Image.Image:
    path = REVIEW / f"customer3_{group}_f{index}.png"
    return Image.open(path).convert("RGBA")


def _save_strip(frames: list[Image.Image], name: str) -> None:
    strip = Image.new("RGBA", (CELL_W * len(frames), CELL_H), (0, 0, 0, 0))
    for i, frame in enumerate(frames):
        strip.paste(frame, (i * CELL_W, 0), frame)
    out = IMAGES / name
    strip.save(out)
    print(f"wrote {out.relative_to(REPO)} {strip.size}")
    for i, frame in enumerate(frames):
        hx, hy = _head_anchor(frame)
        bbox = _content_bbox(frame)
        print(f"  f{i} head=({hx},{hy}) bbox={bbox}")


def main() -> None:
    for group, out_name in (
        ("walk", "customer3_walk.png"),
        ("turn", "customer3_turn.png"),
        ("sit", "customer3_sit.png"),
    ):
        frames = [_place_head_locked(_load_review_cell(group, i)) for i in range(4)]
        # Assert head lock within a few pixels
        heads = [_head_anchor(f) for f in frames]
        xs = [h[0] for h in heads]
        ys = [h[1] for h in heads]
        assert max(xs) - min(xs) <= 4, f"{group} head x drift {xs}"
        assert max(ys) - min(ys) <= 2, f"{group} head y drift {ys}"
        assert abs(sum(ys) / 4 - LOCK_HEAD_Y) <= 2, f"{group} head y off {ys}"
        _save_strip(frames, out_name)
    print("integrated with locked head; position code untouched")


if __name__ == "__main__":
    main()
