from PIL import Image, ImageFilter, ImageDraw
import numpy as np
import shutil
from pathlib import Path

ROOT = Path(r"C:\Users\Ezgi\Documents\GitHub\nailGlam")
BEFORE = ROOT / "assets/images/salon_room_before_logo_sign.png"
OUT = ROOT / "assets/images/salon_room.png"
LOGO = ROOT / "assets/images/nail_glam_logo.png"
MAGENTA_OUT = ROOT / "tool/_logo_on_magenta.png"
TOOL = ROOT / "tool"
TOOL.mkdir(exist_ok=True)

# 1) Start fresh from before
shutil.copyfile(BEFORE, OUT)
base = Image.open(OUT).convert("RGB")
assert base.size == (1536, 1024), base.size
arr = np.array(base).astype(np.float64)

# --- Verify logo transparency ---
logo_full = Image.open(LOGO).convert("RGBA")
la = np.array(logo_full)
hL, wL = la.shape[:2]
corners = {
    "TL": int(la[0, 0, 3]),
    "TR": int(la[0, wL - 1, 3]),
    "BL": int(la[hL - 1, 0, 3]),
    "BR": int(la[hL - 1, wL - 1, 3]),
}
print("Logo corners alpha:", corners)
assert all(v == 0 for v in corners.values()), "Logo corners must be fully transparent"

# Magenta transparency check (logo alone)
mag = Image.new("RGBA", logo_full.size, (255, 0, 255, 255))
mag.alpha_composite(logo_full)
mag.convert("RGB").save(MAGENTA_OUT)
print(f"Wrote {MAGENTA_OUT}")

# Gold glass start ~ x=619
GLASS_X = 619
LOGO_W = 168  # within 160-175
GAP = 15  # 10-20px left of glass
logo_right = GLASS_X - GAP
logo_left = logo_right - LOGO_W

aspect = logo_full.height / logo_full.width
logo_h = int(round(LOGO_W * aspect))
logo = logo_full.resize((LOGO_W, logo_h), Image.Resampling.LANCZOS)

text_cy = (300 + 440) // 2
logo_top = int(text_cy - logo_h / 2)
logo_top = max(200, min(logo_top, 520 - logo_h))

print(f"Glass start x={GLASS_X}")
print(f"Logo placement: left={logo_left}, top={logo_top}, w={LOGO_W}, h={logo_h}")
print(f"Logo right edge={logo_right} (gap to glass={GLASS_X - logo_right}px)")

# --- 2) Remove painted text ---
tx0, ty0, tx1, ty1 = 115, 290, 505, 460

above_patch = arr[ty0 - 55 : ty0 - 10, tx0 + 40 : tx1 - 40]
below_patch = arr[ty1 + 10 : ty1 + 55, tx0 + 40 : tx1 - 40]
if above_patch.size == 0:
    above_patch = arr[230:270, 180:400]
if below_patch.size == 0:
    below_patch = arr[470:510, 180:400]

c_above = above_patch.mean(axis=(0, 1))
c_below = below_patch.mean(axis=(0, 1))
noise_std = float(
    np.mean(
        [
            above_patch.std(axis=(0, 1)).mean(),
            below_patch.std(axis=(0, 1)).mean(),
        ]
    )
)
noise_std = max(1.5, min(noise_std, 4.0))
print(f"Wall sample ABOVE RGB={np.round(c_above,1)} BELOW RGB={np.round(c_below,1)} noise_std={noise_std:.2f}")

ph, pw = ty1 - ty0, tx1 - tx0
t = np.linspace(0.0, 1.0, ph)[:, None, None]
grad = c_above[None, None, :] * (1 - t) + c_below[None, None, :] * t
grad = np.broadcast_to(grad, (ph, pw, 3)).copy()
rng = np.random.default_rng(42)
noise = rng.normal(0, noise_std, size=(ph, pw, 3))
noise_img = Image.fromarray(
    np.clip(noise + 128, 0, 255).astype(np.uint8)
).filter(ImageFilter.GaussianBlur(radius=1.2))
noise = np.array(noise_img).astype(np.float64) - 128.0
patch = np.clip(grad + noise, 0, 255)

pad = 36
mask_h, mask_w = ph + 2 * pad, pw + 2 * pad
mask = Image.new("L", (mask_w, mask_h), 0)
draw = ImageDraw.Draw(mask)
inset = 8
draw.rounded_rectangle(
    [pad + inset, pad + inset, mask_w - pad - inset - 1, mask_h - pad - inset - 1],
    radius=48,
    fill=255,
)
mask = mask.filter(ImageFilter.GaussianBlur(radius=22))
mask_arr = np.array(mask).astype(np.float64) / 255.0

work = arr.copy()
ex0, ey0 = tx0 - pad, ty0 - pad
ex1, ey1 = tx1 + pad, ty1 + pad
ix0, iy0 = max(0, ex0), max(0, ey0)
ix1, iy1 = min(1536, ex1), min(1024, ey1)
mx0, my0 = ix0 - ex0, iy0 - ey0

patch_layer = work[iy0:iy1, ix0:ix1].copy()
core_y0, core_x0 = ty0 - iy0, tx0 - ix0
core_y1, core_x1 = core_y0 + ph, core_x0 + pw
cy0 = max(0, core_y0)
cx0 = max(0, core_x0)
cy1 = min(patch_layer.shape[0], core_y1)
cx1 = min(patch_layer.shape[1], core_x1)
py0, px0 = cy0 - core_y0, cx0 - core_x0
py1, px1 = py0 + (cy1 - cy0), px0 + (cx1 - cx0)
patch_layer[cy0:cy1, cx0:cx1] = patch[py0:py1, px0:px1]

m = mask_arr[my0 : my0 + (iy1 - iy0), mx0 : mx0 + (ix1 - ix0)][:, :, None]
blended = patch_layer * m + work[iy0:iy1, ix0:ix1] * (1 - m)
work[iy0:iy1, ix0:ix1] = blended

band = Image.fromarray(np.clip(work[iy0:iy1, ix0:ix1], 0, 255).astype(np.uint8))
band_blur = band.filter(ImageFilter.GaussianBlur(radius=2.5))
edge = mask_arr[my0 : my0 + (iy1 - iy0), mx0 : mx0 + (ix1 - ix0)]
edge_w = (edge * (1 - edge) * 4.0).clip(0, 1)[:, :, None]
band_arr = np.array(band).astype(np.float64)
band_b = np.array(band_blur).astype(np.float64)
soft = band_arr * (1 - 0.55 * edge_w) + band_b * (0.55 * edge_w)
work[iy0:iy1, ix0:ix1] = soft

cleaned = Image.fromarray(np.clip(work, 0, 255).astype(np.uint8))

# --- 3) Composite logo with soft drop shadow ONLY ---
shadow_layer = Image.new("RGBA", cleaned.size, (0, 0, 0, 0))
logo_alpha = logo.split()[3]
sh_a = logo_alpha.point(lambda a: int(round(a * 0.28)))
shadow_rgba = Image.merge(
    "RGBA",
    (
        Image.new("L", logo.size, 0),
        Image.new("L", logo.size, 0),
        Image.new("L", logo.size, 0),
        sh_a,
    ),
)
sx, sy = logo_left + 4, logo_top + 6
shadow_layer.paste(shadow_rgba, (sx, sy), shadow_rgba)
shadow_layer = shadow_layer.filter(ImageFilter.GaussianBlur(radius=8))

out_rgba = cleaned.convert("RGBA")
out_rgba = Image.alpha_composite(out_rgba, shadow_layer)
out_rgba.alpha_composite(logo, dest=(logo_left, logo_top))
final = out_rgba.convert("RGB")
assert final.size == (1536, 1024)
final.save(OUT, optimize=True)
print(f"Saved {OUT} size={final.size}")

# --- Quality checks ---
final_arr = np.array(final).astype(np.float64)
logo_mask_full = Image.new("L", final.size, 0)
logo_mask_full.paste(logo_alpha, (logo_left, logo_top))
dil = logo_mask_full.filter(ImageFilter.MaxFilter(37))
ring = (np.array(dil) > 20) & (np.array(logo_mask_full) < 10)
ring[:, GLASS_X - 5 :] = False
ring_px = final_arr[ring]
distant = final_arr[80:140, 120:280]
ring_rgb = ring_px.reshape(-1, 3).mean(axis=0)
dist_rgb = distant.reshape(-1, 3).mean(axis=0)
ring_lum = ring_px.reshape(-1, 3).mean(axis=1).mean()
dist_lum = distant.reshape(-1, 3).mean(axis=1).mean()
print(f"Wall RING around logo: mean RGB={np.round(ring_rgb,1)} lum={ring_lum:.1f} n={ring_px.reshape(-1,3).shape[0]}")
print(f"Distant wall:          mean RGB={np.round(dist_rgb,1)} lum={dist_lum:.1f}")
print(f"Luminance delta (ring - distant) = {ring_lum - dist_lum:.1f}")
bright_ok = abs(ring_lum - dist_lum) < 25 and ring_lum < dist_lum + 18
print(f"No large bright patch behind logo: {bright_ok}")

fill_c = final_arr[ty0 + 40 : ty1 - 40, tx0 + 40 : tx1 - 40]
print(f"Filled text region mean RGB={np.round(fill_c.mean(axis=(0,1)),1)} lum={fill_c.mean():.1f}")
print(f"Above sample lum={c_above.mean():.1f} Below sample lum={c_below.mean():.1f}")

final.crop((80, 180, 650, 560)).save(TOOL / "_salon_logo_preview.png")
print(f"Preview: {TOOL / '_salon_logo_preview.png'}")
