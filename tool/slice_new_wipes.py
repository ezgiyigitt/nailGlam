"""Slice the delivered new_wipe.png sheet into six standalone wipe-tin PNGs.

The sheet is six full-bleed wipe tins side by side on a transparent
background (buffer-0..buffer-5's art, in ascending shop-tier order left to
right). AtlasToolImage renders any icon whose path isn't a literal built-in
constant (AssetPaths.nailBuffer etc.) as a full-bleed image, so each tin just
needs to be its own tightly-cropped PNG — same treatment as the other shop
skins (tool_spray_N.png, tool_clips_N.png, soap_bottle_N.png).

This replaces two earlier attempts that both went wrong: tool_wipe_1/2/3.png
were bad crops, and the "fix" pointed AssetPaths.toolWipe1..3 at
tool_wipe_premium_1/2/3.png — three frames cut from a *different*, four-box
strip — while toolWipe4..6 still pointed at the bad files. So the drawer was
showing two unrelated art sets in one shelf.

Usage:
    python tool/slice_new_wipes.py

Slicing is by alpha column runs rather than a fixed cell width: the tins are
not evenly spaced on the sheet (gaps run 12–23px, and the two top tiers are
wider than the starter). A fixed 2172/6 grid clips the crowns off the last
two. The run count is asserted, so a re-delivered sheet with a different
number of tins fails loudly instead of silently mis-slicing.
"""

import numpy as np
from PIL import Image

SHEET = "assets/images/new_wipe.png"
OUT_TEMPLATE = "assets/images/tool_wipe_{index}.png"

# Alpha at or below this is treated as empty. 16 and 128 find the same six
# runs on this sheet, so the split is not sitting on a threshold cliff.
ALPHA_FLOOR = 16

# Horizontal slack when lifting a cell out, before it is re-trimmed tight.
# Deliberately under half the narrowest gap between two tins (12px) so a
# neighbour's glow can never be pulled into this cell's crop.
PAD = 4

EXPECTED = 6


def column_runs(alpha: np.ndarray) -> list[tuple[int, int]]:
    """Start/end x of every vertical band of the sheet that has any pixels."""
    has_content = (alpha > ALPHA_FLOOR).any(axis=0)
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
    # A stray antialiased speck between tins would read as its own run and
    # throw the count off, so anything too narrow to be a tin is dropped.
    return [(a, b) for a, b in runs if b - a > 20]


def main() -> None:
    sheet = Image.open(SHEET).convert("RGBA")
    runs = column_runs(np.asarray(sheet)[:, :, 3])

    if len(runs) != EXPECTED:
        raise SystemExit(
            f"expected {EXPECTED} wipe tins, found {len(runs)} column runs: "
            f"{runs}"
        )

    tins: list[Image.Image] = []
    for x0, x1 in runs:
        cell = sheet.crop(
            (max(0, x0 - PAD), 0, min(sheet.width, x1 + PAD), sheet.height)
        )
        cell_alpha = np.asarray(cell)[:, :, 3]
        ys, xs = np.nonzero(cell_alpha > ALPHA_FLOOR)
        tins.append(
            cell.crop(
                (
                    xs.min(),
                    max(0, ys.min() - PAD),
                    xs.max() + 1,
                    min(cell.height, ys.max() + 1 + PAD),
                )
            )
        )

    # Every tin is then padded out to one shared canvas, centred across and
    # sitting on a common bottom edge.
    #
    # Tight crops alone are wrong here even though they are "correct": the
    # shop card scales each icon with BoxFit.contain, so a taller PNG is
    # shrunk to fit and its tin body ends up visibly smaller than its
    # neighbours'. The tins are drawn at the same scale on the sheet (the
    # crops are all 330–353 wide); it is the crowns and finials on the upper
    # tiers that make those frames taller. A shared canvas hands that height
    # difference back to the art instead of the layout — the bodies line up
    # along the shelf and the crown simply reaches higher, which is the whole
    # point of the tier.
    canvas_w = max(tin.width for tin in tins)
    canvas_h = max(tin.height for tin in tins)

    for index, tin in enumerate(tins, start=1):
        canvas = Image.new("RGBA", (canvas_w, canvas_h), (0, 0, 0, 0))
        canvas.paste(tin, ((canvas_w - tin.width) // 2, canvas_h - tin.height), tin)
        out_path = OUT_TEMPLATE.format(index=index)
        canvas.save(out_path)
        print(f"{out_path}: {canvas.size} (tin {tin.size})")


if __name__ == "__main__":
    main()
