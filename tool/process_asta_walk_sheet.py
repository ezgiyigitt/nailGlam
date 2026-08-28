"""Punch checkerboard bg to alpha and pack walk sheet into game cell size."""

from __future__ import annotations

import os

from PIL import Image

SRC = r"C:\Users\Ezgi\.cursor\projects\c-Users-Ezgi-Documents-GitHub-nailGlam\assets\asta_walk_sheet_v1.png"
OUT_DIR = r"C:\Users\Ezgi\Documents\GitHub\nailGlam\tool\review_asta_fresh"
TW, TH = 432, 433


def is_bg(r: int, g: int, b: int, a: int = 255) -> bool:
    if a < 10:
        return True
    mx, mn = max(r, g, b), min(r, g, b)
    # checkerboard light gray / white
    if mx - mn <= 12 and mn >= 170:
        return True
    if mx - mn <= 18 and mn >= 140 and abs(r - g) <= 10 and abs(g - b) <= 10:
        return True
    return False


def main() -> None:
    os.makedirs(OUT_DIR, exist_ok=True)
    im = Image.open(SRC).convert("RGBA")
    w, h = im.size
    print("src", w, h, im.mode)

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

    band_w = w // 4
    crops: list[Image.Image | None] = []
    heights: list[int] = []
    widths: list[int] = []
    for i in range(4):
        x0 = i * band_w
        x1 = (i + 1) * band_w if i < 3 else w
        cell = out.crop((x0, 0, x1, h))
        bx = cell.getbbox()
        print(f"frame{i} band {x0}-{x1} bbox {bx}")
        if not bx:
            crops.append(None)
            continue
        # inset 2px from band edges to avoid neighbor bleed
        left, top, right, bottom = bx
        left = max(left, 2)
        right = min(right, cell.width - 2)
        crop = cell.crop((left, top, right, bottom))
        crops.append(crop)
        widths.append(crop.width)
        heights.append(crop.height)

    max_h = max(heights)
    max_w = max(widths)
    margin_top = 8
    margin_bottom = 12
    margin_x = 14
    avail_h = TH - margin_top - margin_bottom
    avail_w = TW - 2 * margin_x
    scale = min(avail_h / max_h, avail_w / max_w)
    print("unified scale", scale, "max", max_w, max_h)

    sheet = Image.new("RGBA", (TW * 4, TH), (0, 0, 0, 0))
    for i, crop in enumerate(crops):
        if crop is None:
            continue
        nw = max(1, int(round(crop.width * scale)))
        nh = max(1, int(round(crop.height * scale)))
        # hard clamp so hair never spills into next cell
        if nw > TW - 4:
            nh = max(1, int(round(nh * (TW - 4) / nw)))
            nw = TW - 4
        resized = crop.resize((nw, nh), Image.Resampling.LANCZOS)
        x = i * TW + (TW - nw) // 2
        y = margin_top
        x = max(i * TW + 2, min(x, (i + 1) * TW - nw - 2))
        sheet.paste(resized, (x, y), resized)

    out_path = os.path.join(OUT_DIR, "asta_walk_sheet_transparent.png")
    sheet.save(out_path)
    print("saved", out_path, sheet.size, sheet.mode)

    for i in range(4):
        fr = sheet.crop((i * TW, 0, (i + 1) * TW, TH))
        fr.save(os.path.join(OUT_DIR, f"asta_walk_f{i}.png"))
        print(f"f{i} bbox", fr.getbbox())


if __name__ == "__main__":
    main()
