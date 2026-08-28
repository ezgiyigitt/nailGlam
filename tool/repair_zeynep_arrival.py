"""Rebuild Zeynep walk/turn/sit strips from installed cells.

Fixes:
- Walk: arm-only pendulum (chest locked), smaller swing
- Turn: ends standing (not seated)
- Sit: stand → settle → seated → hands on table, head-locked like Lila
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "tool"))
from pack_zeynep_customer import (  # noqa: E402
    CELL_H,
    CELL_W,
    _arm_pendulum,
    _bilinear_rgba,
    _head_anchor,
)

IMAGES = REPO / "assets" / "images"
REVIEW = REPO / "tool" / "review_zeynep_arrival"


def _load_cells(name: str) -> list[Image.Image]:
    strip = Image.open(IMAGES / f"{name}.png").convert("RGBA")
    return [
        strip.crop((i * CELL_W, 0, (i + 1) * CELL_W, CELL_H)) for i in range(4)
    ]


def _crop_content(cell: Image.Image) -> Image.Image:
    alpha = np.asarray(cell.split()[3]) > 8
    rows = np.flatnonzero(alpha.any(axis=1))
    cols = np.flatnonzero(alpha.any(axis=0))
    if rows.size == 0:
        return cell
    return cell.crop(
        (int(cols[0]), int(rows[0]), int(cols[-1]) + 1, int(rows[-1]) + 1)
    )


def _place_on_cell(figure: Image.Image, *, head_x: int, head_y: int) -> Image.Image:
    src_x, src_y = _head_anchor(figure)
    cell = Image.new("RGBA", (CELL_W, CELL_H), (0, 0, 0, 0))
    cell.paste(figure, (head_x - src_x, head_y - src_y), figure)
    return cell


def _scale_to_head(figure: Image.Image, target_head_h: int) -> Image.Image:
    _, top = _head_anchor(figure)
    alpha = np.asarray(figure.split()[3]) > 8
    head_rows = np.flatnonzero(alpha[top : top + figure.height // 3].any(axis=1))
    head_h = max(1, int(head_rows[-1]) + 1 if head_rows.size else figure.height // 4)
    factor = target_head_h / head_h
    size = (
        max(1, round(figure.width * factor)),
        max(1, round(figure.height * factor)),
    )
    return figure.resize(size, Image.LANCZOS)


def _arm_pendulum_fixed(cell: Image.Image, swing: float) -> Image.Image:
    """Only the near arm moves; chest and torso stay locked."""
    if abs(swing) < 0.05:
        return cell.copy()
    src = np.asarray(cell.convert("RGBA"))
    height, width = src.shape[:2]
    yy, xx = np.indices((height, width), dtype=np.float32)
    alpha = src[..., 3] > 8
    mid = alpha[int(height * 0.55)]
    cols = np.flatnonzero(mid)
    center_x = float((int(cols[0]) + int(cols[-1])) / 2) if cols.size else width / 2
    # Lock head, hair, chest, and upper back.
    shoulder = height * 0.54
    falloff = np.clip((yy - shoulder) / max(1.0, height - shoulder), 0.0, 1.0) ** 2.4
    # Narrow band on the front/right arm only.
    side = np.clip((xx - (center_x + 8.0)) / 42.0, 0.0, 1.0)
    map_x = xx - swing * falloff * side
    warped = _bilinear_rgba(src, map_x, yy)
    cut = int(shoulder)
    warped[:cut] = src[:cut]
    return Image.fromarray(warped, "RGBA")


def _save_strip(frames: list[Image.Image], out_name: str) -> None:
    strip = Image.new("RGBA", (CELL_W * len(frames), CELL_H), (0, 0, 0, 0))
    for i, frame in enumerate(frames):
        strip.paste(frame, (i * CELL_W, 0), frame)
    strip.save(IMAGES / out_name)
    print(f"{out_name}: {strip.size[0]}x{strip.size[1]}")


def _head_metrics(cell: Image.Image) -> tuple[int, int, int]:
    head_x, head_y = _head_anchor(cell)
    alpha = np.asarray(cell.split()[3]) > 8
    head_rows = np.flatnonzero(alpha[head_y : head_y + cell.height // 3].any(axis=1))
    head_h = max(1, int(head_rows[-1]) + 1 if head_rows.size else cell.height // 4)
    return head_x, head_y, head_h


def rebuild_walk() -> None:
    cells = _load_cells("customer3_walk")
    master = cells[1]  # neutral swing frame
    swings = (14.0, 0.0, -14.0, 0.0)
    frames = [_arm_pendulum_fixed(master, swing) for swing in swings]
    _save_strip(frames, "customer3_walk.png")

    arr = np.asarray(Image.open(IMAGES / "customer3_walk.png"))
    head = slice(0, int(CELL_H * 0.54))
    cells_arr = [arr[:, i * CELL_W : (i + 1) * CELL_W] for i in range(4)]
    for i, cell in enumerate(cells_arr[1:], start=1):
        diff = np.abs(cell[head].astype(np.int16) - cells_arr[0][head].astype(np.int16))
        assert float(diff.mean()) < 1.2, f"torso popped on walk frame {i}"


def rebuild_turn() -> None:
    cells = _load_cells("customer3_turn")
    # Keep profile → 3/4 → front. Hold standing on the last cell (was seated).
    frames = [cells[0], cells[1], cells[2], cells[2].copy()]
    _save_strip(frames, "customer3_turn.png")


def _bottom_y(cell: Image.Image) -> int:
    alpha = np.asarray(cell.split()[3]) > 8
    rows = np.flatnonzero(alpha.any(axis=1))
    return int(rows[-1]) if rows.size else cell.height - 1


def _trim_for_head_lock(
    figure: Image.Image,
    *,
    head_x: int,
    head_y: int,
    max_bottom: int,
) -> Image.Image:
    """Crop legs/feet so a head-locked paste never drops below [max_bottom]."""
    src_x, src_y = _head_anchor(figure)
    paste_y = head_y - src_y
    alpha = np.asarray(figure.split()[3]) > 8
    rows = np.flatnonzero(alpha.any(axis=1))
    if rows.size == 0:
        return figure
    overflow = paste_y + int(rows[-1]) - max_bottom
    if overflow <= 0:
        return figure
    crop_h = figure.height - overflow
    min_h = src_y + max(12, figure.height // 6)
    if crop_h < min_h:
        crop_h = min_h
    return figure.crop((0, 0, figure.width, crop_h))


def _place_head_locked(
    figure: Image.Image,
    *,
    head_x: int,
    head_y: int,
    max_bottom: int,
) -> Image.Image:
    trimmed = _trim_for_head_lock(
        figure,
        head_x=head_x,
        head_y=head_y,
        max_bottom=max_bottom,
    )
    return _place_on_cell(trimmed, head_x=head_x, head_y=head_y)


def rebuild_sit() -> None:
    turn = _load_cells("customer3_turn")
    sit_cells = _load_cells("customer3_sit")
    standing = turn[3]
    seated = _crop_content(sit_cells[1])
    hands = _crop_content(sit_cells[3])

    head_x, head_y, head_h = _head_metrics(standing)
    target_bottom = _bottom_y(standing)
    seated = _scale_to_head(seated, head_h)
    hands = _scale_to_head(hands, head_h)

    frames = [
        standing,
        _place_head_locked(seated, head_x=head_x, head_y=head_y + 2, max_bottom=target_bottom),
        _place_head_locked(seated, head_x=head_x, head_y=head_y + 4, max_bottom=target_bottom),
        _place_head_locked(hands, head_x=head_x, head_y=head_y + 6, max_bottom=target_bottom),
    ]
    _save_strip(frames, "customer3_sit.png")

    bottoms = [_bottom_y(frame) for frame in frames]
    heads = [_head_metrics(frame)[:2] for frame in frames]
    bottom_spread = max(bottoms) - min(bottoms)
    head_y_spread = max(h[1] for h in heads) - min(h[1] for h in heads)
    assert bottom_spread <= 2, f"sit bottom jumped: {bottoms}"
    assert head_y_spread <= 6, f"sit head jumped: {heads}"


def preview() -> None:
    REVIEW.mkdir(parents=True, exist_ok=True)
    for name in ("customer3_walk", "customer3_turn", "customer3_sit"):
        strip = Image.open(IMAGES / f"{name}.png")
        for i in range(4):
            strip.crop((i * CELL_W, 0, (i + 1) * CELL_W, CELL_H)).save(
                REVIEW / f"{name}_f{i}.png"
            )


def main() -> None:
    rebuild_walk()
    rebuild_turn()
    rebuild_sit()
    preview()
    print("repaired Asta arrival strips")


if __name__ == "__main__":
    main()
