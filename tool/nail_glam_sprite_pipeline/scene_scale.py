"""Automatic scene scale solver from character height = 1.0 world unit."""

from __future__ import annotations

from dataclasses import asdict, dataclass
from pathlib import Path

from PIL import Image
import numpy as np

from .config import ScaleHints


@dataclass
class SceneScale:
    character_height: float
    door_height: float
    door_opening_width: float
    chair_seat_height: float
    chair_width: float
    door_to_chair_distance: float
    walk_distance: float
    stop_x: float
    sit_x: float
    ground_y: float
    # Pixel helpers for packing prompts
    character_pixel_height: int
    notes: list[str]

    def to_dict(self) -> dict:
        return asdict(self)


def _opaque_height(path: Path | None) -> int | None:
    if path is None or not path.exists():
        return None
    im = Image.open(path).convert("RGBA")
    a = np.asarray(im)
    vis = a[:, :, 3] > 16
    rgb = a[:, :, :3].astype(np.int16)
    dark = rgb.sum(axis=2) < 36
    vis = vis & ~dark
    if not vis.any():
        return None
    ys, _ = np.where(vis)
    return int(ys.max() - ys.min() + 1)


def solve_scale(
    hints: ScaleHints,
    *,
    identity_path: Path,
    door_path: Path | None,
    chair_path: Path | None,
) -> SceneScale:
    notes: list[str] = []
    ch = hints.character_height
    door_h = (hints.door_height_min + hints.door_height_max) / 2.0
    seat_h = hints.chair_seat_height_ratio * ch
    chair_w = hints.chair_width_ratio * ch
    opening_w = hints.door_opening_width_ratio * ch

    id_px = _opaque_height(identity_path) or 1400
    door_px = _opaque_height(door_path)
    chair_px = _opaque_height(chair_path)

    if door_px:
        # Door leaf art is ~character*2.1–2.3 tall in world; sanity check ratio.
        ratio = door_px / max(id_px, 1)
        if ratio < 0.9:
            notes.append(f"door art short vs identity ({ratio:.2f}); keep door_h={door_h}")
        elif ratio > 3.5:
            notes.append(f"door art tall vs identity ({ratio:.2f}); clamp door opening cues")
        else:
            notes.append(f"door/identity pixel ratio {ratio:.2f} within band")

    if chair_px:
        ratio = chair_px / max(id_px, 1)
        notes.append(f"chair/identity pixel ratio {ratio:.2f}")
        # Seat roughly mid-lower third of chair art.
        seat_h = max(0.38 * ch, min(0.48 * ch, seat_h))

    # Path length in world units — enough for several gait cycles.
    door_to_chair = 4.2 * ch
    walk_distance = 5.6 * ch
    stop_x = 0.88 * door_to_chair
    sit_x = door_to_chair
    ground_y = 0.0

    # Character must clear door (~80% of opening height).
    if ch > door_h * 0.92:
        notes.append("character too tall for door — reduce far scale in game")
    else:
        notes.append("character clears doorway with headroom")

    return SceneScale(
        character_height=ch,
        door_height=door_h,
        door_opening_width=opening_w,
        chair_seat_height=seat_h,
        chair_width=chair_w,
        door_to_chair_distance=door_to_chair,
        walk_distance=walk_distance,
        stop_x=stop_x,
        sit_x=sit_x,
        ground_y=ground_y,
        character_pixel_height=id_px,
        notes=notes,
    )
