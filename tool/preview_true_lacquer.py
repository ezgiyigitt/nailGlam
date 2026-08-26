"""Preview finished-hand polish with true lacquer colors (not Color-blend)."""

from __future__ import annotations

from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

REPO = Path(__file__).resolve().parent.parent
IMAGES = REPO / "assets" / "images"
OUT = REPO / "tool" / "review_light_nails" / "approval"
STEMS = ("pinky", "ring", "middle", "pointer", "thumb")

# Real inventory colors
COLORS = {
    "pinky": (255, 107, 168),   # blush
    "ring": (208, 18, 58),      # RED — must stay red
    "middle": (208, 18, 58),    # RED
    "pointer": (230, 184, 162), # nude
    "thumb": (212, 160, 23),    # gold
}

# Sprite atlas windows used in-game
CROPS = {
    "light": (0, 0, 833, 1446),
    "dark": (344, 0, 344 + 868, 1018),
}


def _soft_light(base: np.ndarray, blend: np.ndarray) -> np.ndarray:
    b = base.astype(np.float32) / 255.0
    s = blend.astype(np.float32) / 255.0
    out = np.where(
        s <= 0.5,
        b - (1.0 - 2.0 * s) * b * (1.0 - b),
        b + (2.0 * s - 1.0) * (np.sqrt(np.clip(b, 0, 1)) - b),
    )
    return np.clip(out * 255.0, 0, 255).astype(np.uint8)


def _dilate_mask(alpha: np.ndarray, px: int = 3) -> np.ndarray:
    img = Image.fromarray(alpha, "L")
    for _ in range(px):
        img = img.filter(ImageFilter.MaxFilter(3))
    img = img.filter(ImageFilter.GaussianBlur(0.8))
    return np.asarray(img)


def paint_hand(skin: str) -> Image.Image:
    hand = Image.open(IMAGES / f"final_hand_{skin}.png").convert("RGBA")
    x0, y0, x1, y1 = CROPS[skin]
    crop = hand.crop((x0, y0, x1, y1))
    arr = np.asarray(crop).copy()
    rgb = arr[..., :3]
    for stem, color in COLORS.items():
        mask_full = np.asarray(
            Image.open(IMAGES / f"final_hand_{skin}_nail_{stem}.png").convert("RGBA")
        )[..., 3]
        mask = _dilate_mask(mask_full[y0:y1, x0:x1], px=2)
        a = (mask.astype(np.float32) / 255.0) * 0.96
        lacquer = np.zeros_like(rgb, dtype=np.float32)
        lacquer[..., 0] = color[0]
        lacquer[..., 1] = color[1]
        lacquer[..., 2] = color[2]
        # True color body (srcOver). SoftLight of the plate is a light gloss
        # pass only — heavy Color-blend was shifting red → washed pink.
        for c in range(3):
            rgb[..., c] = (
                lacquer[..., c] * a + rgb[..., c].astype(np.float32) * (1.0 - a)
            )
        gloss = _soft_light(rgb, arr[..., :3])
        gloss_w = a * 0.22
        for c in range(3):
            rgb[..., c] = gloss[..., c] * gloss_w + rgb[..., c] * (1.0 - gloss_w)
        # Wet highlight streak (vertical soft white)
        ys_idx, xs_idx = np.where(a > 0.2)
        if ys_idx.size:
            cy = float(ys_idx.mean())
            cx = float(xs_idx.mean())
            h, w = a.shape
            ys = np.arange(h)[:, None]
            xs = np.arange(w)[None, :]
            streak = np.exp(
                -(((xs - cx) / max(w * 0.028, 1.0)) ** 2)
                - (((ys - cy) / max(h * 0.10, 1.0)) ** 2)
            )
            shine = streak * a * 0.18
            for c in range(3):
                rgb[..., c] = np.clip(rgb[..., c] + 255.0 * shine, 0, 255)
    out = np.dstack([rgb.astype(np.uint8), arr[..., 3]])
    bg = Image.new("RGBA", crop.size, (255, 182, 193, 255))
    bg.alpha_composite(Image.fromarray(out, "RGBA"))
    return bg.convert("RGB")


def install_dilated_masks(skin: str) -> None:
    for stem in STEMS:
        path = IMAGES / f"final_hand_{skin}_nail_{stem}.png"
        rgba = np.asarray(Image.open(path).convert("RGBA"))
        alpha = _dilate_mask(rgba[..., 3], px=2)
        out = np.zeros_like(rgba)
        out[..., :3] = 255
        out[..., 3] = alpha
        Image.fromarray(out, "RGBA").save(path)
    # Combined
    combined = None
    for stem in STEMS:
        a = np.asarray(Image.open(IMAGES / f"final_hand_{skin}_nail_{stem}.png"))[..., 3]
        combined = a if combined is None else np.maximum(combined, a)
    out = np.zeros((*combined.shape, 4), dtype=np.uint8)
    out[..., :3] = 255
    out[..., 3] = combined
    Image.fromarray(out, "RGBA").save(IMAGES / f"final_hand_{skin}_nail_mask.png")


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for skin in ("light", "dark"):
        # Do not mutate installed masks here — only dilate in-memory while painting.
        paint_hand(skin).save(OUT / f"preview_{skin}_true_lacquer.jpg", quality=94)
        print("wrote", OUT / f"preview_{skin}_true_lacquer.jpg")
        img = np.asarray(Image.open(OUT / f"preview_{skin}_true_lacquer.jpg"))
        mask = np.asarray(
            Image.open(IMAGES / f"final_hand_{skin}_nail_ring.png").convert("RGBA")
        )[..., 3]
        x0, y0, x1, y1 = CROPS[skin]
        m = mask[y0:y1, x0:x1] > 180
        mean = img[m].mean(axis=0)
        print(f"  {skin} ring mean RGB after red lacquer:", mean.round(1))
        # Guard: inventory red is (208,18,58). Color-blend used to wash this to pink
        # (~230,150,160). True lacquer must stay red-dominant.
        assert mean[0] > 180 and mean[1] < 90 and mean[2] < 120, mean
        assert mean[0] > mean[1] + 80, mean
        print(f"  {skin} red lacquer OK")


if __name__ == "__main__":
    main()
