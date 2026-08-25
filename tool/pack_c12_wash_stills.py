"""Pack the four generated C1/C2 wash stills into one aligned transparent strip.

Does not dissolve dirt. Keys the black studio field and locks every cell to the
same content box so the hand does not jump. Approval files only.
"""

from __future__ import annotations

import shutil
import sys
from pathlib import Path

import numpy as np
from PIL import Image

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "tool"))
from pack_zeynep_customer import _key_auto  # noqa: E402

CURSOR_ASSETS = Path(
    r"C:\Users\Ezgi\.cursor\projects\c-Users-Ezgi-Documents-GitHub-nailGlam\assets"
)
SRC = REPO / "tool" / "review_light_nails" / "src"
OUT = REPO / "tool" / "review_light_nails" / "approval"
PINK = (255, 182, 193)
PAD = 28

# Dirty → half → almost → clean skin (nails stay dirty).
FRAMES = (
    "c12_wash_dirty_still.png",
    "c12_wash_f1_half.png",
    "c12_wash_f2_almost.png",
    "c12_wash_f3_clean.png",
)


def _content_bbox(arr: np.ndarray, thresh: int = 10) -> tuple[int, int, int, int]:
    ys, xs = np.where(arr[..., 3] > thresh)
    if xs.size == 0:
        return 0, 0, arr.shape[1], arr.shape[0]
    return int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1


def _place(frame: Image.Image, cell: tuple[int, int], box: tuple[int, int, int, int]) -> Image.Image:
    arr = np.asarray(frame.convert("RGBA"))
    x0, y0, x1, y1 = _content_bbox(arr)
    crop = frame.crop((x0, y0, x1, y1))
    tw, th = box[2] - box[0], box[3] - box[1]
    scale = min(tw / crop.width, th / crop.height)
    nw, nh = max(1, round(crop.width * scale)), max(1, round(crop.height * scale))
    scaled = crop.resize((nw, nh), Image.LANCZOS)
    canvas = Image.new("RGBA", cell, (0, 0, 0, 0))
    px = box[0] + (tw - nw) // 2
    py = box[1] + (th - nh) // 2
    canvas.alpha_composite(scaled, (px, py))
    return canvas


def _preview(image: Image.Image, dest: Path) -> None:
    canvas = Image.new("RGBA", image.size, (*PINK, 255))
    canvas.alpha_composite(image.convert("RGBA"))
    dest.parent.mkdir(parents=True, exist_ok=True)
    canvas.convert("RGB").save(dest, quality=92)


def main() -> None:
    SRC.mkdir(parents=True, exist_ok=True)
    keyed: list[Image.Image] = []
    for name in FRAMES:
        src = CURSOR_ASSETS / name
        if not src.exists():
            raise FileNotFoundError(src)
        local = SRC / name
        shutil.copy2(src, local)
        keyed.append(_key_auto(Image.open(local)))

    master = np.asarray(keyed[0].convert("RGBA"))
    x0, y0, x1, y1 = _content_bbox(master)
    cell_w = (x1 - x0) + PAD * 2
    cell_h = (y1 - y0) + PAD * 2
    box = (PAD, PAD, PAD + (x1 - x0), PAD + (y1 - y0))
    cell = (cell_w, cell_h)

    cells = [_place(frame, cell, box) for frame in keyed]
    strip = Image.new("RGBA", (cell_w * 4, cell_h), (0, 0, 0, 0))
    for i, frame in enumerate(cells):
        strip.paste(frame, (i * cell_w, 0), frame)

    OUT.mkdir(parents=True, exist_ok=True)
    dest = OUT / "hand_wash_light_c12.png"
    strip.save(dest)
    _preview(strip, OUT / "hand_wash_light_c12_preview.jpg")
    for i, frame in enumerate(cells):
        _preview(frame, OUT / f"hand_wash_light_c12_f{i}.jpg")
    print("cell", cell_w, cell_h, "strip", strip.size)
    print("wrote", dest)


if __name__ == "__main__":
    main()
