"""Repair black fringe + sharp top crops on light finger strip sheets.

Targets (4 equal-width 464x1398 cells packed to 1856x1398):
- middle_clean_light.png
- pinky_clean_light.png
- middle_short_light.png (only if fringe candidates > 5000)

Backups written once if missing (*_fringe_backup.png).
"""

from __future__ import annotations

import shutil
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

REPO = Path(__file__).resolve().parent.parent
IMAGES = REPO / "assets" / "images"
CELL_W, CELL_H = 464, 1398
STRIP_W, STRIP_H = 1856, 1398
TOP_FADE_PX = 32  # within 24-40


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


def _luma(rgb: np.ndarray) -> np.ndarray:
    return 0.2126 * rgb[..., 0] + 0.7152 * rgb[..., 1] + 0.0722 * rgb[..., 2]


def fringe_candidates(arr: np.ndarray) -> int:
    """alpha 1-250 & rgb all < 40."""
    a = arr[..., 3]
    rgb = arr[..., :3]
    return int(((a >= 1) & (a <= 250) & (rgb < 40).all(2)).sum())


def _clear_black_fringe(arr: np.ndarray) -> np.ndarray:
    """Near-black adjacent to transparent → clear; dark matte → clear; rim tint."""
    out = arr.copy()
    a = out[..., 3]
    lum = out[..., :3].astype(np.float32).mean(2)
    transparent = a < 20
    near_black = (a > 20) & (lum < 38)
    touch = _dilate(transparent, 2) & near_black
    matte = (a > 20) & (a < 200) & (lum < 45)
    kill = touch | (matte & _dilate(transparent, 1))
    out[kill, 3] = 0
    out[kill, :3] = 0

    # Tint remaining semi-transparent rim toward interior skin median (peach).
    opaque = out[..., 3] > 12
    if not opaque.any():
        return out
    interior = (
        np.asarray(
            Image.fromarray(opaque.astype(np.uint8) * 255, "L").filter(
                ImageFilter.MinFilter(9)
            )
        )
        > 127
    )
    if not interior.any():
        interior = (
            np.asarray(
                Image.fromarray(opaque.astype(np.uint8) * 255, "L").filter(
                    ImageFilter.MinFilter(5)
                )
            )
            > 127
        )
    if not interior.any():
        return out

    skin = np.median(out[interior, :3].astype(np.float32), axis=0)
    skin_lum = float(_luma(skin.reshape(1, 1, 3))[0, 0])

    def _ring(px: int) -> np.ndarray:
        op = out[..., 3] > 12
        inner = (
            np.asarray(
                Image.fromarray(op.astype(np.uint8) * 255, "L").filter(
                    ImageFilter.MinFilter(px)
                )
            )
            > 127
        )
        return op & ~inner

    # Extra near-black halo eat (from pack_c12_pinky_cut._defringe).
    for px in (5, 3):
        lum2 = _luma(out[..., :3].astype(np.float32))
        dark = _ring(px) & (lum2 < max(70.0, skin_lum * 0.48))
        out[dark] = 0

    rim = _ring(5)
    semi = rim & (out[..., 3] > 12) & (out[..., 3] < 250)
    if semi.any():
        lum2 = _luma(out[..., :3].astype(np.float32))
        pull = np.clip((skin_lum * 0.92 - lum2) / max(18.0, skin_lum * 0.45), 0.0, 1.0)
        w = (pull * 0.85 * semi.astype(np.float32))[..., None]
        rgb = out[..., :3].astype(np.float32)
        rgb = rgb * (1.0 - w) + skin.reshape(1, 1, 3) * w
        out[..., :3] = np.clip(rgb, 0, 255).astype(np.uint8)
        # Boost alpha slightly on tinted rim so no dark halo shows through.
        boost = semi & (out[..., 3] < 220)
        out[boost, 3] = np.minimum(
            255, (out[boost, 3].astype(np.float32) * 1.12 + 8).astype(np.uint8)
        )

    return out


def _soft_outer_silhouette(arr: np.ndarray) -> np.ndarray:
    """Slight Gaussian soft on alpha at 1-2px edge ring only."""
    out = arr.copy()
    solid = out[..., 3] > 36
    if not solid.any():
        return out
    edge = solid & ~_erode(solid, 2)
    if not edge.any():
        return out
    a = out[..., 3].astype(np.float32)
    a_img = Image.fromarray(np.clip(a, 0, 255).astype(np.uint8), "L")
    a_blur = np.asarray(a_img.filter(ImageFilter.GaussianBlur(1.2))).astype(np.float32)
    soft = a.copy()
    soft[edge] = a_blur[edge]
    # Keep fully transparent exterior fully clear.
    soft[~solid & (out[..., 3] < 8)] = 0
    out[..., 3] = np.clip(soft, 0, 255).astype(np.uint8)
    out[out[..., 3] < 8, :3] = 0
    return out


def _soften_top_crop(arr: np.ndarray, fade_px: int = TOP_FADE_PX) -> np.ndarray:
    """Vertical alpha fade on topmost opaque stump only — not nail tip at bottom."""
    out = arr.copy()
    a = out[..., 3]
    opaque = a > 36
    if not opaque.any():
        return out

    rows = np.any(opaque, axis=1)
    ys = np.where(rows)[0]
    y0 = int(ys[0])
    # Only fade near the top stump; ignore anything deep in the finger/nail.
    y1 = min(out.shape[0], y0 + fade_px)
    # Guard: if the opaque mass starts near the bottom, skip (would hit nail tip).
    if y0 > out.shape[0] * 0.55:
        return out

    fade_h = y1 - y0
    if fade_h <= 0:
        return out

    # Linear 0→1 over the fade band (fully faded at topmost opaque row).
    t = np.linspace(0.0, 1.0, fade_h, dtype=np.float32)
    # Only apply where there is already some alpha in that column's top band.
    band = out[y0:y1].copy()
    for i, w in enumerate(t):
        row_a = band[i, :, 3].astype(np.float32)
        # Multiply alpha by fade weight so knife-edge softens.
        band[i, :, 3] = np.clip(row_a * w, 0, 255).astype(np.uint8)
        band[i, band[i, :, 3] < 8, :3] = 0
    out[y0:y1] = band
    return out


def repair_cell(cell: Image.Image) -> Image.Image:
    arr = np.asarray(cell.convert("RGBA"))
    arr = _clear_black_fringe(arr)
    arr = _soft_outer_silhouette(arr)
    arr = _clear_black_fringe(arr)  # re-clear after soft edge
    arr = _soften_top_crop(arr)
    return Image.fromarray(arr, "RGBA")


def even_cells(strip: Image.Image) -> list[Image.Image]:
    assert strip.size == (STRIP_W, STRIP_H), strip.size
    return [strip.crop((i * CELL_W, 0, (i + 1) * CELL_W, CELL_H)) for i in range(4)]


def pack_strip(cells: list[Image.Image]) -> Image.Image:
    out = Image.new("RGBA", (STRIP_W, STRIP_H), (0, 0, 0, 0))
    for i, cell in enumerate(cells):
        assert cell.size == (CELL_W, CELL_H), cell.size
        out.paste(cell, (i * CELL_W, 0))
    return out


def process_sheet(name: str, force: bool = True) -> None:
    src = IMAGES / name
    backup = IMAGES / name.replace(".png", "_fringe_backup.png")
    if not src.exists():
        print(f"SKIP missing: {src}")
        return

    before_img = Image.open(src).convert("RGBA")
    assert before_img.size == (STRIP_W, STRIP_H), before_img.size
    before_arr = np.asarray(before_img)
    before_n = fringe_candidates(before_arr)

    if not force and before_n <= 5000:
        print(f"{name}: fringe_candidates={before_n} (<=5000) — skip")
        return

    if not backup.exists():
        shutil.copy2(src, backup)
        print(f"backup -> {backup.name}")
    else:
        print(f"backup exists: {backup.name}")

    # Prefer repairing from backup so re-runs are idempotent on original fringe.
    base = Image.open(backup).convert("RGBA")
    cells = [repair_cell(c) for c in even_cells(base)]
    out = pack_strip(cells)
    after_arr = np.asarray(out)
    after_n = fringe_candidates(after_arr)
    out.save(src)
    print(
        f"{name}: fringe_candidates before={before_n} after={after_n} "
        f"saved {out.size[0]}x{out.size[1]} RGBA"
    )


def main() -> None:
    process_sheet("middle_clean_light.png", force=True)
    process_sheet("pinky_clean_light.png", force=True)
    process_sheet("middle_short_light.png", force=False)


if __name__ == "__main__":
    main()
