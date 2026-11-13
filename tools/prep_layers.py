"""เตรียมภาพฉากหลังแบบแยกชั้น (ให้ฉากมีมิติ) และไอคอนไอเทม

ใช้: python3 tools/prep_layers.py <โฟลเดอร์ภาพต้นฉบับ> assets/art
  naksat_layer_far.png              -> layer_far.png            (ท้องฟ้า+ภูเขา ทึบทั้งภาพ)
  naksat_layer_<แผนที่>_mid.png     -> layer_<แผนที่>_mid.png   (บ้าน/ทุ่งนา ตัดพื้นชมพูออก)
  naksat_layer_<แผนที่>_near.png    -> layer_<แผนที่>_near.png  (ต้นไม้/รั้ว ตัดพื้นชมพูออก)
  naksat_items.png                  -> items/item_<ชื่อ>.png    (ไอคอน 6 ชิ้น)
ทุกชั้นถูกต่อกับภาพกลับด้านของตัวเอง เพื่อให้ต่อซ้ำแนวนอนได้ไม่เห็นรอย
"""
import os
import sys
import numpy as np
from PIL import Image
from scipy import ndimage

SRC, OUT = sys.argv[1], sys.argv[2]
ITEMS = ["coin", "potion", "frog_leg", "mushroom_cap", "pouch", "tiger_fang"]


def key_out(im, lo=110.0, hi=150.0):
    a = np.asarray(im.convert("RGB")).astype(np.float32)
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    corner = a[:8, :8].reshape(-1, 3).mean(axis=0)
    green = corner[1] > corner[0] and corner[1] > corner[2]
    measure = (g - np.maximum(r, b)) if green else (np.minimum(r, b) - g)
    alpha = np.clip((hi - measure) / (hi - lo), 0.0, 1.0)
    near_edge = ndimage.binary_dilation(alpha < 0.5, iterations=3)
    spill = near_edge & (measure > 12)
    if green:
        g = np.where(spill, np.minimum(g, np.maximum(r, b) + 8), g)
    else:
        r = np.where(spill, np.minimum(r, g + 8), r)
        b = np.where(spill, np.minimum(b, g + 8), b)
    return np.dstack([r, g, b, alpha * 255.0]).clip(0, 255).astype(np.uint8)


def mirrored(im):
    pair = Image.new(im.mode, (im.width * 2, im.height))
    pair.paste(im, (0, 0))
    pair.paste(im.transpose(Image.FLIP_LEFT_RIGHT), (im.width, 0))
    return pair


# ชั้นหลังสุด
far = np.asarray(Image.open(f"{SRC}/naksat_layer_far.png").convert("RGB")).astype(np.float32)
top = far[:6].reshape(-1, 3).mean(axis=0)
fade = np.clip(np.arange(far.shape[0]) / 60.0, 0.0, 1.0)[:, None, None]
far = far * fade + top[None, None, :] * (1.0 - fade)
mirrored(Image.fromarray(far.clip(0, 255).astype(np.uint8), "RGB")).save(f"{OUT}/layer_far.png")
print("far sky color", [round(float(v) / 255.0, 3) for v in top])

# ชั้นกลางและชั้นหน้า
for stage in ["village", "field"]:
    for depth in ["mid", "near"]:
        # ชั้นกลางไม่มีสีชมพูในภาพ ตัดพื้นได้เข้มกว่า (กันขอบชมพูหลงเหลือ)
        rgba = key_out(Image.open(f"{SRC}/naksat_layer_{stage}_{depth}.png"), *((60.0, 110.0) if depth == "mid" else (110.0, 150.0)))
        solid = rgba[..., 3] > 128
        lab, n = ndimage.label(solid)
        sizes = ndimage.sum(solid, lab, range(1, n + 1))
        keep = np.isin(lab, [i + 1 for i, s in enumerate(sizes) if s > 60])
        rgba[..., 3] = np.where(keep, rgba[..., 3], 0)
        rows = np.where(keep.any(axis=1))[0]
        cut = rgba[rows[0]:rows[-1] + 1]
        mirrored(Image.fromarray(cut, "RGBA")).save(f"{OUT}/layer_{stage}_{depth}.png")
        print(stage, depth, "rows", rows[0], rows[-1])

# ไอคอนไอเทม
os.makedirs(f"{OUT}/items", exist_ok=True)
rgba = key_out(Image.open(f"{SRC}/naksat_items.png"), 50.0, 90.0)
solid = rgba[..., 3] > 128
lab, n = ndimage.label(ndimage.binary_dilation(solid, iterations=6))
boxes = sorted([s for s in ndimage.find_objects(lab) if (s[0].stop - s[0].start) > 40], key=lambda s: s[1].start)
assert len(boxes) == len(ITEMS), len(boxes)
for name, box in zip(ITEMS, boxes):
    im = Image.fromarray(rgba[box], "RGBA")
    im = im.crop(im.getchannel("A").point(lambda v: 255 if v > 40 else 0).getbbox())
    im.thumbnail((60, 60), Image.LANCZOS)
    canvas = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    canvas.alpha_composite(im, ((64 - im.width) // 2, (64 - im.height) // 2))
    canvas.save(f"{OUT}/items/item_{name}.png")
print("items", len(boxes))
