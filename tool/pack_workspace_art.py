"""Copy the wood tabletop and pack the 5-frame customer emotion strip."""

from __future__ import annotations

import shutil
import sys
from pathlib import Path

from PIL import Image

from key_generated_art import (
    OUT_DIR,
    _cells,
    _crop_to_content,
    _head_anchor,
    _key,
)

SOURCE_DIR = Path(
    r"C:\Users\Ezgi\.cursor\projects\c-Users-Ezgi-Documents-GitHub-nailGlam\assets"
)


def pack_emotion(source: Path) -> None:
    keyed = _key(Image.open(source))
    frames = [_crop_to_content(cell) for cell in _cells(keyed, 5, 1)]
    anchors = [_head_anchor(frame) for frame in frames]

    left_reach = max(anchor[0] for anchor in anchors)
    right_reach = max(frame.width - anchor[0] for frame, anchor in zip(frames, anchors))
    head_room = max(anchor[1] for anchor in anchors)
    depth = max(frame.height - anchor[1] for frame, anchor in zip(frames, anchors))

    pad_x = 16
    pad_y = 8
    cell_width = left_reach + right_reach + pad_x * 2
    cell_height = head_room + depth + pad_y * 2

    strip = Image.new("RGBA", (cell_width * len(frames), cell_height), (0, 0, 0, 0))
    for index, (frame, (anchor_x, anchor_y)) in enumerate(zip(frames, anchors)):
        strip.paste(
            frame,
            (
                index * cell_width + pad_x + left_reach - anchor_x,
                pad_y + head_room - anchor_y,
            ),
        )

    out = OUT_DIR / "customer_emotion.png"
    strip.save(out)
    print(f"customer_emotion.png: {strip.size[0]}x{strip.size[1]} ({len(frames)} frames)")


def main() -> int:
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    table = SOURCE_DIR / "table_surface.png"
    if not table.exists():
        print(f"missing {table}", file=sys.stderr)
        return 1
    dest = OUT_DIR / "table_surface.png"
    shutil.copy2(table, dest)
    with Image.open(dest) as image:
        print(f"table_surface.png: {image.size[0]}x{image.size[1]}")

    emotion = SOURCE_DIR / "customer_emotion.png"
    if not emotion.exists():
        print(f"missing {emotion}", file=sys.stderr)
        return 1
    pack_emotion(emotion)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
