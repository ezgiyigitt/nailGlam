"""Rebuild Asta turn/sit strips so she eases into the chair instead of snapping.

Sit frames:
  0 standing (turn end)
  1 early settle  (~33% toward seated)
  2 deep settle   (~72% toward seated)
  3 hands on table

Turn frames stay profile → 3/4 → front, with the last cell a soft hold of front
(not a duplicate of a seated pose).
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "tool"))
from pack_zeynep_customer import CELL_H, CELL_W, _head_anchor  # noqa: E402
from repair_zeynep_arrival import (  # noqa: E402
    IMAGES,
    REVIEW,
    _arm_pendulum_fixed,
    _bottom_y,
    _crop_content,
    _head_metrics,
    _load_cells,
    _place_on_cell,
    _save_strip,
    _scale_to_head,
    _trim_for_head_lock,
)

OUT_REVIEW = REPO / "tool" / "review_asta_smooth_sit"
POSE_CACHE = REPO / "tool" / "asta_pose_cache"


def _ease_in_out(t: float) -> float:
    t = max(0.0, min(1.0, t))
    return t * t * (3.0 - 2.0 * t)


def _warp_lower_body(cell: Image.Image, sit_amount: float) -> Image.Image:
    """Compress the lower torso downward a little as she settles."""
    if sit_amount <= 0.01:
        return cell.copy()
    src = np.asarray(cell.convert("RGBA"))
    height, width = src.shape[:2]
    yy, xx = np.indices((height, width), dtype=np.float32)
    hinge = height * 0.42
    below = np.clip((yy - hinge) / max(1.0, height - hinge), 0.0, 1.0)
    # Pull lower pixels up (shorten torso under the table line).
    pull = sit_amount * 28.0 * (below**1.35)
    map_y = yy + pull
    # Keep head/shoulders locked.
    map_y = np.where(yy < hinge, yy, map_y)
    map_y = np.clip(map_y, 0, height - 1)
    y0 = np.floor(map_y).astype(np.int32)
    y1 = np.clip(y0 + 1, 0, height - 1)
    fy = map_y - y0
    x = np.clip(xx.astype(np.int32), 0, width - 1)
    top = src[y0, x].astype(np.float32)
    bot = src[y1, x].astype(np.float32)
    fy = fy[..., None]
    out = top * (1.0 - fy) + bot * fy
    # Soften alpha on the compressed band so the blend reads cleaner.
    alpha = out[..., 3:4]
    fade = 1.0 - (sit_amount * 0.08 * below[..., None])
    out[..., 3:4] = alpha * fade
    return Image.fromarray(np.clip(out, 0, 255).astype(np.uint8), "RGBA")


def _crossfade(a: Image.Image, b: Image.Image, t: float) -> Image.Image:
    """Head-aligned alpha crossfade from a → b."""
    t = _ease_in_out(t)
    aa = np.asarray(a.convert("RGBA"), dtype=np.float32)
    bb = np.asarray(b.convert("RGBA"), dtype=np.float32)
    a_rgb, a_a = aa[..., :3], aa[..., 3:4] / 255.0
    b_rgb, b_a = bb[..., :3], bb[..., 3:4] / 255.0
    out_a = a_a * (1.0 - t) + b_a * t
    out_rgb = a_rgb * (a_a * (1.0 - t)) + b_rgb * (b_a * t)
    out_rgb = np.where(out_a > 1e-5, out_rgb / np.maximum(out_a, 1e-5), 0.0)
    out = np.concatenate([out_rgb, out_a * 255.0], axis=-1)
    return Image.fromarray(np.clip(out, 0, 255).astype(np.uint8), "RGBA")


def _pose_on_cell(
    figure: Image.Image,
    *,
    head_x: int,
    head_y: int,
    max_bottom: int,
) -> Image.Image:
    trimmed = _trim_for_head_lock(
        figure, head_x=head_x, head_y=head_y, max_bottom=max_bottom
    )
    return _place_on_cell(trimmed, head_x=head_x, head_y=head_y)


def rebuild_walk() -> None:
    cells = _load_cells("customer3_walk")
    master = cells[1]
    swings = (12.0, 0.0, -12.0, 0.0)
    frames = [_arm_pendulum_fixed(master, swing) for swing in swings]
    _save_strip(frames, "customer3_walk.png")


def rebuild_turn() -> None:
    cells = _load_cells("customer3_turn")
    # Distinct turn beats; soft hold on the front pose (no sit yet).
    front = cells[2]
    frames = [cells[0], cells[1], front, front.copy()]
    _save_strip(frames, "customer3_turn.png")


def rebuild_sit() -> None:
    turn = _load_cells("customer3_turn")
    standing = turn[3]

    seated_path = POSE_CACHE / "seated.png"
    hands_path = POSE_CACHE / "hands.png"
    if seated_path.exists() and hands_path.exists():
        seated_src = _crop_content(Image.open(seated_path).convert("RGBA"))
        hands_src = _crop_content(Image.open(hands_path).convert("RGBA"))
    else:
        sit_cells = _load_cells("customer3_sit")
        seated_src = _crop_content(sit_cells[1])
        hands_src = _crop_content(sit_cells[3])

    head_x, head_y, head_h = _head_metrics(standing)
    target_bottom = _bottom_y(standing)
    seated = _scale_to_head(seated_src, head_h)
    hands = _scale_to_head(hands_src, head_h)

    seated_cell = _pose_on_cell(
        seated, head_x=head_x, head_y=head_y + 5, max_bottom=target_bottom
    )
    hands_cell = _pose_on_cell(
        hands, head_x=head_x, head_y=head_y + 7, max_bottom=target_bottom
    )

    early = _crossfade(standing, seated_cell, 0.34)
    early = _pose_on_cell(
        _crop_content(early),
        head_x=head_x,
        head_y=head_y + 2,
        max_bottom=target_bottom,
    )

    mid = _crossfade(standing, seated_cell, 0.72)
    mid = _pose_on_cell(
        _crop_content(mid),
        head_x=head_x,
        head_y=head_y + 4,
        max_bottom=target_bottom,
    )

    frames = [standing, early, mid, hands_cell]
    _save_strip(frames, "customer3_sit.png")

    bottoms = [_bottom_y(frame) for frame in frames]
    heads = [_head_metrics(frame)[:2] for frame in frames]
    bottom_spread = max(bottoms) - min(bottoms)
    head_y_spread = max(h[1] for h in heads) - min(h[1] for h in heads)
    assert bottom_spread <= 6, f"sit bottom jumped: {bottoms}"
    assert head_y_spread <= 8, f"sit head jumped: {heads}"

    arrs = [np.asarray(frame) for frame in frames]
    for i in range(3):
        diff = np.abs(arrs[i].astype(np.int16) - arrs[i + 1].astype(np.int16)).mean()
        assert diff > 3.0, f"sit frames {i}->{i + 1} too similar ({diff:.2f})"
        print(f"sit diff f{i}->f{i+1}: {diff:.2f}")


def preview() -> None:
    OUT_REVIEW.mkdir(parents=True, exist_ok=True)
    REVIEW.mkdir(parents=True, exist_ok=True)
    for name in ("customer3_walk", "customer3_turn", "customer3_sit"):
        strip = Image.open(IMAGES / f"{name}.png")
        for i in range(4):
            cell = strip.crop((i * CELL_W, 0, (i + 1) * CELL_W, CELL_H))
            cell.save(OUT_REVIEW / f"{name}_f{i}.png")
            cell.save(REVIEW / f"{name}_f{i}.png")


def main() -> None:
    rebuild_walk()
    rebuild_turn()
    rebuild_sit()
    preview()
    print("smoothed Asta turn/sit strips")


if __name__ == "__main__":
    main()
