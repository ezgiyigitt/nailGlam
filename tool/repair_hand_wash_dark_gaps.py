"""Clean hand_wash_dark: heal finger-gap cuts + remove black edge fringe.

Restores from backup, then:
1) closes thin transparent notches between fingers
2) clears near-black opaque fringe that touches transparent bg
   (leftover black matte — looks like 'kesik' against wood)
Interior dirt smudges stay untouched.
"""

from __future__ import annotations

from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

REPO = Path(__file__).resolve().parent.parent
SRC = REPO / "assets" / "images" / "hand_wash_dark.png"
BACKUP = REPO / "assets" / "images" / "hand_wash_dark_backup.png"
PREVIEW = REPO / "tool" / "review_hand_wash_dark_fix"


def _dilate(mask: np.ndarray, r: int) -> np.ndarray:
    out = mask
    for _ in range(max(0, r)):
        p = np.pad(out, 1, constant_values=False)
        nxt = np.zeros_like(out)
        for dy in (-1, 0, 1):
            for dx in (-1, 0, 1):
                nxt |= p[1 + dy : out.shape[0] + 1 + dy, 1 + dx : out.shape[1] + 1 + dx]
        out = nxt
    return out


def _erode(mask: np.ndarray, r: int) -> np.ndarray:
    out = mask
    for _ in range(max(0, r)):
        p = np.pad(out, 1, constant_values=True)
        nxt = np.ones_like(out, dtype=bool)
        for dy in (-1, 0, 1):
            for dx in (-1, 0, 1):
                nxt &= p[1 + dy : out.shape[0] + 1 + dy, 1 + dx : out.shape[1] + 1 + dx]
        out = nxt
    return out


def _close(mask: np.ndarray, r: int) -> np.ndarray:
    return _erode(_dilate(mask, r), r)


def _fill_narrow_row_gaps(mask: np.ndarray, max_gap: int, y0: int, y1: int) -> np.ndarray:
    out = mask.copy()
    h, w = out.shape
    for y in range(y0, min(y1, h)):
        row = out[y]
        i = 0
        while i < w:
            if row[i]:
                i += 1
                continue
            j = i
            while j < w and not row[j]:
                j += 1
            if i > 0 and j < w and row[i - 1] and row[j] and 1 <= (j - i) <= max_gap:
                # Prefer filling gaps that are deep notches: both sides thick
                left = int(row[max(0, i - 12) : i].sum())
                right = int(row[j : min(w, j + 12)].sum())
                if left >= 4 and right >= 4:
                    row[i:j] = True
            i = j
    return out


def _inpaint_skin(arr: np.ndarray, fill: np.ndarray) -> np.ndarray:
    """Fill with brighter local skin (avoid pure black dirt samples)."""
    out = arr.copy()
    h, w = fill.shape
    yy, xx = np.where(fill)
    rgb = arr[..., :3].astype(np.float32)
    lum = rgb.mean(2)
    good = (arr[..., 3] > 180) & (lum > 55) & ~fill
    fallback = (arr[..., 3] > 180) & ~fill
    for y, x in zip(yy.tolist(), xx.tolist()):
        y0, y1 = max(0, y - 10), min(h, y + 11)
        x0, x1 = max(0, x - 10), min(w, x + 11)
        m = good[y0:y1, x0:x1]
        if m.sum() < 8:
            m = fallback[y0:y1, x0:x1]
        if not m.any():
            continue
        sample = rgb[y0:y1, x0:x1][m]
        # bias toward brighter skin
        order = sample.mean(1).argsort()
        pick = sample[order[len(order) // 2 :]]
        out[y, x, :3] = pick.mean(0).astype(np.uint8)
        out[y, x, 3] = 255
    return out


def _clear_black_fringe(arr: np.ndarray) -> np.ndarray:
    """Make near-black pixels that touch transparent exterior fully transparent."""
    out = arr.copy()
    a = out[..., 3]
    lum = out[..., :3].astype(np.float32).mean(2)
    transparent = a < 20
    near_black = (a > 20) & (lum < 38)
    # fringe = near-black adjacent to transparent
    touch = _dilate(transparent, 2) & near_black
    # also kill semi-transparent dark matte
    matte = (a > 20) & (a < 200) & (lum < 45)
    kill = touch | (matte & _dilate(transparent, 1))
    out[kill, 3] = 0
    out[kill, :3] = 0
    return out


def repair_cell(cell: Image.Image) -> Image.Image:
    arr = np.asarray(cell.convert("RGBA"))
    h, _ = arr.shape[:2]
    arr = _clear_black_fringe(arr)

    solid = arr[..., 3] > 36
    closed = _close(solid, 4)
    closed = _fill_narrow_row_gaps(closed, max_gap=22, y0=int(h * 0.12), y1=int(h * 0.60))
    closed &= _dilate(solid, 7)

    fill = closed & ~(arr[..., 3] > 36)
    out = _inpaint_skin(arr, fill)

    # Soft outer edge
    alpha = np.where(closed | (out[..., 3] > 36), 255.0, 0.0)
    # Keep original interior alpha where already opaque
    interior = _erode(closed, 3)
    alpha = np.where(interior, np.maximum(out[..., 3].astype(np.float32), 255.0), alpha)
    a_img = Image.fromarray(np.clip(alpha, 0, 255).astype(np.uint8), "L")
    a_blur = np.asarray(a_img.filter(ImageFilter.GaussianBlur(0.9))).astype(np.float32)
    edge = closed ^ _erode(closed, 2)
    soft = out[..., 3].astype(np.float32)
    soft[fill] = 255
    soft[edge] = a_blur[edge]
    soft[~closed & ~(out[..., 3] > 36)] = 0
    # Re-apply fringe clear after soft
    out[..., 3] = soft.astype(np.uint8)
    out = _clear_black_fringe(out)
    out[out[..., 3] < 8, :3] = 0
    return Image.fromarray(out, "RGBA")


def main() -> None:
    PREVIEW.mkdir(parents=True, exist_ok=True)
    assert BACKUP.exists(), "missing backup"
    src = Image.open(BACKUP).convert("RGBA")
    w, h = src.size
    cw = w // 4
    frames = []
    for i in range(4):
        fixed = repair_cell(src.crop((i * cw, 0, (i + 1) * cw, h)))
        frames.append(fixed)
        fixed.save(PREVIEW / f"frame_{i}.png")
        b = int((np.asarray(src.crop((i * cw, 0, (i + 1) * cw, h)))[..., 3] > 40).sum())
        a = int((np.asarray(fixed)[..., 3] > 40).sum())
        print(f"f{i}: {b} -> {a} (delta {a - b})")

    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    for i, frame in enumerate(frames):
        out.paste(frame, (i * cw, 0), frame)
    out.save(SRC)

    cell = np.asarray(frames[0])
    crop = cell[200:700, 150:850]
    yy, xx = np.indices(crop.shape[:2])
    lite = ((xx // 12) + (yy // 12)) % 2 == 0
    base = np.zeros_like(crop)
    base[lite] = (210, 210, 220, 255)
    base[~lite] = (160, 160, 175, 255)
    chk = Image.fromarray(base, "RGBA")
    chk.alpha_composite(Image.fromarray(crop))
    chk.save(PREVIEW / "fingers_checker.png")
    print("wrote", SRC)


if __name__ == "__main__":
    main()
