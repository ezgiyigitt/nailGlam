"""Pack approved dirty + two mids + approved clean into one locked pinky strip."""

from __future__ import annotations

import shutil
import sys
from pathlib import Path

import numpy as np
from PIL import Image

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "tool"))
from make_zeynep_nail_sheets import PINKY_CELL, fit_finger_cell, pack_strip  # noqa: E402
from pack_zeynep_customer import _key_auto  # noqa: E402

CURSOR = Path(
    r"C:\Users\Ezgi\.cursor\projects\c-Users-Ezgi-Documents-GitHub-nailGlam\assets"
)
SRC = REPO / "tool" / "review_light_nails" / "src"
OUT = REPO / "tool" / "review_light_nails" / "approval"
PINK = (255, 182, 193)

DIRTY = CURSOR / "c__Users_Ezgi_AppData_Roaming_Cursor_User_workspaceStorage_9564a3c94e3063fd248743fa88c27cbd_images_c12_pinky_dirty_still-8113c468-107f-4916-bade-925fcf094bff.png"
MID_A = CURSOR / "c__Users_Ezgi_AppData_Roaming_Cursor_User_workspaceStorage_9564a3c94e3063fd248743fa88c27cbd_images_c12_pinky_mid_a-f68741d7-d30c-4b18-9319-de92a5aea5b3.png"
MID_B = CURSOR / "c__Users_Ezgi_AppData_Roaming_Cursor_User_workspaceStorage_9564a3c94e3063fd248743fa88c27cbd_images_c12_pinky_mid_b-deaeb142-0d9a-428a-9b6c-b7c1339aa6ed.png"
CLEAN = CURSOR / "c__Users_Ezgi_AppData_Roaming_Cursor_User_workspaceStorage_9564a3c94e3063fd248743fa88c27cbd_images_c12_pinky_clean_still-6aecb10e-fdbd-4ed3-960b-3304e5c88410.png"
FALLBACKS = (
    CURSOR / "c12_pinky_dirty_still.png",
    CURSOR / "c12_pinky_mid_a.png",
    CURSOR / "c12_pinky_mid_b.png",
    CURSOR / "c12_pinky_clean_still.png",
)


def _bbox(arr: np.ndarray, thresh: int = 10) -> tuple[int, int, int, int]:
    ys, xs = np.where(arr[..., 3] > thresh)
    return int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1


def _place(frame: Image.Image, cell: tuple[int, int], box: tuple[int, int, int, int]) -> Image.Image:
    arr = np.asarray(frame.convert("RGBA"))
    x0, y0, x1, y1 = _bbox(arr)
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
    names = (
        ("c12_pinky_dirty_user.png", DIRTY),
        ("c12_pinky_mid_a.png", MID_A),
        ("c12_pinky_mid_b.png", MID_B),
        ("c12_pinky_clean_user.png", CLEAN),
    )
    keyed: list[Image.Image] = []
    for i, (name, src) in enumerate(names):
        if not src.exists():
            src = FALLBACKS[i]
        if not src.exists():
            raise FileNotFoundError(src)
        local = SRC / name
        shutil.copy2(src, local)
        keyed.append(_key_auto(Image.open(local)))

    master = np.asarray(keyed[0].convert("RGBA"))
    x0, y0, x1, y1 = _bbox(master)
    pad = 20
    cell_w = (x1 - x0) + pad * 2
    cell_h = (y1 - y0) + pad * 2
    # Keep C3 pinky cell so later drop-in matches atlas.
    cell = PINKY_CELL
    # Fit master content into PINKY_CELL, then use that box for every frame.
    master_cell = fit_finger_cell(keyed[0], cell)
    marr = np.asarray(master_cell)
    box = _bbox(marr)
    frames = [_place(frame, cell, box) for frame in keyed]

    OUT.mkdir(parents=True, exist_ok=True)
    dest = OUT / "pinky_clean_light_c12.png"
    pack_strip(frames, dest)
    _preview(Image.open(dest), OUT / "pinky_clean_light_c12_preview.jpg")
    for i, frame in enumerate(frames):
        _preview(frame, OUT / f"pinky_clean_light_c12_f{i}.jpg")
    print("cell", cell, "strip", tuple(Image.open(dest).size))
    print("wrote", dest)


if __name__ == "__main__":
    main()
