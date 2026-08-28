import sys
import subprocess
import os

def install_rembg():
    try:
        import rembg
    except ImportError:
        print("Installing rembg...")
        subprocess.check_call([sys.executable, "-m", "pip", "install", "rembg", "onnxruntime"])

install_rembg()

from rembg import remove
from PIL import Image

def process_image(img_path, out_prefix):
    print(f"Processing {img_path}...")
    img = Image.open(img_path)
    
    # Remove background using rembg
    out = remove(img)
    
    # Split into 6 images horizontally
    w, h = out.size
    item_w = w // 6
    
    os.makedirs("assets/images/generated", exist_ok=True)
    
    for i in range(6):
        box = (i * item_w, 0, (i + 1) * item_w, h)
        item_img = out.crop(box)
        
        # Get bounding box of non-transparent pixels
        bbox = item_img.getbbox()
        if bbox:
            item_img = item_img.crop(bbox)
            
            # Save
            item_img.save(f"assets/images/generated/{out_prefix}_{i+1}.png")
            print(f"Saved {out_prefix}_{i+1}.png")

p1 = r'C:\Users\Ezgi\.gemini\antigravity-ide\brain\3d71e681-7aba-4911-8c9e-82f17edd7e26\.user_uploaded\media_1787815706774.jpg'
p2 = r'C:\Users\Ezgi\.gemini\antigravity-ide\brain\3d71e681-7aba-4911-8c9e-82f17edd7e26\.user_uploaded\media_1787815706801.jpg'

process_image(p1, "raw_clips")
process_image(p2, "raw_soaps")
