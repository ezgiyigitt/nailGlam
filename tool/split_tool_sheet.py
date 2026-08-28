"""Split a 6-item magenta-keyed tool spritesheet into equal PNG tiers."""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw


def chroma_key(im: Image.Image) -> Image.Image:
    arr = np.asarray(im.convert("RGBA")).astype(np.float32)
    r, g, b = arr[:, :, 0], arr[:, :, 1], arr[:, :, 2]
    magenta_dist = np.sqrt((r - 255) ** 2 + (g - 0) ** 2 + (b - 255) ** 2)
    alpha = np.ones_like(r) * 255.0
    alpha[magenta_dist < 90] = 0
    soft = (magenta_dist >= 90) & (magenta_dist < 160) & (g < 140)
    alpha[soft] = ((magenta_dist[soft] - 90) / 70 * 255).clip(0, 255)
    extra = (g < 80) & (r > 200) & (b > 200) & (magenta_dist < 200)
    alpha[extra] = np.minimum(alpha[extra], ((magenta_dist[extra] - 60) / 100 * 255).clip(0, 255))
    out = arr.copy()
    out[:, :, 3] = alpha
    edge = (alpha > 0) & (alpha < 250) & (g < 150)
    out[edge, 0] = np.minimum(out[edge, 0], out[edge, 1] + 40)
    out[edge, 2] = np.minimum(out[edge, 2], out[edge, 1] + 40)
    return Image.fromarray(out.astype(np.uint8), "RGBA")


def find_segments(col: np.ndarray) -> list[tuple[int, int]]:
    is_gap = col < 25
    segments: list[tuple[int, int]] = []
    in_content = False
    start = 0
    for x, gap in enumerate(is_gap):
        if not gap and not in_content:
            start = x
            in_content = True
        elif gap and in_content:
            segments.append((start, x - 1))
            in_content = False
    if in_content:
        segments.append((start, len(col) - 1))
    return segments


def split_to_six(keyed: Image.Image) -> list[tuple[int, int]]:
    ka = np.array(keyed)
    opaque = ka[:, :, 3] > 12
    col = opaque.sum(axis=0)
    w = keyed.size[0]
    merged = find_segments(col)
    while len(merged) < 6:
        widest = max(range(len(merged)), key=lambda i: merged[i][1] - merged[i][0])
        a, b = merged[widest]
        sub = col[a : b + 1]
        inner = sub[20:-20]
        if len(inner) < 10:
            break
        split = a + 20 + int(inner.argmin())
        merged[widest : widest + 1] = [(a, split - 1), (split + 1, b)]
    if len(merged) != 6:
        raise RuntimeError(f"expected 6 segments, got {len(merged)}: {merged}")
    padded: list[tuple[int, int]] = []
    for i, (a, b) in enumerate(merged):
        left_gap = 0 if i == 0 else (merged[i - 1][1] + a) // 2 + 1
        right_gap = w - 1 if i == 5 else (b + merged[i + 1][0]) // 2
        padded.append((max(left_gap, a - 4), min(right_gap, b + 4)))
    return padded


def export_sheet(src: Path, out_dir: Path, prefix: str, cell_size: int = 512) -> None:
    keyed = chroma_key(Image.open(src))
    w, h = keyed.size
    ranges = split_to_six(keyed)
    out_dir.mkdir(parents=True, exist_ok=True)
    cells: list[Image.Image] = []
    for i, (xa, xb) in enumerate(ranges):
        cell = keyed.crop((xa, 0, xb + 1, h))
        c = np.array(cell)
        ys, xs = np.where(c[:, :, 3] > 12)
        cropped = cell.crop((xs.min(), ys.min(), xs.max() + 1, ys.max() + 1))
        cw, ch = cropped.size
        scale = min((cell_size * 0.88) / cw, (cell_size * 0.92) / ch)
        nw, nh = max(1, int(cw * scale)), max(1, int(ch * scale))
        resized = cropped.resize((nw, nh), Image.Resampling.LANCZOS)
        canvas = Image.new("RGBA", (cell_size, cell_size), (0, 0, 0, 0))
        canvas.paste(resized, ((cell_size - nw) // 2, (cell_size - nh) // 2), resized)
        cells.append(canvas)
        canvas.save(out_dir / f"{prefix}_tier_{i + 1}.png")

    sheet = Image.new("RGBA", (cell_size * 6, cell_size), (0, 0, 0, 0))
    for i, canvas in enumerate(cells):
        sheet.paste(canvas, (i * cell_size, 0), canvas)
    sheet.save(out_dir / f"{prefix}_6_sheet_equal.png")

    bg = Image.new("RGBA", sheet.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(bg)
    s = 24
    for y in range(0, sheet.height, s):
        for x in range(0, sheet.width, s):
            color = (235, 235, 240, 255) if ((x // s) + (y // s)) % 2 == 0 else (210, 210, 218, 255)
            draw.rectangle([x, y, x + s - 1, y + s - 1], fill=color)
    preview = Image.alpha_composite(bg, sheet)
    d = ImageDraw.Draw(preview)
    for i in range(1, 6):
        x = i * cell_size
        d.line([(x, 0), (x, sheet.height - 1)], fill=(255, 60, 60, 180), width=2)
    preview.save(out_dir / f"{prefix}_6_preview_checker.png")
    print(f"wrote {out_dir}")


def main() -> None:
    if len(sys.argv) != 4:
        raise SystemExit("usage: split_tool_sheet.py <src.png> <out_dir> <prefix>")
    export_sheet(Path(sys.argv[1]), Path(sys.argv[2]), sys.argv[3])


if __name__ == "__main__":
    main()
