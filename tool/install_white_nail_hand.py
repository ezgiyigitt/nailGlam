"""Install final light hand from user art with pre-painted white nail plates."""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "tool"))
from make_zeynep_nail_sheets import _feather_nail_alpha, _luma  # noqa: E402
from pack_zeynep_customer import _crop_to_content, _key_black  # noqa: E402

HAND_SRC = Path(
    r"C:\Users\Ezgi\.cursor\projects\c-Users-Ezgi-Documents-GitHub-nailGlam\assets"
    r"\c__Users_Ezgi_AppData_Roaming_Cursor_User_workspaceStorage_9564a3c94e3063fd248743fa88c27cbd_images_572cf599-e078-4597-8b48-aa49035f92d9-30de84d8-d308-49de-a127-8130ae21d2d0.jpg"
)

IMAGES = REPO / "assets" / "images"
REVIEW = REPO / "tool" / "review_light_nails" / "approval"
CANVAS = (833, 1446)
HAND_ORDER = ("pinky", "ring", "middle", "pointer", "thumb")


def _rgba_mask(alpha: np.ndarray) -> Image.Image:
    if alpha.dtype == bool or int(alpha.max()) <= 1:
        base = (alpha.astype(np.float32) * 255).astype(np.uint8)
    else:
        base = alpha.astype(np.uint8)
    feather = Image.fromarray(base, "L").filter(ImageFilter.GaussianBlur(1.2))
    a = np.asarray(feather).astype(np.uint8)
    out = np.zeros((*a.shape, 4), dtype=np.uint8)
    out[..., :3] = 255
    out[..., 3] = np.where(a > 8, a, 0)
    return Image.fromarray(out, "RGBA")


def _fit_canvas(keyed: Image.Image) -> Image.Image:
    cw, ch = CANVAS
    crop = _crop_to_content(keyed)
    scale = min((cw - 24) / crop.width, (ch - 24) / crop.height)
    nw, nh = max(1, round(crop.width * scale)), max(1, round(crop.height * scale))
    scaled = crop.resize((nw, nh), Image.LANCZOS)
    canvas = Image.new("RGBA", CANVAS, (0, 0, 0, 0))
    canvas.alpha_composite(scaled, ((cw - nw) // 2, ch - nh - 12))
    return canvas


def _white_nail_mask(rgb: np.ndarray, alpha: np.ndarray) -> np.ndarray:
    lum = _luma(rgb.astype(np.float32))
    # White nail plates from the user's art pass.
    white = alpha & (lum > 210) & (rgb.min(axis=2) > 185)
    if white.sum() < 400:
        white = alpha & (lum > 200)
    return white


def _split_nail_blobs(white: np.ndarray) -> list[np.ndarray]:
    h, w = white.shape
    seen = np.zeros((h, w), dtype=bool)
    blobs: list[tuple[np.ndarray, float, float]] = []
    for y, x in zip(*np.where(white)):
        if seen[y, x]:
            continue
        stack = [(int(x), int(y))]
        pts: list[tuple[int, int]] = []
        while stack:
            cx, cy = stack.pop()
            if cx < 0 or cy < 0 or cx >= w or cy >= h or seen[cy, cx] or not white[cy, cx]:
                continue
            seen[cy, cx] = True
            pts.append((cx, cy))
            stack.extend(((cx - 1, cy), (cx + 1, cy), (cx, cy - 1), (cx, cy + 1)))
        if len(pts) < 120:
            continue
        blob = np.zeros((h, w), dtype=bool)
        xs = [p[0] for p in pts]
        ys = [p[1] for p in pts]
        for cx, cy in pts:
            blob[cy, cx] = True
        blobs.append((blob, float(np.mean(xs)), float(np.mean(ys))))
    blobs.sort(key=lambda item: item[1])
    if len(blobs) != 5:
        raise RuntimeError(f"expected 5 nail blobs, found {len(blobs)}")
    return [blob for blob, _, _ in blobs]


def _naturalize_nails(hand: Image.Image, white: np.ndarray) -> Image.Image:
    """Swap flat white plates for a soft nude gloss so bare nails look natural."""
    arr = np.asarray(hand).copy()
    rgb = arr[..., :3].astype(np.float32)
    alpha = arr[..., 3] > 20
    skin = rgb[alpha & ~white]
    if skin.size == 0:
        return hand
    base = np.median(skin, axis=0)
    nail_rgb = base * 0.92 + np.array([18.0, 8.0, 10.0])
    nail_rgb = np.clip(nail_rgb, 0, 255)
    for c in range(3):
        rgb[..., c][white] = nail_rgb[c]
    arr[..., :3] = np.clip(rgb, 0, 255).astype(np.uint8)
    return Image.fromarray(arr, "RGBA")


def _preview_multicolor(hand: Image.Image, masks: dict[str, Image.Image]) -> Image.Image:
    preview = hand.copy()
    colors = {
        "pinky": (255, 107, 168),
        "ring": (208, 18, 58),
        "middle": (230, 184, 162),
        "pointer": (155, 90, 182),
        "thumb": (212, 160, 23),
    }
    for stem, rgb in colors.items():
        tint = Image.new("RGBA", hand.size, (*rgb, 0))
        tint.putalpha(masks[stem].split()[-1].point(lambda v: int(v * 0.93)))
        preview = Image.alpha_composite(preview, tint)
    bg = Image.new("RGBA", hand.size, (255, 182, 193, 255))
    bg.alpha_composite(preview)
    return bg.convert("RGB")


def _preview_align(hand: Image.Image, masks: dict[str, Image.Image]) -> Image.Image:
    bg = Image.new("RGBA", hand.size, (255, 182, 193, 255))
    bg.alpha_composite(hand)
    ov = np.zeros((*hand.size[::-1], 4), dtype=np.uint8)
    for i, stem in enumerate(HAND_ORDER):
        m = np.asarray(masks[stem])[..., 3] > 40
        ov[m] = (60, 200 + (i * 11) % 40, 90, 175)
    bg = Image.alpha_composite(bg, Image.fromarray(ov, "RGBA"))
    return bg.convert("RGB")


def main() -> None:
    raw = Image.open(HAND_SRC).convert("RGBA")
    keyed = _key_black(raw, fill_tolerance=22)
    canvas = _fit_canvas(keyed)

    arr = np.asarray(canvas)
    rgb = arr[..., :3]
    alpha = arr[..., 3] > 20
    white = _white_nail_mask(rgb, alpha)
    blobs = _split_nail_blobs(white)

    masks: dict[str, Image.Image] = {}
    combined = np.zeros(canvas.size[::-1], dtype=bool)
    for stem, blob in zip(HAND_ORDER, blobs, strict=True):
        plate = _feather_nail_alpha(blob)
        combined |= blob
        masks[stem] = _rgba_mask(plate)

    hand = _naturalize_nails(canvas, white)
    hand.save(IMAGES / "final_hand_light.png")
    for stem, mask in masks.items():
        mask.save(IMAGES / f"final_hand_light_nail_{stem}.png")
    _rgba_mask(_feather_nail_alpha(combined)).save(IMAGES / "final_hand_light_nail_mask.png")

    REVIEW.mkdir(parents=True, exist_ok=True)
    _preview_multicolor(hand, masks).save(
        REVIEW / "preview_white_nail_hand_multicolor.jpg",
        quality=94,
    )
    _preview_align(hand, masks).save(
        REVIEW / "preview_white_nail_hand_mask_align.jpg",
        quality=94,
    )
    print("installed white-nail hand", IMAGES / "final_hand_light.png")


if __name__ == "__main__":
    main()
