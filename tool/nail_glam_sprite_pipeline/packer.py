"""Sprite sheet packer — equal cells, chronological L→R, T→B."""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

from PIL import Image
import numpy as np


@dataclass
class AtlasEntry:
    frame: int
    x: int
    y: int
    w: int
    h: int
    sequence: str


def key_black(im: Image.Image) -> Image.Image:
    arr = np.asarray(im.convert("RGBA")).copy()
    rgb = arr[:, :, :3].astype(np.int16)
    dark = rgb.sum(axis=2)
    alpha = arr[:, :, 3].astype(np.int16)
    # Only near-black — preserve cream trousers.
    alpha = np.where(dark < 28, 0, np.where(dark < 46, (dark * 5).clip(0, 255), alpha))
    arr[:, :, 3] = alpha.astype(np.uint8)
    return Image.fromarray(arr, "RGBA")


def crop_opaque(im: Image.Image, pad: int = 4) -> Image.Image:
    arr = np.asarray(im)
    ys, xs = np.where(arr[:, :, 3] > 16)
    if xs.size == 0:
        return im
    x0 = max(0, int(xs.min()) - pad)
    y0 = max(0, int(ys.min()) - pad)
    x1 = min(im.width, int(xs.max()) + 1 + pad)
    y1 = min(im.height, int(ys.max()) + 1 + pad)
    return im.crop((x0, y0, x1, y1))


def pack_sheet(
    frames: list[Image.Image],
    *,
    cell_w: int,
    cell_h: int,
    padding: int,
    columns: int | None = None,
) -> tuple[Image.Image, list[AtlasEntry]]:
    n = len(frames)
    if n == 0:
        raise ValueError("no frames to pack")
    cols = columns or max(1, int(np.ceil(np.sqrt(n))))
    rows = int(np.ceil(n / cols))
    sheet = Image.new("RGBA", (cols * cell_w, rows * cell_h), (0, 0, 0, 0))
    atlas: list[AtlasEntry] = []

    for i, fr in enumerate(frames):
        keyed = key_black(fr)
        cropped = crop_opaque(keyed, pad=2)
        # Fit inside cell with padding, bottom-align feet.
        max_w = cell_w - padding * 2
        max_h = cell_h - padding * 2
        scale = min(max_w / cropped.width, max_h / cropped.height)
        nw = max(1, int(cropped.width * scale))
        nh = max(1, int(cropped.height * scale))
        resized = cropped.resize((nw, nh), Image.Resampling.LANCZOS)
        col = i % cols
        row = i // cols
        x = col * cell_w + (cell_w - nw) // 2
        y = row * cell_h + cell_h - padding - nh
        sheet.paste(resized, (x, y), resized)
        atlas.append(
            AtlasEntry(
                frame=i,
                x=col * cell_w,
                y=row * cell_h,
                w=cell_w,
                h=cell_h,
                sequence="",
            )
        )
    return sheet, atlas


def save_individual_frames(frames: list[Image.Image], out_dir: Path) -> list[Path]:
    out_dir.mkdir(parents=True, exist_ok=True)
    paths = []
    for i, fr in enumerate(frames):
        p = out_dir / f"frame_{i:04d}.png"
        key_black(fr).save(p)
        paths.append(p)
    return paths
