"""Clean Asta sheets: remove flat gray bg, drop neighbor bleed, pack 1728x433."""

from __future__ import annotations

import os
from collections import deque

from PIL import Image

OUT_DIR = r"C:\Users\Ezgi\Documents\GitHub\nailGlam\tool\review_asta_fresh"
TW, TH = 432, 433

WALK_SRC = r"C:\Users\Ezgi\.cursor\projects\c-Users-Ezgi-Documents-GitHub-nailGlam\assets\asta_walk_sheet_v1.png"
TURN_SRC = r"C:\Users\Ezgi\.cursor\projects\c-Users-Ezgi-Documents-GitHub-nailGlam\assets\asta_turn_sheet_v1.png"


def is_bg(r: int, g: int, b: int, a: int = 255) -> bool:
    if a < 10:
        return True
    mx, mn = max(r, g, b), min(r, g, b)
    if mx - mn <= 14 and mn >= 160:
        return True
    if mx - mn <= 22 and mn >= 125 and abs(r - g) <= 14 and abs(g - b) <= 14:
        return True
    return False


def punch(im: Image.Image) -> Image.Image:
    im = im.convert("RGBA")
    w, h = im.size
    px = im.load()
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    opx = out.load()
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if is_bg(r, g, b, a):
                opx[x, y] = (0, 0, 0, 0)
            else:
                opx[x, y] = (r, g, b, 255)
    return out


def keep_largest_component(cell: Image.Image) -> Image.Image:
    """Drop orphaned pixels that leaked from a neighboring frame."""
    w, h = cell.size
    px = cell.load()
    visited = [[False] * w for _ in range(h)]
    best: list[tuple[int, int]] = []

    for y in range(h):
        for x in range(w):
            if visited[y][x] or px[x, y][3] == 0:
                continue
            q: deque[tuple[int, int]] = deque([(x, y)])
            visited[y][x] = True
            comp: list[tuple[int, int]] = []
            while q:
                cx, cy = q.popleft()
                comp.append((cx, cy))
                for nx, ny in (
                    (cx - 1, cy),
                    (cx + 1, cy),
                    (cx, cy - 1),
                    (cx, cy + 1),
                ):
                    if 0 <= nx < w and 0 <= ny < h and not visited[ny][nx]:
                        visited[ny][nx] = True
                        if px[nx, ny][3] > 0:
                            q.append((nx, ny))
            if len(comp) > len(best):
                best = comp

    cleaned = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    cpx = cleaned.load()
    for x, y in best:
        cpx[x, y] = px[x, y]
    return cleaned


def extract_crops(sheet: Image.Image) -> list[Image.Image]:
    w, h = sheet.size
    band_w = w // 4
    crops: list[Image.Image] = []
    for i in range(4):
        x0 = i * band_w
        x1 = (i + 1) * band_w if i < 3 else w
        cell = keep_largest_component(sheet.crop((x0, 0, x1, h)))
        bx = cell.getbbox()
        print(f"  frame{i} band {x0}-{x1} bbox {bx}")
        if not bx:
            raise RuntimeError(f"empty frame {i}")
        # slight inset so edge hair doesn't sit on the cell wall
        left, top, right, bottom = bx
        left = max(0, left)
        right = min(cell.width, right)
        crops.append(cell.crop((left, top, right, bottom)))
    return crops


def pack(crops: list[Image.Image], prefix: str) -> str:
    heights = [c.height for c in crops]
    widths = [c.width for c in crops]
    max_h = max(heights)
    max_w = max(widths)
    margin_top = 8
    margin_bottom = 14
    margin_x = 16
    scale = min(
        (TH - margin_top - margin_bottom) / max_h,
        (TW - 2 * margin_x) / max_w,
    )
    print(f"{prefix} scale {scale:.4f} max {max_w}x{max_h}")

    out = Image.new("RGBA", (TW * 4, TH), (0, 0, 0, 0))
    for i, crop in enumerate(crops):
        nw = max(1, int(round(crop.width * scale)))
        nh = max(1, int(round(crop.height * scale)))
        if nw > TW - 8:
            nh = max(1, int(round(nh * (TW - 8) / nw)))
            nw = TW - 8
        resized = crop.resize((nw, nh), Image.Resampling.LANCZOS)
        x = i * TW + (TW - nw) // 2
        y = margin_top
        x = max(i * TW + 4, min(x, (i + 1) * TW - nw - 4))
        out.paste(resized, (x, y), resized)

    path = os.path.join(OUT_DIR, f"{prefix}_sheet_transparent.png")
    out.save(path)
    print("saved", path, out.size)
    for i in range(4):
        fr = out.crop((i * TW, 0, (i + 1) * TW, TH))
        fr.save(os.path.join(OUT_DIR, f"{prefix}_f{i}.png"))
        bb = fr.getbbox()
        print(f"  {prefix} f{i} bbox {bb}")
        # safety: bbox must stay inside cell (always true) and not touch left/right hard
        if bb and (bb[0] <= 1 or bb[2] >= TW - 1):
            print(f"  WARNING: {prefix} f{i} touches cell edge")
    return path


def process(src: str, prefix: str) -> None:
    print("===", prefix, "===")
    punched = punch(Image.open(src))
    crops = extract_crops(punched)
    pack(crops, prefix)


def main() -> None:
    os.makedirs(OUT_DIR, exist_ok=True)
    process(WALK_SRC, "asta_walk")
    process(TURN_SRC, "asta_turn")


if __name__ == "__main__":
    main()
