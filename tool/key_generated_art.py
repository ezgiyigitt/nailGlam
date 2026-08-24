"""Turn magenta-backed renders into game-ready PNGs.

The image generator cannot output alpha, so character and prop art is rendered
on a flat magenta field. This cuts that field away and writes the result into
``assets/images``.

The cut is a flood fill seeded from the image border rather than a colour
threshold: pink flowers, pink polish bottles and blush satin sit close enough
to magenta in colour space that any threshold wide enough to catch the
background also eats them.

Characters keep their original canvas: the walk and sit poses must stay on the
same frame or she jumps when the sprite swaps. Props are cropped to their
artwork and then padded back out to the aspect ratio the scene lays them out
with, so the game never has to stretch them.

Usage:
    python tool/key_generated_art.py <source-dir>
    python tool/key_generated_art.py <source-dir> menu
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

REPO_ROOT = Path(__file__).resolve().parent.parent
OUT_DIR = REPO_ROOT / "assets" / "images"

# Per-channel spread the flood fill tolerates while spreading over the flat
# background. Wide enough for the renderer's gradient banding, tight enough to
# stop at the silhouette.
FILL_TOLERANCE = 70

# Euclidean RGB distance at which an enclosed pocket still counts as backdrop.
POCKET_TOLERANCE = 70

# Narrowest pocket that survives the opening pass, in pixels.
POCKET_MIN_SPAN = 9

SENTINEL = (1, 254, 2)


def _background_mask(
    image: Image.Image,
    fill_tolerance: int,
    pocket_tolerance: int,
    pocket_min_span: int,
) -> np.ndarray:
    canvas = image.convert("RGB")
    width, height = canvas.size
    seeds = [
        (0, 0),
        (width - 1, 0),
        (0, height - 1),
        (width - 1, height - 1),
        (width // 2, 0),
    ]
    for seed in seeds:
        ImageDraw.floodfill(canvas, seed, SENTINEL, thresh=fill_tolerance)

    # Background also shows through enclosed gaps the border fill cannot reach,
    # such as scissor handles, the glass jar or the wedge between a logo
    # character and the letters below her. Those gaps are seeded by colour and
    # then filled, so a gap that drifts with the backdrop gradient still goes.
    for seed in _pocket_seeds(image, pocket_tolerance, pocket_min_span):
        if canvas.getpixel(seed) != SENTINEL:
            ImageDraw.floodfill(canvas, seed, SENTINEL, thresh=fill_tolerance)

    pixels = np.asarray(canvas, dtype=np.int32)
    return np.all(pixels == np.array(SENTINEL, dtype=np.int32), axis=-1)


def _pocket_seeds(
    image: Image.Image, tolerance: int, min_span: int
) -> list[tuple[int, int]]:
    """Points inside gaps that still show the backdrop.

    Contours drawn in a near-backdrop tone match the colour test too, and
    seeding a fill on one would let it crawl through the artwork. They are
    hairlines, so an opening pass drops them while leaving real gaps seeded.
    """
    pixels = np.asarray(image.convert("RGB"), dtype=np.int32)
    backdrop = pixels[0, 0]
    pocket = np.sqrt(((pixels - backdrop) ** 2).sum(axis=-1)) < tolerance
    pocket = (
        np.asarray(
            Image.fromarray((pocket * 255).astype(np.uint8), "L")
            .filter(ImageFilter.MinFilter(min_span))
            .filter(ImageFilter.MaxFilter(min_span))
        )
        > 127
    )
    stride = max(1, min_span // 2)
    return [
        (int(x), int(y)) for y, x in np.argwhere(pocket)[:: stride * stride]
    ]


def _key(
    image: Image.Image,
    fill_tolerance: int = FILL_TOLERANCE,
    pocket_tolerance: int = POCKET_TOLERANCE,
    pocket_min_span: int = POCKET_MIN_SPAN,
) -> Image.Image:
    filled = _background_mask(
        image, fill_tolerance, pocket_tolerance, pocket_min_span
    )

    rgba = np.asarray(image.convert("RGBA"), dtype=np.int32).copy()
    rgba[..., 3] = np.where(filled, 0, 255)

    alpha = Image.fromarray(rgba[..., 3].astype(np.uint8), "L")
    # Erode a pixel to bite off the magenta fringe the renderer leaves on soft
    # edges, then soften what is left so the silhouette is not stair-stepped.
    alpha = alpha.filter(ImageFilter.MinFilter(3)).filter(
        ImageFilter.GaussianBlur(0.6)
    )
    rgba[..., 3] = np.asarray(alpha, dtype=np.int32)

    # Pull magenta out of the surviving half-transparent rim only.
    edge = rgba[..., 3] < 255
    cap = rgba[..., 1] + 40
    rgba[..., 0] = np.where(edge, np.minimum(rgba[..., 0], cap), rgba[..., 0])
    rgba[..., 2] = np.where(edge, np.minimum(rgba[..., 2], cap), rgba[..., 2])

    return Image.fromarray(rgba.astype(np.uint8), "RGBA")


def _crop_to_content(image: Image.Image) -> Image.Image:
    bbox = image.getbbox()
    return image.crop(bbox) if bbox else image


def _pad_to_aspect(image: Image.Image, aspect: float) -> Image.Image:
    """Grows the canvas with transparency until it matches [aspect].

    Padding is added at the top or the sides only: the artwork stays welded to
    the bottom edge, which is where the scene anchors it.
    """
    width, height = image.size
    target_height = int(round(width / aspect))
    if target_height >= height:
        canvas = Image.new("RGBA", (width, target_height), (0, 0, 0, 0))
        canvas.paste(image, (0, target_height - height))
        return canvas

    target_width = int(round(height * aspect))
    canvas = Image.new("RGBA", (target_width, height), (0, 0, 0, 0))
    canvas.paste(image, ((target_width - width) // 2, 0))
    return canvas


def process(
    source: Path,
    name: str,
    *,
    crop: bool = False,
    aspect: float | None = None,
    fill_tolerance: int = FILL_TOLERANCE,
    pocket_tolerance: int = POCKET_TOLERANCE,
    pocket_min_span: int = POCKET_MIN_SPAN,
) -> None:
    image = _key(
        Image.open(source), fill_tolerance, pocket_tolerance, pocket_min_span
    )
    if crop or aspect is not None:
        image = _crop_to_content(image)
    if aspect is not None:
        image = _pad_to_aspect(image, aspect)

    image.save(OUT_DIR / name)
    print(f"{name}: {image.size[0]}x{image.size[1]}")


def _cells(image: Image.Image, columns: int, rows: int) -> list[Image.Image]:
    width, height = image.size
    cell_width = width // columns
    cell_height = height // rows
    return [
        image.crop(
            (
                column * cell_width,
                row * cell_height,
                (column + 1) * cell_width,
                (row + 1) * cell_height,
            )
        )
        for row in range(rows)
        for column in range(columns)
    ]


def _scaled(frame: Image.Image, factor: float) -> Image.Image:
    if factor == 1:
        return frame
    size = (max(1, round(frame.width * factor)), max(1, round(frame.height * factor)))
    return frame.resize(size, Image.LANCZOS)


def _head_anchor(frame: Image.Image) -> tuple[int, int]:
    """Returns the horizontal centre and the top of the character's head.

    Registering on the head rather than the whole silhouette is what keeps the
    animation still: a swinging arm changes the overall bounding box every
    frame, while the head barely moves.
    """
    alpha = np.asarray(frame.split()[3], dtype=np.int32) > 8
    rows = np.flatnonzero(alpha.any(axis=1))
    top = int(rows[0])
    head_band = alpha[top : top + max(1, frame.height // 4)]
    columns = np.flatnonzero(head_band.any(axis=0))
    return int((columns[0] + columns[-1]) // 2), top


def pack_character(sources: list[tuple[Path, str, int, int, float]]) -> None:
    """Packs every customer pose onto one shared cell.

    All poses come out of the generator at different scales and sit at
    different heights inside their cell, so the game would pop each time it
    swapped sprites. Here every frame is scaled to a common head size, then
    registered on the head, then laid out on one cell size shared across all
    the strips. The game can therefore draw any pose at one size and one
    anchor.

    Each source is (path, output name, columns, rows, head scale), where the
    head scale was measured off the delivered render: it is the factor that
    brings that pose's head down to the size of the walk pose's head.
    """
    packs: list[tuple[str, list[Image.Image], list[tuple[int, int]]]] = []
    for source, name, columns, rows, head_scale in sources:
        keyed = _key(Image.open(source))
        frames = [
            _scaled(_crop_to_content(cell), head_scale)
            for cell in _cells(keyed, columns, rows)
        ]
        packs.append((name, frames, [_head_anchor(frame) for frame in frames]))

    every = [
        (frame, anchor)
        for _, frames, anchors in packs
        for frame, anchor in zip(frames, anchors)
    ]
    left_reach = max(anchor[0] for _, anchor in every)
    right_reach = max(frame.width - anchor[0] for frame, anchor in every)
    head_room = max(anchor[1] for _, anchor in every)
    depth = max(frame.height - anchor[1] for frame, anchor in every)

    # Bilinear filtering samples past the cell edge. Without a transparent
    # gutter the next walk pose bleeds in as a ghost on her back.
    pad_x = 24
    pad_y = 8
    cell_width = left_reach + right_reach + pad_x * 2
    cell_height = head_room + depth + pad_y * 2

    for name, frames, anchors in packs:
        strip = Image.new(
            "RGBA", (cell_width * len(frames), cell_height), (0, 0, 0, 0)
        )
        for index, (frame, (anchor_x, anchor_y)) in enumerate(
            zip(frames, anchors)
        ):
            strip.paste(
                frame,
                (
                    index * cell_width + pad_x + left_reach - anchor_x,
                    pad_y + head_room - anchor_y,
                ),
            )
        strip.save(OUT_DIR / name)
        print(f"{name}: {strip.size[0]}x{strip.size[1]} ({len(frames)} frames)")


def process_menu(source_dir: Path) -> None:
    """Crops the title and the two menu labels to their artwork."""
    for name in ("nail_glam_logo.png", "btn_start.png", "btn_how_to_play.png"):
        process(source_dir / name, name, crop=True)


def main() -> int:
    if len(sys.argv) not in (2, 3):
        print(__doc__)
        return 2

    source_dir = Path(sys.argv[1])
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    if len(sys.argv) == 3:
        if sys.argv[2] != "menu":
            print(__doc__)
            return 2
        process_menu(source_dir)
        return 0

    process_menu(source_dir)

    # The desk aspect matches the box the scene reserves for it, so it is
    # placed pixel-for-pixel instead of stretched.
    process(source_dir / "salon_chair.png", "salon_chair.png", crop=True)
    process(
        source_dir / "nail_table.png",
        "nail_table.png",
        aspect=1166 / 760,
    )

    pack_character(
        [
            (source_dir / "customer_walk_sheet.png", "customer_walk.png", 2, 2, 1.0),
            (source_dir / "customer_turn_sheet.png", "customer_turn.png", 2, 2, 1.0),
            (source_dir / "customer_sit.png", "customer_sit.png", 1, 1, 0.258),
        ]
    )

    room = Image.open(source_dir / "salon_room_mint.png").convert("RGB")
    room.save(OUT_DIR / "salon_room.png")
    print(f"salon_room.png: {room.size[0]}x{room.size[1]}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
