"""Force-match Asta skin tone across walk/turn/sit cells (position unchanged)."""

from __future__ import annotations

from pathlib import Path

import numpy as np
from PIL import Image

REPO = Path(__file__).resolve().parent.parent
IMAGES = REPO / "assets" / "images"
CELL_W, CELL_H = 432, 433
TARGET = np.array([110.0, 68.0, 48.0], dtype=np.float32)


def _dilate(mask: np.ndarray, iters: int = 2) -> np.ndarray:
    out = mask
    for _ in range(iters):
        padded = np.pad(out, 1, constant_values=False)
        nxt = np.zeros_like(out)
        for dy in (-1, 0, 1):
            for dx in (-1, 0, 1):
                nxt |= padded[
                    1 + dy : out.shape[0] + 1 + dy,
                    1 + dx : out.shape[1] + 1 + dx,
                ]
        out = nxt
    return out


def _skin_mask(arr: np.ndarray) -> np.ndarray:
    a = arr[..., 3] > 160
    r = arr[..., 0].astype(np.float32)
    g = arr[..., 1].astype(np.float32)
    b = arr[..., 2].astype(np.float32)
    lum = 0.2126 * r + 0.7152 * g + 0.0722 * b
    skin = (
        a
        & (lum > 40)
        & (lum < 205)
        & (r + 8 >= g)
        & (r > b)
        & ((r - b) > 10)
        & ((r - g) < 95)
    )
    # Exclude navy blouse (blue-ish mid tones)
    navy = a & (b + 8 > r) & (b > g) & (lum < 90)
    skin &= ~navy
    yy = np.arange(arr.shape[0])[:, None]
    skin &= yy < int(CELL_H * 0.70)
    return _dilate(skin, 2) & a


def _blur(weight: np.ndarray, passes: int = 3) -> np.ndarray:
    k = np.array([1, 2, 3, 2, 1], dtype=np.float32)
    k /= k.sum()
    w = weight.astype(np.float32)
    for _ in range(passes):
        pad = np.pad(w, ((0, 0), (2, 2)), mode="edge")
        w = (
            pad[:, 0:-4] * k[0]
            + pad[:, 1:-3] * k[1]
            + pad[:, 2:-2] * k[2]
            + pad[:, 3:-1] * k[3]
            + pad[:, 4:] * k[4]
        )
        pad = np.pad(w, ((2, 2), (0, 0)), mode="edge")
        w = (
            pad[0:-4] * k[0]
            + pad[1:-3] * k[1]
            + pad[2:-2] * k[2]
            + pad[3:-1] * k[3]
            + pad[4:] * k[4]
        )
    return np.clip(w, 0, 1)


def _match(cell: Image.Image) -> Image.Image:
    arr = np.asarray(cell.convert("RGBA")).copy()
    skin = _skin_mask(arr)
    if int(skin.sum()) < 60:
        return cell
    rgb = arr[..., :3].astype(np.float32)
    mean = rgb[skin].mean(axis=0)
    delta = TARGET - mean
    # Soft edge so hairline doesn't hard-cut
    w = _blur(skin.astype(np.float32), passes=4)[..., None]
    # Strong correction on skin; leave hair/clothes alone
    rgb = np.clip(rgb + delta * w, 0, 255)
    arr[..., :3] = rgb.astype(np.uint8)

    # Second pass: exact mean lock on core skin
    skin2 = _skin_mask(arr)
    if skin2.sum() >= 60:
        mean2 = arr[skin2, :3].astype(np.float32).mean(axis=0)
        delta2 = TARGET - mean2
        w2 = _blur(skin2.astype(np.float32), passes=2)[..., None]
        rgb = arr[..., :3].astype(np.float32)
        arr[..., :3] = np.clip(rgb + delta2 * w2, 0, 255).astype(np.uint8)
    return Image.fromarray(arr, "RGBA")


def _scrub_magenta(cell: Image.Image) -> Image.Image:
    arr = np.asarray(cell.convert("RGBA")).copy()
    r, g, b, a = arr[..., 0], arr[..., 1], arr[..., 2], arr[..., 3]
    fringe = (a > 8) & (a < 245) & (r > 145) & (b > 145) & (g < 115)
    if fringe.any():
        arr[fringe, 3] = 0
        arr[fringe, :3] = 0
    return Image.fromarray(arr, "RGBA")


def process(name: str) -> None:
    path = IMAGES / name
    strip = Image.open(path).convert("RGBA")
    frames = []
    print(f"=== {name} ===")
    for i in range(4):
        cell = strip.crop((i * CELL_W, 0, (i + 1) * CELL_W, CELL_H))
        cell = _scrub_magenta(cell)
        before = np.asarray(cell)
        m0 = _skin_mask(before)
        mean0 = before[m0, :3].mean(0) if m0.any() else None
        cell = _match(cell)
        after = np.asarray(cell)
        m1 = _skin_mask(after)
        mean1 = after[m1, :3].mean(0) if m1.any() else None
        print(f"  f{i} {mean0} -> {mean1}")
        frames.append(cell)
    out = Image.new("RGBA", (CELL_W * 4, CELL_H), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        out.paste(f, (i * CELL_W, 0), f)
    out.save(path)


def main() -> None:
    # Re-load from review pack first so we don't stack corrections on prior pass.
    review = REPO / "tool" / "review_asta_new_frames"
    lock_script = REPO / "tool" / "integrate_asta_frames.py"
    # Re-integrate clean, then normalize once.
    import runpy

    runpy.run_path(str(lock_script), run_name="__main__")
    for name in ("customer3_walk.png", "customer3_turn.png", "customer3_sit.png"):
        process(name)


if __name__ == "__main__":
    main()
