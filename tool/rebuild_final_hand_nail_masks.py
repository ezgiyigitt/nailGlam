"""Rebuild filled per-digit nail masks from installed final hand art."""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "tool"))
from make_zeynep_nail_sheets import _feather_nail_alpha  # noqa: E402
from mask_user_final_hand import (  # noqa: E402
    HAND_ORDER,
    _nail_centers,
    _preview_multicolor,
    _rgba_mask,
)

REVIEW = REPO / "tool" / "review_light_nails" / "approval"
SCALES: dict[str, tuple[float, float]] = {
    "pinky": (0.95, 1.05),
    "ring": (1.0, 1.08),
    "middle": (1.05, 1.12),
    "pointer": (1.0, 1.08),
    "thumb": (1.15, 1.05),
}


def _solid_rgba_mask(alpha: np.ndarray) -> Image.Image:
    if alpha.dtype == bool or int(alpha.max()) <= 1:
        base = (alpha.astype(np.float32) * 255).astype(np.uint8)
    else:
        base = alpha.astype(np.uint8)
    feather = Image.fromarray(base, "L").filter(ImageFilter.GaussianBlur(1.0))
    a = np.asarray(feather).astype(np.uint8)
    out = np.zeros((*a.shape, 4), dtype=np.uint8)
    out[..., :3] = 255
    out[..., 3] = np.where(a > 8, a, 0)
    return Image.fromarray(out, "RGBA")


def build_masks(hand_path: Path, out_prefix: str) -> None:
    hand = Image.open(hand_path).convert("RGBA")
    centers = _nail_centers(hand)
    width, height = hand.size
    finger = np.asarray(hand)[..., 3] > 20
    combined = np.zeros((height, width), dtype=bool)
    masks: dict[str, Image.Image] = {}

    ys = np.arange(height)[:, None]
    xs = np.arange(width)[None, :]

    for stem in HAND_ORDER:
        cx, cy, rad = centers[stem]
        sx, sy = SCALES[stem]
        ellipse = (((xs - cx) / (rad * sx)) ** 2 + ((ys - cy) / (rad * sy)) ** 2) <= 1.0
        plate = ellipse & finger & (ys <= cy + rad * sy * 0.35)
        plate = _feather_nail_alpha(plate) > 127
        combined |= plate
        masks[stem] = _rgba_mask(plate)
        masks[stem].save(REPO / "assets" / "images" / f"{out_prefix}_nail_{stem}.png")
        print(
            out_prefix,
            stem,
            int(plate.sum()),
            f"center=({cx:.0f},{cy:.0f}) r={rad:.0f}",
        )

    _rgba_mask(_feather_nail_alpha(combined)).save(
        REPO / "assets" / "images" / f"{out_prefix}_nail_mask.png",
    )
    REVIEW.mkdir(parents=True, exist_ok=True)
    label = out_prefix.rsplit("_", 1)[-1]
    _preview_multicolor(hand, masks).save(
        REVIEW / f"preview_{label}_oval_multicolor.jpg",
        quality=93,
    )


def main() -> None:
    build_masks(REPO / "assets" / "images" / "final_hand_light.png", "final_hand_light")
    build_masks(REPO / "assets" / "images" / "final_hand_dark.png", "final_hand_dark")


if __name__ == "__main__":
    main()
