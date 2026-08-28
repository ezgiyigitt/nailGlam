"""Remove flat gray/checkerboard background and pack Asta turn sheet."""

from __future__ import annotations

import os

from PIL import Image

SRC = r"C:\Users\Ezgi\.cursor\projects\c-Users-Ezgi-Documents-GitHub-nailGlam\assets\asta_turn_sheet_v1.png"
OUT_DIR = r"C:\Users\Ezgi\Documents\GitHub\nailGlam\tool\review_asta_fresh"
TW, TH = 432, 433


def is_bg(r: int, g: int, b: int, a: int = 255) -> bool:
    if a < 10:
        return True
    mx, mn = max(r, g, b), min(r, g, b)
    # flat light gray used as chroma (#C8C8C8-ish) or checkerboard
    if mx - mn <= 14 and mn >= 160:
        return True
    if mx - mn <= 20 and mn >= 130 and abs(r - g) <= 12 and abs(g - b) <= 12:
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


def pack_sheet(out: Image.Image, prefix: str) -> str:
    w, h = out.size
    band_w = w // 4
    crops: list[Image.Image | None] = []
    heights: list[int] = []
    widths: list[int] = []
    for i in range(4):
        x0 = i * band_w
        x1 = (i + 1) * band_w if i < 3 else w
        cell = out.crop((x0, 0, x1, h))
        bx = cell.getbbox()
        print(f"{prefix} frame{i} band {x0}-{x1} bbox {bx}")
        if not bx:
            crops.append(None)
            continue
        left, top, right, bottom = bx
        # keep clear of band edges so hair cannot bleed into neighbor cell
        left = max(left, 3)
        right = min(right, cell.width - 3)
        if right <= left:
            crops.append(None)
            continue
        crop = cell.crop((left, top, right, bottom))
        crops.append(crop)
        widths.append(crop.width)
        heights.append(crop.height)

    max_h = max(heights)
    max_w = max(widths)
    margin_top = 8
    margin_bottom = 12
    margin_x = 14
    scale = min((TH - margin_top - margin_bottom) / max_h, (TW - 2 * margin_x) / max_w)
    print(f"{prefix} unified scale", scale, "max", max_w, max_h)

    sheet = Image.new("RGBA", (TW * 4, TH), (0, 0, 0, 0))
    for i, crop in enumerate(crops):
        if crop is None:
            continue
        nw = max(1, int(round(crop.width * scale)))
        nh = max(1, int(round(crop.height * scale)))
        if nw > TW - 6:
            nh = max(1, int(round(nh * (TW - 6) / nw)))
            nw = TW - 6
        resized = crop.resize((nw, nh), Image.Resampling.LANCZOS)
        x = i * TW + (TW - nw) // 2
        y = margin_top
        x = max(i * TW + 3, min(x, (i + 1) * TW - nw - 3))
        sheet.paste(resized, (x, y), resized)

    out_path = os.path.join(OUT_DIR, f"{prefix}_sheet_transparent.png")
    sheet.save(out_path)
    print("saved", out_path, sheet.size)
    for i in range(4):
        fr = sheet.crop((i * TW, 0, (i + 1) * TW, TH))
        fr.save(os.path.join(OUT_DIR, f"{prefix}_f{i}.png"))
        print(f"{prefix} f{i} bbox", fr.getbbox())
    return out_path


def main() -> None:
    os.makedirs(OUT_DIR, exist_ok=True)
    punched = punch(Image.open(SRC))
    pack_sheet(punched, "asta_turn")


if __name__ == "__main__":
    main()
