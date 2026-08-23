"""Fast packer: vectorized studio-backdrop keying + foot-aligned sheets."""

from __future__ import annotations

from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "images"
SRC = Path(
    r"C:\Users\Ezgi\.cursor\projects\c-Users-Ezgi-Documents-GitHub-nailGlam\assets"
)


def clear_studio_bg(im: Image.Image) -> Image.Image:
    arr = np.asarray(im.convert("RGBA")).copy()
    rgb = arr[:, :, :3].astype(np.int16)
    dark = rgb.sum(axis=2)
    # Near-black fills.
    alpha = arr[:, :, 3].astype(np.int16)
    alpha = np.where(dark < 28, 0, np.where(dark < 48, (dark * 5).clip(0, 255), alpha))

    r, g, b = rgb[:, :, 0], rgb[:, :, 1], rgb[:, :, 2]
    sat = np.maximum(np.maximum(r, g), b) - np.minimum(np.minimum(r, g), b)
    lum = (r + g + b) / 3.0

    # Light gray / off-white studio (baked "transparent" checkers).
    studio = ((sat <= 20) & (lum >= 175)) | ((sat <= 14) & (lum >= 155))
    # Soft mauve/lavender studio leftovers.
    studio |= (sat <= 35) & (lum >= 210) & (np.abs(r - g) < 16) & (np.abs(g - b) < 22)

    alpha = np.where(studio, 0, alpha)
    arr[:, :, 3] = alpha.astype(np.uint8)
    return Image.fromarray(arr, "RGBA")


def crop_opaque(im: Image.Image) -> Image.Image:
    arr = np.asarray(im)
    alpha = arr[:, :, 3]
    ys, xs = np.where(alpha > 16)
    if xs.size == 0:
        raise SystemExit(f"empty frame after keying")
    pad = 2
    x0 = max(0, int(xs.min()) - pad)
    y0 = max(0, int(ys.min()) - pad)
    x1 = min(im.width, int(xs.max()) + 1 + pad)
    y1 = min(im.height, int(ys.max()) + 1 + pad)
    return im.crop((x0, y0, x1, y1))


def pack(paths: list[Path], columns: int, margin: int = 6) -> Image.Image:
    frames = [crop_opaque(clear_studio_bg(Image.open(p))) for p in paths]
    max_w = max(f.width for f in frames)
    max_h = max(f.height for f in frames)
    cell_w = max_w + margin * 2
    cell_h = max_h + margin * 2
    rows = (len(frames) + columns - 1) // columns
    sheet = Image.new("RGBA", (cell_w * columns, cell_h * rows), (0, 0, 0, 0))
    for i, frame in enumerate(frames):
        col = i % columns
        row = i // columns
        x = col * cell_w + (cell_w - frame.width) // 2
        y = row * cell_h + cell_h - margin - frame.height
        sheet.paste(frame, (x, y), frame)
    print(f"{len(frames)} frames {sheet.size} cell={cell_w}x{cell_h} cols={columns}")
    origins = [
        f"Vector2({(i % columns) * cell_w}, {(i // columns) * cell_h})"
        for i in range(len(frames))
    ]
    print(f"  frameSize: Vector2({cell_w}, {cell_h}),")
    print(f"  framePositions: <Vector2>[{', '.join(origins)}],")
    print(f"  footPaddings: const <double>[{', '.join(['0'] * len(frames))}],")
    print(f"  displayScale: {888.0 / cell_h:.3f},")
    return sheet


def main() -> None:
    walk = pack(
        [
            SRC / n
            for n in (
                "cycle_1_contact.png",
                "cycle_2_down.png",
                "cycle_3_pass.png",
                "cycle_4_up.png",
                "cycle_5_opp_contact.png",
                "cycle_6_opp_pass.png",
            )
        ],
        columns=6,
    )
    sit = pack(
        [
            SRC / n
            for n in (
                "sit_01_stand.png",
                "sit_02_bend.png",
                "sit_03_mid.png",
                "sit_04_seated.png",
            )
        ],
        columns=4,
    )
    hands = pack(
        [
            SRC / n
            for n in (
                "hands_01_lap.png",
                "hands_02_lift.png",
                "hands_03_reach.png",
                "hands_04_planted.png",
            )
        ],
        columns=4,
    )
    OUT.mkdir(parents=True, exist_ok=True)
    walk.save(OUT / "customer_01_walk.png")
    sit.save(OUT / "customer_01_sit.png")
    hands.save(OUT / "customer_01_hands_to_table.png")
    hands.save(OUT / "customer_01_sit_idle.png")
    print(f"wrote sheets into {OUT}")


if __name__ == "__main__":
    main()
