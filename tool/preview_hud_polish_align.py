"""Preview HUD polish ovals mapped through BoxFit.contain (light + dark)."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw

REPO = Path(__file__).resolve().parent.parent
IMAGES = REPO / "assets" / "images"
OUT = REPO / "tool" / "review_hud"
OUT.mkdir(parents=True, exist_ok=True)

LIGHT = {
    "pinky": (0.0619, 0.8008, 0.0372, 0.0270),
    "ring": (0.2540, 0.9141, 0.0426, 0.0328),
    "middle": (0.4979, 0.9561, 0.0438, 0.0322),
    "pointer": (0.7590, 0.9201, 0.0426, 0.0325),
    "thumb": (0.9386, 0.7071, 0.0444, 0.0332),
}
DARK = {
    "pinky": (0.2530, 0.7071, 0.0257, 0.0586),
    "ring": (0.3738, 0.8726, 0.0270, 0.0737),
    "middle": (0.5182, 0.9217, 0.0283, 0.0708),
    "pointer": (0.6589, 0.8697, 0.0309, 0.0718),
    "thumb": (0.7556, 0.5476, 0.0309, 0.0674),
}


def contain_dest(box_w: float, box_h: float, img_w: int, img_h: int) -> tuple[float, float, float, float]:
    image_aspect = img_w / img_h
    box_aspect = box_w / box_h
    if box_aspect > image_aspect:
        draw_h = box_h
        draw_w = draw_h * image_aspect
    else:
        draw_w = box_w
        draw_h = draw_w / image_aspect
    left = (box_w - draw_w) / 2
    top = box_h - draw_h
    return left, top, draw_w, draw_h


def render(skin: str, layouts: dict, polish: str = "pinky") -> Path:
    hand = Image.open(IMAGES / f"final_hand_{skin}.png").convert("RGBA")
    card_w, card_h = 132, 156
    pad = (4, 8, 4, 26)
    paint_w = card_w - pad[0] - pad[2]
    paint_h = card_h - pad[1] - pad[3]

    card = Image.new("RGBA", (card_w, card_h), (255, 248, 251, 255))
    draw = ImageDraw.Draw(card)
    draw.rounded_rectangle((0, 0, card_w - 1, card_h - 1), 20, outline=(232, 160, 184), width=2)

    left, top, draw_w, draw_h = contain_dest(paint_w, paint_h, hand.width, hand.height)
    fitted = hand.resize((max(1, round(draw_w)), max(1, round(draw_h))), Image.LANCZOS)
    ox = pad[0] + left
    oy = pad[1] + top
    card.alpha_composite(fitted, (round(ox), round(oy)))

    # Wrong mapping (old bug): normalized to full paint box.
    bad = layouts[polish]
    bx = pad[0] + bad[0] * paint_w
    by = pad[1] + bad[1] * paint_h
    brx, bry = bad[2] * paint_w, bad[3] * paint_h

    # Correct mapping: normalized to contain dest.
    cx = ox + bad[0] * draw_w
    cy = oy + bad[1] * draw_h
    rx, ry = bad[2] * draw_w, bad[3] * draw_h

    overlay = Image.new("RGBA", card.size, (0, 0, 0, 0))
    od = ImageDraw.Draw(overlay)
    od.ellipse((bx - brx, by - bry, bx + brx, by + bry), fill=(255, 0, 0, 90))
    od.ellipse((cx - rx, cy - ry, cx + rx, cy + ry), fill=(220, 20, 60, 230))
    card = Image.alpha_composite(card, overlay)

    # Assert polish center lands on opaque hand pixels.
    hx = int(round((cx - ox) * hand.width / draw_w))
    hy = int(round((cy - oy) * hand.height / draw_h))
    hx = max(0, min(hand.width - 1, hx))
    hy = max(0, min(hand.height - 1, hy))
    alpha = hand.getpixel((hx, hy))[3]
    assert alpha > 64, f"{skin} {polish} mapped off-hand alpha={alpha} at {(hx, hy)}"

    # Bad mapping for light pinky should be off-hand (documents the bug).
    if skin == "light" and polish == "pinky":
        bhx = int(round((bx - ox) * hand.width / draw_w))
        # bx is left of dest; expect outside or near edge
        assert bx < ox + 8, "expected old pinky mapping in left letterbox"

    out = OUT / f"hud_polish_{skin}_{polish}.png"
    card.save(out)
    print("saved", out, "hand_alpha", alpha)
    return out


def main() -> None:
    render("light", LIGHT, "pinky")
    render("light", LIGHT, "middle")
    render("dark", DARK, "pinky")
    print("ok")


if __name__ == "__main__":
    main()
