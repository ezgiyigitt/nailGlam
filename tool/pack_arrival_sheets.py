"""Key, isolate, and pack the arrival character sheets plus props."""

from __future__ import annotations

from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
GEN = Path(
    r"C:\Users\Ezgi\.cursor\projects\c-Users-Ezgi-Documents-GitHub-nailGlam\assets"
)
OUT = ROOT / "assets" / "images"


def key_studio(im: Image.Image) -> Image.Image:
    """Drop only the near-black backdrop. White trousers must stay opaque."""
    arr = np.asarray(im.convert("RGBA")).copy()
    rgb = arr[:, :, :3].astype(np.int16)
    dark = rgb.sum(axis=2)
    alpha = arr[:, :, 3].astype(np.int16)
    alpha = np.where(dark < 28, 0, np.where(dark < 46, (dark * 5).clip(0, 255), alpha))
    arr[:, :, 3] = alpha.astype(np.uint8)
    return Image.fromarray(arr, "RGBA")


def crop_opaque(im: Image.Image, pad: int = 4) -> Image.Image:
    arr = np.asarray(im)
    ys, xs = np.where(arr[:, :, 3] > 16)
    if xs.size == 0:
        raise SystemExit("empty after keying")
    x0 = max(0, int(xs.min()) - pad)
    y0 = max(0, int(ys.min()) - pad)
    x1 = min(im.width, int(xs.max()) + 1 + pad)
    y1 = min(im.height, int(ys.max()) + 1 + pad)
    return im.crop((x0, y0, x1, y1))


def row_figures(im: Image.Image, count: int) -> list[Image.Image]:
    arr = np.asarray(im)
    vis = arr[:, :, 3] > 16
    occ = vis.any(axis=0)
    runs: list[tuple[int, int]] = []
    start = None
    for i, filled in enumerate(occ):
        if filled and start is None:
            start = i
        elif not filled and start is not None:
            if i - start > 12:
                runs.append((start, i))
            start = None
    if start is not None and im.width - start > 12:
        runs.append((start, im.width))
    runs.sort(key=lambda r: r[1] - r[0], reverse=True)
    picked = sorted(runs[:count], key=lambda r: r[0])
    if len(picked) < count:
        raise SystemExit(f"expected {count} figures, found {len(picked)}")
    frames = []
    for x0, x1 in picked:
        slice_im = im.crop((x0, 0, x1, im.height))
        frames.append(crop_opaque(slice_im, pad=6))
    return frames


def pack_frames(frames: list[Image.Image], margin: int = 20) -> Image.Image:
    max_w = max(f.width for f in frames)
    max_h = max(f.height for f in frames)
    cell_w = max_w + margin * 2
    cell_h = max_h + margin * 2
    sheet = Image.new("RGBA", (cell_w * len(frames), cell_h), (0, 0, 0, 0))
    for i, frame in enumerate(frames):
        x = i * cell_w + (cell_w - frame.width) // 2
        y = cell_h - margin - frame.height
        sheet.paste(frame, (x, y), frame)
    print(f"  packed {len(frames)} {sheet.size} cell={cell_w}x{cell_h}")
    return sheet


def save_prop(src: Path, dest: Path) -> None:
    keyed = crop_opaque(key_studio(Image.open(src)), pad=8)
    keyed.save(dest)
    print(f"  prop {dest.name} {keyed.size}")


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)

    walk_names = (
        "walk_02_r_down.png",
        "walk_01_r_contact.png",
        "walk_03_l_pass.png",
        "walk_08_r_reach.png",
        "walk_07_r_pass.png",
        "walk_05_l_contact.png",
        "walk_04_l_reach.png",
        "walk_06_l_down.png",
    )
    walk_frames = [crop_opaque(key_studio(Image.open(GEN / n))) for n in walk_names]
    walk = pack_frames(walk_frames, margin=24)
    walk.save(OUT / "customer1_walk.png")

    stop = pack_frames(
        [crop_opaque(key_studio(Image.open(GEN / "walk_09_stand.png")))],
        margin=24,
    )
    stop.save(OUT / "customer1_stop.png")

    turn_frames = row_figures(key_studio(Image.open(GEN / "turn_to_chair.png")), 4)
    turn = pack_frames(turn_frames, margin=22)
    turn.save(OUT / "customer1_sit.png")

    sit_frames = row_figures(key_studio(Image.open(GEN / "sit_abc.png")), 3)
    sit_frames += row_figures(key_studio(Image.open(GEN / "sit_def.png")), 3)
    sit = pack_frames(sit_frames, margin=22)
    sit.save(OUT / "customer1_wait.png")

    save_prop(GEN / "salon_chair_manicure.png", OUT / "salon_chair.png")
    save_prop(GEN / "table_34.png", OUT / "table.png")
    print(f"wrote sheets into {OUT}")


if __name__ == "__main__":
    main()
