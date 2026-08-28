"""Force Asta face+neck skin to emotion-sheet face color (no body-mean mix)."""

from __future__ import annotations

from pathlib import Path

import numpy as np
from PIL import Image

REPO = Path(__file__).resolve().parent.parent
REVIEW = REPO / "tool" / "review_asta_new_frames"
IMAGES = REPO / "assets" / "images"
CELL_W, CELL_H = 432, 433
LOCK_HEAD_X, LOCK_HEAD_Y = 216, 11


def _bbox(cell: Image.Image):
    a = np.asarray(cell.convert("RGBA"))[..., 3] > 8
    ys, xs = np.where(a)
    if ys.size == 0:
        return None
    return int(xs.min()), int(ys.min()), int(xs.max()), int(ys.max())


def _head(cell: Image.Image):
    a = np.asarray(cell.convert("RGBA"))[..., 3] > 8
    ys, xs = np.where(a)
    top = int(ys.min())
    band = a[top : top + max(24, CELL_H // 6)]
    cols = np.where(band.any(axis=0))[0]
    return int((int(cols[0]) + int(cols[-1])) / 2), top


def place(src: Image.Image) -> Image.Image:
    src = src.convert("RGBA")
    box = _bbox(src)
    if box is None:
        return Image.new("RGBA", (CELL_W, CELL_H), (0, 0, 0, 0))
    x0, y0, x1, y1 = box
    fig = src.crop((x0, y0, x1 + 1, y1 + 1))
    hx, hy = _head(src)
    cell = Image.new("RGBA", (CELL_W, CELL_H), (0, 0, 0, 0))
    cell.paste(fig, (LOCK_HEAD_X - (hx - x0), LOCK_HEAD_Y - (hy - y0)), fig)
    return cell


def _blur(w: np.ndarray, passes: int = 5) -> np.ndarray:
    k = np.array([1, 2, 3, 2, 1], dtype=np.float32)
    k /= k.sum()
    x = w.astype(np.float32)
    for _ in range(passes):
        p = np.pad(x, ((0, 0), (2, 2)), mode="edge")
        x = (
            p[:, 0:-4] * k[0]
            + p[:, 1:-3] * k[1]
            + p[:, 2:-2] * k[2]
            + p[:, 3:-1] * k[3]
            + p[:, 4:] * k[4]
        )
        p = np.pad(x, ((2, 2), (0, 0)), mode="edge")
        x = (
            p[0:-4] * k[0]
            + p[1:-3] * k[1]
            + p[2:-2] * k[2]
            + p[3:-1] * k[3]
            + p[4:] * k[4]
        )
    return np.clip(x, 0, 1)


def face_skin_mask(arr: np.ndarray, *, face_bottom: float = 0.48) -> np.ndarray:
    """Skin on head/face/upper neck only — excludes arms/hands."""
    h, w = arr.shape[:2]
    a = arr[..., 3] > 180
    r = arr[..., 0].astype(np.float32)
    g = arr[..., 1].astype(np.float32)
    b = arr[..., 2].astype(np.float32)
    lum = 0.2126 * r + 0.7152 * g + 0.0722 * b
    skin = (
        a
        & (lum > 55)
        & (lum < 200)
        & (r + 5 >= g)
        & (r > b)
        & ((r - b) > 12)
        & ((r - g) < 95)
    )
    yy = np.arange(h)[:, None]
    xx = np.arange(w)[None, :]
    skin &= yy < int(h * face_bottom)
    # center column — avoid side hair fringe
    skin &= (xx > w * 0.18) & (xx < w * 0.82)
    return skin


def emotion_face_target() -> np.ndarray:
    em = np.asarray(Image.open(IMAGES / "customer3_emotion.png").convert("RGBA"))
    h, w = em.shape[:2]
    ew = w // 5
    # Frame 3: normal soft smile
    cell = em[:, 3 * ew : 4 * ew]
    m = face_skin_mask(cell, face_bottom=0.85)
    assert m.sum() > 200, "emotion face skin not found"
    return cell[m, :3].astype(np.float32).mean(axis=0)


def match_face(cell: Image.Image, target: np.ndarray) -> Image.Image:
    """Pull every face-skin pixel toward emotion RGB (kills orange blush flicker)."""
    arr = np.asarray(cell.convert("RGBA")).copy()
    skin = face_skin_mask(arr)
    if skin.sum() < 80:
        return cell
    rgb = arr[..., :3].astype(np.float32)
    w = _blur(skin.astype(np.float32), passes=5)[..., None]
    # Per-pixel blend to the emotion face color — not a mean shift.
    # 0.72 keeps some shading while removing burnt-orange cheeks.
    strength = 0.72
    target_b = target.reshape(1, 1, 3)
    rgb = rgb * (1.0 - w * strength) + target_b * (w * strength)
    arr[..., :3] = np.clip(rgb, 0, 255).astype(np.uint8)

    # Extra crush on leftover hot orange cheek pixels
    r = arr[..., 0].astype(np.float32)
    g = arr[..., 1].astype(np.float32)
    b = arr[..., 2].astype(np.float32)
    hot = skin & (r > 165) & ((r - g) > 55)
    if hot.any():
        wh = _blur(hot.astype(np.float32), passes=2)[..., None]
        rgb = arr[..., :3].astype(np.float32)
        rgb = rgb * (1.0 - wh * 0.85) + target_b * (wh * 0.85)
        arr[..., :3] = np.clip(rgb, 0, 255).astype(np.uint8)
    return Image.fromarray(arr, "RGBA")


def main() -> None:
    target = emotion_face_target()
    print(f"emotion FACE target RGB={target.round(1)}")

    for group, name in (
        ("walk", "customer3_walk.png"),
        ("turn", "customer3_turn.png"),
        ("sit", "customer3_sit.png"),
    ):
        frames = []
        for i in range(4):
            cell = place(Image.open(REVIEW / f"customer3_{group}_f{i}.png"))
            before = np.asarray(cell)
            m0 = face_skin_mask(before)
            b = before[m0, :3].mean(0) if m0.any() else None
            cell = match_face(cell, target)
            after = np.asarray(cell)
            m1 = face_skin_mask(after)
            a = after[m1, :3].mean(0) if m1.any() else None
            print(
                f"  {group} f{i}: "
                f"{None if b is None else b.round(1)} -> "
                f"{None if a is None else a.round(1)}"
            )
            frames.append(cell)
        strip = Image.new("RGBA", (CELL_W * 4, CELL_H), (0, 0, 0, 0))
        for i, f in enumerate(frames):
            strip.paste(f, (i * CELL_W, 0), f)
        strip.save(IMAGES / name)
        print(f"wrote {name}")


if __name__ == "__main__":
    main()
