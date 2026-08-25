"""Preview the cute hand sim card for approval."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

REPO = Path(__file__).resolve().parent.parent
OUT = REPO / "tool" / "review_hud"
OUT.mkdir(parents=True, exist_ok=True)

SKIN = (240, 196, 168)
SKIN_S = (224, 168, 136)
NAIL = (255, 107, 168)
DIRTY = (196, 160, 90)
CLEAN = (246, 215, 200)


def _finger(draw: ImageDraw.ImageDraw, base, tip, bw, tw, nail_color=None):
    bx, by = base
    tx, ty = tip
    import math

    dx, dy = tx - bx, ty - by
    ln = max(1, math.hypot(dx, dy))
    nx, ny = -dy / ln, dx / ln
    poly = [
        (bx + nx * bw, by + ny * bw),
        (tx + nx * tw, ty + ny * tw),
        (tx, ty),
        (tx - nx * tw, ty - ny * tw),
        (bx - nx * bw, by - ny * bw),
    ]
    draw.polygon(poly, fill=SKIN, outline=SKIN_S)
    nc = nail_color or CLEAN
    draw.ellipse((tx - tw, ty - tw * 0.9, tx + tw, ty + tw * 0.5), fill=nc)


def main() -> None:
    card = Image.new("RGBA", (132, 156), (0, 0, 0, 0))
    draw = ImageDraw.Draw(card, "RGBA")
    draw.rounded_rectangle((0, 0, 131, 155), 20, fill=(255, 248, 251, 255), outline=(232, 160, 184, 255), width=2)
    palm = [(12, 112), (8, 88), (24, 72), (66, 68), (108, 72), (120, 88), (116, 112), (66, 130), (16, 112)]
    draw.polygon(palm, fill=SKIN)
    w, h = 116, 120
    ox, oy = 8, 14
    colors = {
        "pinky": NAIL,
        "ring": (208, 18, 58),
        "middle": DIRTY,
        "pointer": CLEAN,
        "thumb": (212, 160, 23),
    }
    _finger(draw, (ox + 20, oy + 70), (ox + 16, oy + 20), 8, 6, colors["pinky"])
    _finger(draw, (ox + 36, oy + 66), (ox + 34, oy + 10), 9, 7, colors["ring"])
    _finger(draw, (ox + 52, oy + 64), (ox + 52, oy + 6), 10, 7, colors["middle"])
    _finger(draw, (ox + 68, oy + 66), (ox + 70, oy + 12), 9, 7, colors["pointer"])
    _finger(draw, (ox + 84, oy + 88), (ox + 92, oy + 56), 10, 7, colors["thumb"])
    draw.rounded_rectangle((10, 132, 88, 148), 10, fill=(255, 255, 255, 240), outline=(232, 160, 184))
    draw.text((16, 134), "2 kaldı / 5", fill=(138, 75, 99))
    dest = OUT / "cute_hand_sim_preview.png"
    card.save(dest)
    print("saved", dest)


if __name__ == "__main__":
    main()
