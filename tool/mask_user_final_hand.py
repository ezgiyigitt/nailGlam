"""Final hand from user art + nail masks from user's oval reference sheet."""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "tool"))
from make_zeynep_nail_sheets import _feather_nail_alpha, _luma  # noqa: E402
from pack_zeynep_customer import _crop_to_content, _key_black  # noqa: E402

HAND_SRC = Path(
    r"C:\Users\Ezgi\.cursor\projects\c-Users-Ezgi-Documents-GitHub-nailGlam\assets"
    r"\c__Users_Ezgi_AppData_Roaming_Cursor_User_workspaceStorage_9564a3c94e3063fd248743fa88c27cbd_images_eaf5c7e1-0c8b-48b2-a43b-81b9a0b8cef4-8c37969a-da85-48a1-b3d2-61e8b4f8fc6d.jpg"
)
SHEET_SRC = Path(
    r"C:\Users\Ezgi\.cursor\projects\c-Users-Ezgi-Documents-GitHub-nailGlam\assets"
    r"\c__Users_Ezgi_AppData_Roaming_Cursor_User_workspaceStorage_9564a3c94e3063fd248743fa88c27cbd_images_b3c8f341-e80d-4c14-bcab-22861cfc76a7-32b2acdb-df19-40b3-b2f1-23c3badbf1b9.jpg"
)

IMAGES = REPO / "assets" / "images"
REVIEW = REPO / "tool" / "review_light_nails" / "approval"
CANVAS = (833, 1446)
# Reference column top→bottom: thumb, index, middle, ring, pinky
REF_ORDER = ("thumb", "pointer", "middle", "ring", "pinky")
# Hand left→right
HAND_ORDER = ("pinky", "ring", "middle", "pointer", "thumb")


def _rgba_mask(alpha: np.ndarray) -> Image.Image:
    feather = Image.fromarray(alpha.astype(np.uint8) * 255, "L").filter(
        ImageFilter.GaussianBlur(1.2)
    )
    a = np.asarray(feather).astype(np.uint8)
    out = np.zeros((*a.shape, 4), dtype=np.uint8)
    out[..., :3] = 255
    out[..., 3] = np.where(a > 8, a, 0)
    return Image.fromarray(out, "RGBA")


def _fit_canvas(keyed: Image.Image) -> Image.Image:
    cw, ch = CANVAS
    crop = _crop_to_content(keyed)
    scale = min((cw - 24) / crop.width, (ch - 24) / crop.height)
    nw, nh = max(1, round(crop.width * scale)), max(1, round(crop.height * scale))
    scaled = crop.resize((nw, nh), Image.LANCZOS)
    canvas = Image.new("RGBA", CANVAS, (0, 0, 0, 0))
    canvas.alpha_composite(scaled, ((cw - nw) // 2, ch - nh - 12))
    return canvas


def _white_ovals(ref: Image.Image) -> list[tuple[np.ndarray, tuple[int, int, int, int]]]:
    arr = np.asarray(ref.convert("RGB"))
    white = (arr.min(axis=2) > 210) & (arr.max(axis=2) > 240)
    h, w = white.shape
    seen = np.zeros((h, w), dtype=bool)
    blobs: list[tuple[np.ndarray, tuple[int, int, int, int]]] = []
    for y, x in zip(*np.where(white)):
        if seen[y, x]:
            continue
        stack = [(int(x), int(y))]
        pts: list[tuple[int, int]] = []
        while stack:
            cx, cy = stack.pop()
            if cx < 0 or cy < 0 or cx >= w or cy >= h or seen[cy, cx] or not white[cy, cx]:
                continue
            seen[cy, cx] = True
            pts.append((cx, cy))
            stack.extend(((cx - 1, cy), (cx + 1, cy), (cx, cy - 1), (cx, cy + 1)))
        if len(pts) < 400:
            continue
        blob = np.zeros((h, w), dtype=bool)
        xs = [p[0] for p in pts]
        ys = [p[1] for p in pts]
        for cx, cy in pts:
            blob[cy, cx] = True
        bbox = (int(min(xs)), int(min(ys)), int(max(xs)), int(max(ys)))
        blobs.append((blob, bbox))
    blobs.sort(key=lambda item: (item[1][1] + item[1][3]) / 2)
    if len(blobs) != 5:
        raise RuntimeError(f"expected 5 reference ovals, found {len(blobs)}")
    return blobs


def _score_nail_at(
    finger: np.ndarray,
    lum: np.ndarray,
    x: int,
    *,
    half: int = 20,
) -> tuple[float, float, float, int] | None:
    h, w = finger.shape
    if x < 0 or x >= w or not finger[:, x].any():
        return None
    y_tip = int(np.where(finger[:, x])[0].max())
    x0, x1 = max(0, x - half), min(w, x + half + 1)
    y0 = max(0, y_tip - 42)
    patch_f = finger[y0 : y_tip + 1, x0:x1]
    patch_l = lum[y0 : y_tip + 1, x0:x1]
    nail = patch_f & (patch_l > 160)
    ys, xs = np.where(nail)
    if ys.size < 25:
        nail = patch_f & (patch_l > 140)
        ys, xs = np.where(nail)
    if ys.size < 15:
        return None
    cx = float(xs.mean()) + x0
    cy = float(ys.mean()) + y0
    rad = max(
        10.0,
        max(xs.max() - xs.min() + 1, ys.max() - ys.min() + 1) * 0.55,
    )
    return cx, cy, rad, int(ys.size)


def _nail_centers(hand: Image.Image) -> dict[str, tuple[float, float, float]]:
    """Find each nail plate by scanning bright tip clusters left→right."""
    arr = np.asarray(hand)
    finger = arr[..., 3] > 20
    lum = _luma(arr[..., :3].astype(np.float32))
    h, w = finger.shape

    cols = np.flatnonzero(finger.any(axis=0))
    x_lo, x_hi = int(cols[0]), int(cols[-1])

    samples: list[tuple[int, tuple[float, float, float, int]]] = []
    for x in range(x_lo, x_hi + 1, 4):
        hit = _score_nail_at(finger, lum, x)
        if hit and hit[3] > 80:
            samples.append((x, hit))

    peaks: list[tuple[int, tuple[float, float, float, int]]] = []
    for i in range(1, len(samples) - 1):
        prev = samples[i - 1][1][3]
        cur = samples[i][1][3]
        nxt = samples[i + 1][1][3]
        if cur >= prev and cur >= nxt:
            peaks.append(samples[i])

    peaks.sort(key=lambda item: -item[1][3])
    chosen: list[tuple[int, tuple[float, float, float, int]]] = []
    min_sep = 38
    for x, hit in peaks:
        if all(abs(x - px) >= min_sep for px, _ in chosen):
            chosen.append((x, hit))
        if len(chosen) == 5:
            break
    chosen.sort(key=lambda item: item[0])

    if len(chosen) != 5:
        raise RuntimeError(f"only found {len(chosen)} nail peaks")

    scale = {"pinky": 0.92, "ring": 0.98, "middle": 1.02, "pointer": 0.98, "thumb": 1.08}
    centers: dict[str, tuple[float, float, float]] = {}
    for stem, (_, (cx, cy, rad, _)) in zip(HAND_ORDER, chosen, strict=True):
        centers[stem] = (cx, cy, rad * scale[stem])
    return centers


def _paste_oval(
    canvas: np.ndarray,
    oval: np.ndarray,
    bbox: tuple[int, int, int, int],
    center: tuple[float, float],
    radius: float,
) -> None:
    x0, y0, x1, y1 = bbox
    ow, oh = x1 - x0 + 1, y1 - y0 + 1
    target = max(12, int(radius * 2))
    sx = target / max(ow, oh)
    nw = max(4, int(round(ow * sx)))
    nh = max(4, int(round(oh * sx)))
    patch = (
        Image.fromarray(oval.astype(np.uint8) * 255, "L")
        .crop((x0, y0, x1 + 1, y1 + 1))
        .resize((nw, nh), Image.LANCZOS)
    )
    alpha = (np.asarray(patch) > 127).astype(np.uint8)
    px = int(round(center[0] - nw / 2))
    py = int(round(center[1] - nh / 2))
    h, w = canvas.shape
    ysl = max(0, py)
    yel = min(h, py + nh)
    xsl = max(0, px)
    xel = min(w, px + nw)
    if ysl >= yel or xsl >= xel:
        return
    oy0 = ysl - py
    ox0 = xsl - px
    canvas[ysl:yel, xsl:xel] |= alpha[oy0 : oy0 + (yel - ysl), ox0 : ox0 + (xel - xsl)].astype(bool)


def _preview_multicolor(hand: Image.Image, masks: dict[str, Image.Image]) -> Image.Image:
    preview = hand.copy()
    colors = {
        "pinky": (255, 107, 168),
        "ring": (208, 18, 58),
        "middle": (230, 184, 162),
        "pointer": (155, 90, 182),
        "thumb": (212, 160, 23),
    }
    for stem, rgb in colors.items():
        tint = Image.new("RGBA", hand.size, (*rgb, 0))
        tint.putalpha(masks[stem].split()[-1].point(lambda v: int(v * 0.93)))
        preview = Image.alpha_composite(preview, tint)
    bg = Image.new("RGBA", hand.size, (255, 182, 193, 255))
    bg.alpha_composite(preview)
    return bg.convert("RGB")


def _preview_align(hand: Image.Image, masks: dict[str, Image.Image]) -> Image.Image:
    bg = Image.new("RGBA", hand.size, (255, 182, 193, 255))
    bg.alpha_composite(hand)
    ov = np.zeros((*hand.size[::-1], 4), dtype=np.uint8)
    for i, stem in enumerate(HAND_ORDER):
        m = np.asarray(masks[stem])[..., 3] > 40
        ov[m] = (60, 200 + (i * 11) % 40, 90, 175)
    bg = Image.alpha_composite(bg, Image.fromarray(ov, "RGBA"))
    return bg.convert("RGB")


def main() -> None:
    hand = _fit_canvas(_key_black(Image.open(HAND_SRC).convert("RGBA"), fill_tolerance=18))

    sheet = Image.open(SHEET_SRC).convert("RGB")
    split = int(sheet.width * 0.58)
    ovals = _white_ovals(sheet.crop((split, 0, sheet.width, sheet.height)))
    ref_map = dict(zip(REF_ORDER, ovals, strict=True))

    centers = _nail_centers(hand)
    h, w = CANVAS[1], CANVAS[0]
    combined = np.zeros((h, w), dtype=bool)
    masks: dict[str, Image.Image] = {}

    for stem in HAND_ORDER:
        ref_stem = stem if stem != "pointer" else "pointer"
        # REF: thumb, pointer, middle, ring, pinky
        oval, bbox = ref_map[{"pinky": "pinky", "ring": "ring", "middle": "middle", "pointer": "pointer", "thumb": "thumb"}[stem]]
        plate = np.zeros((h, w), dtype=bool)
        cx, cy, rad = centers[stem]
        _paste_oval(plate, oval, bbox, (cx, cy), rad)
        combined |= plate
        masks[stem] = _rgba_mask(_feather_nail_alpha(plate))

    hand.save(IMAGES / "final_hand_light.png")
    for stem, mask in masks.items():
        mask.save(IMAGES / f"final_hand_light_nail_{stem}.png")
    _rgba_mask(_feather_nail_alpha(combined)).save(IMAGES / "final_hand_light_nail_mask.png")

    REVIEW.mkdir(parents=True, exist_ok=True)
    _preview_multicolor(hand, masks).save(
        REVIEW / "preview_user_final_hand_multicolor.jpg",
        quality=94,
    )
    _preview_align(hand, masks).save(
        REVIEW / "preview_user_final_hand_mask_align.jpg",
        quality=94,
    )
    print("installed with oval masks", IMAGES / "final_hand_light.png")


if __name__ == "__main__":
    main()
