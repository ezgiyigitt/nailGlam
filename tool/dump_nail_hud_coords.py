from PIL import Image
import numpy as np

for skin in ("light", "dark"):
    print(skin)
    hand = Image.open(f"assets/images/final_hand_{skin}.png")
    w, h = hand.size
    for stem in ("pinky", "ring", "middle", "pointer", "thumb"):
        alpha = np.array(
            Image.open(f"assets/images/final_hand_{skin}_nail_{stem}.png").convert("RGBA")
        )[..., 3]
        ys, xs = np.where(alpha > 64)
        if ys.size == 0:
            continue
        cx, cy = xs.mean(), ys.mean()
        rx = (xs.max() - xs.min()) / 2 + 2
        ry = (ys.max() - ys.min()) / 2 + 2
        print(
            f"  {stem}: nx={cx / w:.4f} ny={cy / h:.4f} "
            f"rx={rx / w:.4f} ry={ry / h:.4f}"
        )
