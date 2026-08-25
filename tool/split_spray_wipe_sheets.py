"""Build separate 4-frame spray and wipe strips from legacy combined clean sheets.

Pinky (fifth_nail_clean): spray uses source frames 0,0,1,1 — wipe uses 1,2,2,3.
Ring (fourth_nail): same mapping from fourth_nail.png.

Wipe frame 0 matches spray frame 3 (both source frame 1) for a seamless handoff.
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image

REPO = Path(__file__).resolve().parent.parent
IMAGES = REPO / "assets" / "images"

# Source window layout measured in SpriteAtlas (lib/model/sprite_atlas.dart).
PINKY_FRAMES = (
    (15, 0, 355, 879),
    (448, 0, 355, 879),
    (883, 0, 355, 879),
    (1313, 0, 355, 879),
)

RING_FRAMES = (
    (55, 0, 355, 758),
    (565, 0, 355, 758),
    (1045, 0, 355, 758),
    (1549, 0, 355, 758),
)

SPRAY_MAP = (0, 0, 1, 1)
WIPE_MAP = (1, 2, 2, 3)


def _crop_cell(src: Image.Image, box: tuple[int, int, int, int]) -> Image.Image:
    x, y, w, h = box
    return src.crop((x, y, x + w, y + h))


def _pack_strip(cells: list[Image.Image]) -> Image.Image:
    w, h = cells[0].size
    out = Image.new("RGBA", (w * len(cells), h), (0, 0, 0, 0))
    for i, cell in enumerate(cells):
        out.paste(cell, (i * w, 0), cell)
    return out


def _split(
    source_name: str,
    spray_name: str,
    wipe_name: str,
    frames: tuple[tuple[int, int, int, int], ...],
) -> None:
    src_path = IMAGES / source_name
    src = Image.open(src_path).convert("RGBA")
    spray_cells = [_crop_cell(src, frames[i]) for i in SPRAY_MAP]
    wipe_cells = [_crop_cell(src, frames[i]) for i in WIPE_MAP]
    _pack_strip(spray_cells).save(IMAGES / spray_name)
    _pack_strip(wipe_cells).save(IMAGES / wipe_name)
    print(f"wrote {spray_name} and {wipe_name} from {source_name}")


def main() -> None:
    _split(
        "fifth_nail_clean.png",
        "fifth_nail_spray.png",
        "fifth_nail_wipe.png",
        PINKY_FRAMES,
    )
    _split(
        "fourth_nail.png",
        "fourth_nail_spray.png",
        "fourth_nail_wipe.png",
        RING_FRAMES,
    )


if __name__ == "__main__":
    main()
