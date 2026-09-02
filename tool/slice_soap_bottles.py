"""Slice the delivered soaps_all.png sheet into six standalone bottle PNGs.

The sheet is six full-bleed dispenser bottles side by side on a transparent
background (soap-0..soap-5's art, in ascending shop-tier order left to
right). AtlasToolImage renders any icon whose path isn't a literal built-in
constant (AssetPaths.handSoap etc.) as a full-bleed image, so each bottle
just needs to be its own tightly-cropped PNG — same treatment as the other
shop skins (tool_spray_N.png, tool_clips_N.png).

Usage:
    python tool/slice_soap_bottles.py
"""

import numpy as np
from PIL import Image

SHEET = "assets/images/soaps_all.png"
OUT_TEMPLATE = "assets/images/soap_bottle_{index}.png"
PAD = 6


def main() -> None:
    sheet = Image.open(SHEET).convert("RGBA")
    alpha = np.asarray(sheet)[:, :, 3]
    has_content = (alpha > 16).any(axis=0)

    runs: list[tuple[int, int]] = []
    start = None
    for x, present in enumerate(has_content):
        if present and start is None:
            start = x
        elif not present and start is not None:
            runs.append((start, x))
            start = None
    if start is not None:
        runs.append((start, len(has_content)))

    if len(runs) != 6:
        raise SystemExit(
            f"expected 6 bottles, found {len(runs)} column runs: {runs}"
        )

    for index, (x0, x1) in enumerate(runs, start=1):
        cell = sheet.crop(
            (max(0, x0 - PAD), 0, min(sheet.width, x1 + PAD), sheet.height)
        )
        cell_alpha = np.asarray(cell)[:, :, 3]
        ys, xs = np.nonzero(cell_alpha > 16)
        trimmed = cell.crop(
            (
                xs.min(),
                max(0, ys.min() - PAD),
                xs.max() + 1,
                min(cell.height, ys.max() + 1 + PAD),
            )
        )
        out_path = OUT_TEMPLATE.format(index=index)
        trimmed.save(out_path)
        print(f"{out_path}: {trimmed.size}")


if __name__ == "__main__":
    main()
