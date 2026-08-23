"""Key near-black to alpha and pack frames onto a shared foot line."""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
IMAGES = ROOT / "assets" / "images"


@dataclass(frozen=True)
class SheetSpec:
    src: Path
    dst: Path
    frames: int
    columns: int
    rows: int
    keep_first: int | None = None


def key_black(im: Image.Image) -> Image.Image:
    rgba = im.convert("RGBA")
    px = list(rgba.getdata())
    out = []
    for r, g, b, a in px:
        if r < 14 and g < 14 and b < 14:
            out.append((r, g, b, 0))
            continue
        darkness = r + g + b
        if darkness < 36:
            fade = int(a * darkness / 36)
            out.append((r, g, b, fade))
            continue
        out.append((r, g, b, a))
    rgba.putdata(out)
    return rgba


def opaque_bounds(im: Image.Image) -> tuple[int, int, int, int] | None:
    px = im.load()
    w, h = im.size
    min_x, min_y, max_x, max_y = w, h, -1, -1
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a < 16:
                continue
            if a > 240 and r < 12 and g < 12 and b < 12:
                continue
            if x < min_x:
                min_x = x
            if y < min_y:
                min_y = y
            if x > max_x:
                max_x = x
            if y > max_y:
                max_y = y
    if max_x < 0:
        return None
    return min_x, min_y, max_x + 1, max_y + 1


def crop_cells(spec: SheetSpec) -> list[Image.Image]:
    src = Image.open(spec.src)
    keyed = key_black(src)
    cell_w = keyed.width // spec.columns
    cell_h = keyed.height // spec.rows
    crops: list[Image.Image] = []
    count = spec.keep_first or spec.frames
    for i in range(count):
        col = i % spec.columns
        row = i // spec.columns
        cell = keyed.crop(
            (col * cell_w, row * cell_h, (col + 1) * cell_w, (row + 1) * cell_h)
        )
        bounds = opaque_bounds(cell)
        if bounds is None:
            raise SystemExit(f"empty cell {i} in {spec.src.name}")
        crops.append(cell.crop(bounds))
    return crops


def pack(frames: list[Image.Image], columns: int, margin: int = 8) -> Image.Image:
    max_w = max(im.width for im in frames)
    max_h = max(im.height for im in frames)
    cell_w = max_w + margin * 2
    cell_h = max_h + margin * 2
    rows = (len(frames) + columns - 1) // columns
    sheet = Image.new("RGBA", (cell_w * columns, cell_h * rows), (0, 0, 0, 0))
    for i, im in enumerate(frames):
        col = i % columns
        row = i // columns
        x = col * cell_w + (cell_w - im.width) // 2
        y = row * cell_h + (cell_h - margin - im.height)
        sheet.paste(im, (x, y), im)
    return sheet


def write_atlas_hint(name: str, sheet: Image.Image, count: int, columns: int) -> None:
    cell_w = sheet.width // columns
    cell_h = sheet.height // ((count + columns - 1) // columns)
    print(f"{name}: {sheet.width}x{sheet.height} cells {columns}x{count // columns} size={cell_w}x{cell_h}")
    origins = []
    for i in range(count):
        origins.append(f"Vector2({(i % columns) * cell_w}, {(i // columns) * cell_h})")
    pads = ", ".join(["0"] * count)
    print(f"  frameSize: Vector2({cell_w}, {cell_h}),")
    print(f"  framePositions: <Vector2>[{', '.join(origins)}],")
    print(f"  footPaddings: const <double>[{pads}],")


def pack_loose(paths: list[Path]) -> Image.Image:
    frames = []
    for path in paths:
        keyed = key_black(Image.open(path))
        bounds = opaque_bounds(keyed)
        if bounds is None:
            raise SystemExit(f"empty image {path}")
        frames.append(keyed.crop(bounds))
    return pack(frames, columns=len(frames))


def main() -> None:
    walk_spec = SheetSpec(
        src=IMAGES / "customer_01_walk.png",
        dst=IMAGES / "customer_01_walk.png",
        frames=8,
        columns=4,
        rows=2,
        keep_first=4,
    )
    sit_spec = SheetSpec(
        src=IMAGES / "customer_01_sit.png",
        dst=IMAGES / "customer_01_sit.png",
        frames=8,
        columns=4,
        rows=2,
    )
    hands_src = Path(
        r"C:\Users\Ezgi\.cursor\projects\c-Users-Ezgi-Documents-GitHub-nailGlam\assets"
    )

    walk_frames = crop_cells(walk_spec)
    sit_frames = crop_cells(sit_spec)
    walk = pack(walk_frames, columns=4, margin=4)
    sit = pack(sit_frames, columns=4, margin=4)
    hands = pack_loose(
        [
            hands_src / "hands_f1_lap.png",
            hands_src / "hands_f2_lift.png",
            hands_src / "hands_f3_reach.png",
            hands_src / "hands_f4_planted.png",
        ]
    )
    walk.save(walk_spec.dst)
    sit.save(sit_spec.dst)
    hands.save(IMAGES / "customer_01_hands_to_table.png")
    hands.save(IMAGES / "customer_01_sit_idle.png")
    write_atlas_hint("walk", walk, 4, 4)
    write_atlas_hint("sit", sit, 8, 4)
    write_atlas_hint("hands", hands, 4, 4)


if __name__ == "__main__":
    main()
