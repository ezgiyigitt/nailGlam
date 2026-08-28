"""Rebuild Asta arrival strips so walk/turn/sit stay one consistent character.

Rules:
- One locked master silhouette for walk (head/chest frozen)
- Only arms swing, in sync (near arm ↔ far arm opposite)
- Turn starts from that same master, then head-locks into front
- Sit uses clean seated/hands poses (no ghosty crossfade)
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "tool"))
from pack_zeynep_customer import CELL_H, CELL_W, _bilinear_rgba, _head_anchor  # noqa: E402
from repair_zeynep_arrival import (  # noqa: E402
    IMAGES,
    _bottom_y,
    _crop_content,
    _head_metrics,
    _load_cells,
    _place_on_cell,
    _save_strip,
    _scale_to_head,
    _trim_for_head_lock,
)

REVIEW = REPO / "tool" / "review_asta_arrival_v2"
POSE_CACHE = REPO / "tool" / "asta_pose_cache"


def _arm_pendulum_synced(cell: Image.Image, swing: float) -> Image.Image:
    """Near arm and far arm swing opposite; head + chest stay pixel-locked."""
    if abs(swing) < 0.05:
        return cell.copy()
    src = np.asarray(cell.convert("RGBA"))
    height, width = src.shape[:2]
    yy, xx = np.indices((height, width), dtype=np.float32)
    alpha = src[..., 3] > 8
    mid = alpha[int(height * 0.55)]
    cols = np.flatnonzero(mid)
    center_x = float((int(cols[0]) + int(cols[-1])) / 2) if cols.size else width / 2.0

    # Everything above mid-chest is frozen.
    shoulder = height * 0.50
    falloff = np.clip((yy - shoulder) / max(1.0, height - shoulder), 0.0, 1.0) ** 1.85

    # Right-facing profile: near (visible) arm is on the right of the torso.
    near = np.clip((xx - (center_x + 4.0)) / 36.0, 0.0, 1.0) ** 1.15
    # Far arm peeks on the left / trailing side.
    far = np.clip(((center_x - 6.0) - xx) / 34.0, 0.0, 1.0) ** 1.15

    # Positive swing = near arm forward (toward facing direction / +x).
    map_x = xx - swing * falloff * near + (swing * 0.62) * falloff * far
    map_y = yy + (swing * 0.08) * falloff * (near - far)

    warped = _bilinear_rgba(src, map_x, map_y)
    cut = int(shoulder)
    warped[:cut] = src[:cut]
    # Soft lock a center torso column so the blouse knot never drifts.
    torso = (xx >= center_x - 18) & (xx <= center_x + 10) & (yy < height * 0.78)
    warped[torso] = src[torso]
    return Image.fromarray(warped, "RGBA")


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


def _yaw_hint(cell: Image.Image, amount: float) -> Image.Image:
    """Subtle profile→camera yaw without ghosting (width stretch around spine)."""
    amount = float(np.clip(amount, 0.0, 1.0))
    if amount < 0.02:
        return cell.copy()
    src = np.asarray(cell.convert("RGBA"))
    height, width = src.shape[:2]
    yy, xx = np.indices((height, width), dtype=np.float32)
    alpha = src[..., 3] > 8
    mid = alpha[int(height * 0.55)]
    cols = np.flatnonzero(mid)
    center_x = float((int(cols[0]) + int(cols[-1])) / 2) if cols.size else width / 2.0

    # Pull the leading (right) edge inward and push the trailing edge out a bit.
    # Looks like a shallow turn toward the camera.
    dx = (xx - center_x) / max(1.0, width * 0.28)
    widen = 1.0 + amount * 0.16
    # Face-side (positive x for right-facing) compresses slightly; back expands.
    face = np.clip(dx, 0.0, 1.0)
    back = np.clip(-dx, 0.0, 1.0)
    map_x = center_x + (xx - center_x) * (1.0 + amount * 0.10 * back - amount * 0.12 * face)
    # Tiny forward lean of shoulders.
    shoulder = height * 0.42
    lean = amount * 6.0 * np.clip((shoulder - yy) / max(1.0, shoulder), 0.0, 1.0)
    map_x = map_x + lean

    warped = _bilinear_rgba(src, map_x, yy)
    # Keep head pixels locked.
    head_cut = int(height * 0.36)
    warped[:head_cut] = src[:head_cut]
    return Image.fromarray(warped, "RGBA")


def _cache_masters() -> tuple[Image.Image, Image.Image, Image.Image, Image.Image]:
    walk = _load_cells("customer3_walk")
    turn = _load_cells("customer3_turn")
    # Neutral walk cell is the shared body.
    profile = walk[1].copy()
    # Prefer clean front from turn strip (last standing front).
    front = turn[2].copy()
    seated_path = POSE_CACHE / "seated.png"
    hands_path = POSE_CACHE / "hands.png"
    if seated_path.exists() and hands_path.exists():
        seated = Image.open(seated_path).convert("RGBA")
        hands = Image.open(hands_path).convert("RGBA")
    else:
        sit = _load_cells("customer3_sit")
        seated = sit[1]
        hands = sit[3]
    POSE_CACHE.mkdir(parents=True, exist_ok=True)
    profile.save(POSE_CACHE / "profile.png")
    front.save(POSE_CACHE / "front.png")
    return profile, front, seated, hands


def rebuild_walk(profile: Image.Image) -> list[Image.Image]:
    swings = (26.0, 0.0, -26.0, 0.0)
    frames = [_arm_pendulum_synced(profile, swing) for swing in swings]
    _save_strip(frames, "customer3_walk.png")

    arr = np.asarray(Image.open(IMAGES / "customer3_walk.png"))
    head = slice(0, int(CELL_H * 0.48))
    cells = [arr[:, i * CELL_W : (i + 1) * CELL_W] for i in range(4)]
    for i, cell in enumerate(cells[1:], start=1):
        diff = float(np.abs(cell[head].astype(np.int16) - cells[0][head].astype(np.int16)).mean())
        assert diff < 0.8, f"walk head/chest popped on frame {i}: {diff:.3f}"
    # Arm motion must be visible in the lower half.
    lower = slice(int(CELL_H * 0.55), CELL_H)
    arm_diff = float(
        np.abs(cells[0][lower].astype(np.int16) - cells[2][lower].astype(np.int16)).mean()
    )
    assert arm_diff > 1.5, f"walk arms barely moved: {arm_diff:.3f}"
    print(f"walk arm swing diff f0<->f2: {arm_diff:.2f}")
    return frames


def rebuild_turn(profile: Image.Image, front: Image.Image) -> list[Image.Image]:
    head_x, head_y, head_h = _head_metrics(profile)
    target_bottom = _bottom_y(profile)

    # Scale front to the same head size, then lock to profile head anchor.
    front_fig = _scale_to_head(_crop_content(front), head_h)
    front_locked = _pose_on_cell(
        front_fig, head_x=head_x, head_y=head_y, max_bottom=target_bottom
    )

    # Progressive yaw from the SAME profile body, then land on front.
    # Keeps silhouette related across the turn instead of unrelated stills.
    frames = [
        profile.copy(),
        _yaw_hint(profile, 0.38),
        _yaw_hint(profile, 0.72),
        front_locked,
    ]
    _save_strip(frames, "customer3_turn.png")

    heads = [_head_metrics(frame)[:2] for frame in frames]
    head_x_spread = max(h[0] for h in heads) - min(h[0] for h in heads)
    head_y_spread = max(h[1] for h in heads) - min(h[1] for h in heads)
    assert head_x_spread <= 6, f"turn head x jumped: {heads}"
    assert head_y_spread <= 4, f"turn head y jumped: {heads}"
    # Consecutive relatedness: early steps must stay on the profile body.
    a0 = np.asarray(frames[0])
    a1 = np.asarray(frames[1])
    early = float(np.abs(a0.astype(np.int16) - a1.astype(np.int16)).mean())
    assert early < 4.0, f"turn early step unrelated: {early:.2f}"
    print(f"turn head anchors: {heads} early_diff={early:.2f}")
    return frames


def rebuild_sit(
    front: Image.Image,
    seated_src: Image.Image,
    hands_src: Image.Image,
) -> list[Image.Image]:
    head_x, head_y, head_h = _head_metrics(front)
    target_bottom = _bottom_y(front)

    seated = _scale_to_head(_crop_content(seated_src), head_h)
    hands = _scale_to_head(_crop_content(hands_src), head_h)

    settle = _pose_on_cell(
        seated, head_x=head_x, head_y=head_y + 3, max_bottom=target_bottom
    )
    seated_cell = _pose_on_cell(
        seated, head_x=head_x, head_y=head_y + 6, max_bottom=target_bottom
    )
    hands_cell = _pose_on_cell(
        hands, head_x=head_x, head_y=head_y + 8, max_bottom=target_bottom
    )

    frames = [front.copy(), settle, seated_cell, hands_cell]
    _save_strip(frames, "customer3_sit.png")

    bottoms = [_bottom_y(frame) for frame in frames]
    heads = [_head_metrics(frame)[:2] for frame in frames]
    assert max(bottoms) - min(bottoms) <= 4, f"sit bottom jumped: {bottoms}"
    assert max(h[1] for h in heads) - min(h[1] for h in heads) <= 10, f"sit head jumped: {heads}"

    # No ghosted double-exposure: consecutive frames must not be near-identical
    # mush, and seated must differ from standing.
    arrs = [np.asarray(f) for f in frames]
    d02 = float(np.abs(arrs[0].astype(np.int16) - arrs[2].astype(np.int16)).mean())
    assert d02 > 4.0, f"sit never settled: {d02:.2f}"
    print(f"sit stand-to-seated diff: {d02:.2f} heads={heads}")
    return frames


def preview() -> None:
    REVIEW.mkdir(parents=True, exist_ok=True)
    for name in ("customer3_walk", "customer3_turn", "customer3_sit"):
        strip = Image.open(IMAGES / f"{name}.png")
        for i in range(4):
            strip.crop((i * CELL_W, 0, (i + 1) * CELL_W, CELL_H)).save(
                REVIEW / f"{name}_f{i}.png"
            )


def main() -> None:
    profile, front, seated, hands = _cache_masters()
    rebuild_walk(profile)
    # Re-read profile after walk write (identical content) for turn continuity.
    profile = _load_cells("customer3_walk")[1]
    rebuild_turn(profile, front)
    front = _load_cells("customer3_turn")[3]
    rebuild_sit(front, seated, hands)
    preview()
    print("rebuilt Asta arrival: locked walk arms + continuous turn/sit")


if __name__ == "__main__":
    main()
