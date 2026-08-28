from __future__ import annotations

from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

REPO = Path(r"C:\Users\Ezgi\Documents\GitHub\nailGlam")
IMAGES = REPO / "assets" / "images"
TOOL = REPO / "tool"
CELL_W, CELL_H = 464, 1398
N_FRAMES = 4
BG = (0xC9, 0xB2, 0x9A)


def luma(rgb: np.ndarray) -> np.ndarray:
    r = rgb[..., 0].astype(np.float32)
    g = rgb[..., 1].astype(np.float32)
    b = rgb[..., 2].astype(np.float32)
    return 0.299 * r + 0.587 * g + 0.114 * b


def dilate(mask: np.ndarray, r: int) -> np.ndarray:
    out = mask.astype(bool)
    for _ in range(max(0, r)):
        img = Image.fromarray(out.astype(np.uint8) * 255, "L")
        out = np.array(img.filter(ImageFilter.MaxFilter(3))) > 0
    return out


def erode(mask: np.ndarray, r: int) -> np.ndarray:
    out = mask.astype(bool)
    for _ in range(max(0, r)):
        img = Image.fromarray(out.astype(np.uint8) * 255, "L")
        out = np.array(img.filter(ImageFilter.MinFilter(3))) > 0
    return out


def cuticle_roi(nail: np.ndarray, opaque: np.ndarray) -> np.ndarray:
    """Thin band at cuticle U (nail base) + lower sidewall starts vs skin."""
    h, w = nail.shape
    dil = dilate(nail, 2)
    ero = erode(nail, 2)
    ring = dil & (~ero)

    base_band = np.zeros_like(nail, dtype=bool)
    for x in range(w):
        col = np.where(nail[:, x])[0]
        if len(col) < 8:
            continue
        by = int(col.max())
        ty = int(col.min())
        hgt = max(1, by - ty)
        y0 = by - max(6, int(0.14 * hgt))
        y1 = min(h, by + 8)
        base_band[y0:y1, x] = True

    side_band = np.zeros_like(nail, dtype=bool)
    ys, _xs = np.where(nail)
    mid_y = int(np.percentile(ys, 55))
    for y in range(mid_y, h):
        row = np.where(nail[y])[0]
        if len(row) < 5:
            continue
        lx, rx = int(row.min()), int(row.max())
        side_band[y, max(0, lx - 3) : min(w, lx + 6)] = True
        side_band[y, max(0, rx - 5) : min(w, rx + 4)] = True

    side_cut = np.zeros_like(side_band)
    for x in range(w):
        col = np.where(nail[:, x])[0]
        if len(col) < 8:
            continue
        by, ty = int(col.max()), int(col.min())
        y0 = by - int(0.38 * (by - ty))
        side_cut[y0 : by + 6, x] = True
    side_band &= side_cut

    roi = (base_band | side_band) & ring
    roi |= base_band & dilate(ring, 1)
    roi &= opaque
    return roi


def local_skin_color(frame: np.ndarray, nail: np.ndarray, opaque: np.ndarray) -> np.ndarray:
    skin = opaque & (~dilate(nail, 1))
    L = luma(frame)
    skin &= L > 140

    skin_rgb = frame[..., :3].astype(np.float32).copy()
    weight = skin.astype(np.float32)
    for c in range(3):
        skin_rgb[..., c] *= weight

    def blur_f32(ch: np.ndarray, radius: int = 8) -> np.ndarray:
        img = Image.fromarray(np.clip(ch, 0, 255).astype(np.uint8), "L")
        for _ in range(3):
            img = img.filter(ImageFilter.GaussianBlur(radius=radius))
        return np.asarray(img, dtype=np.float32)

    w_blur = blur_f32(weight * 255.0, 8) / 255.0
    out = np.zeros((*frame.shape[:2], 3), dtype=np.float32)
    for c in range(3):
        out[..., c] = blur_f32(skin_rgb[..., c], 8)
    w_safe = np.maximum(w_blur, 1e-3)
    out /= w_safe[..., None]

    if skin.any():
        med = np.median(frame[skin, :3].astype(np.float32), axis=0)
    else:
        med = np.array([210.0, 170.0, 140.0], dtype=np.float32)
    need = w_blur < 0.05
    out[need] = med
    return out


def soft_fix_frame(frame: np.ndarray, nail: np.ndarray, strength: str) -> tuple[np.ndarray, int]:
    out = frame.copy()
    opaque = out[..., 3] > 200
    if not nail.any() or not opaque.any():
        return out, 0

    roi = cuticle_roi(nail, opaque)
    if not roi.any():
        return out, 0

    L = luma(out)
    skin_ref = local_skin_color(out, nail, opaque)
    skin_L = luma(skin_ref)
    delta = skin_L - L

    if strength == "strong":
        hard = roi & (delta > 28) & (L < skin_L - 20) & (L < 165)
        charcoal = roi & (L < 110) & (delta > 15)
        adjust = hard | charcoal
        blend = np.clip((delta - 20) / 55.0, 0.35, 0.82)
    else:
        adjust = roi & (L < 95) & (delta > 35)
        blend = np.clip((delta - 30) / 60.0, 0.25, 0.55)

    n = int(adjust.sum())
    if n == 0:
        return out, 0

    rgb = out[..., :3].astype(np.float32)
    b = blend[..., None]
    mixed = rgb * (1.0 - b) + skin_ref * b
    rgb[adjust] = mixed[adjust]

    blur_mask = dilate(adjust, 1) & opaque
    rgb_u8 = np.clip(rgb, 0, 255).astype(np.uint8)
    blurred = np.array(
        Image.fromarray(rgb_u8, "RGB").filter(ImageFilter.GaussianBlur(radius=0.9))
    ).astype(np.float32)
    t = np.zeros(adjust.shape, dtype=np.float32)
    t[adjust] = 0.55
    t[blur_mask & ~adjust] = 0.25
    rgb = rgb * (1 - t[..., None]) + blurred * t[..., None]

    out[..., :3] = np.clip(rgb, 0, 255).astype(np.uint8)
    return out, n


def process_sheet(path: Path, mask_path: Path) -> list[int]:
    sheet = np.array(Image.open(path).convert("RGBA"))
    assert sheet.shape[0] == CELL_H and sheet.shape[1] == CELL_W * N_FRAMES
    mask_im = np.array(Image.open(mask_path).convert("RGBA"))
    assert mask_im.shape[0] == CELL_H and mask_im.shape[1] == CELL_W
    nail = mask_im[..., 3] > 128

    counts = []
    out_sheet = sheet.copy()
    for fi in range(N_FRAMES):
        x0 = fi * CELL_W
        cell = sheet[:, x0 : x0 + CELL_W].copy()
        strength = "strong" if fi < 2 else "light"
        fixed, n = soft_fix_frame(cell, nail, strength)
        out_sheet[:, x0 : x0 + CELL_W] = fixed
        counts.append(n)
        print(f"  {path.name} frame {fi} ({strength}): {n} cuticle pixels adjusted")

    Image.fromarray(out_sheet, "RGBA").save(path)
    return counts


def make_preview(sheet_path: Path, out_path: Path) -> None:
    sheet = np.array(Image.open(sheet_path).convert("RGBA"))
    cell = sheet[:, 0:CELL_W]
    bg = np.zeros_like(cell)
    bg[:] = (*BG, 255)
    a = cell[..., 3:4].astype(np.float32) / 255.0
    comp = (cell.astype(np.float32) * a + bg.astype(np.float32) * (1 - a)).astype(np.uint8)
    comp[..., 3] = 255
    Image.fromarray(comp, "RGBA").save(out_path)
    print(f"  preview -> {out_path.name} on #{BG[0]:02X}{BG[1]:02X}{BG[2]:02X}")


def main() -> None:
    jobs = [
        (IMAGES / "middle_clean_light.png", IMAGES / "middle_nail_mask_light.png"),
        (IMAGES / "pinky_clean_light.png", IMAGES / "pinky_nail_mask_light.png"),
    ]
    for sheet, mask in jobs:
        print(f"Processing {sheet.name} (mask {mask.name} {Image.open(mask).size})")
        process_sheet(sheet, mask)
    make_preview(IMAGES / "middle_clean_light.png", TOOL / "_preview_middle_clean_frame0.png")
    for p in [IMAGES / "middle_clean_light.png", IMAGES / "pinky_clean_light.png"]:
        im = Image.open(p)
        print(f"saved {p.name}: {im.size} {im.mode}")


if __name__ == "__main__":
    main()
