"""เตรียมภาพที่เหลือ: ฉากในบ้านผู้ใหญ่บ้าน ภาพปกเกม ไอคอนอุปกรณ์ และภาพนิ่งร่างหนู

ใช้: python3 tools/prep_misc.py <โฟลเดอร์ภาพต้นฉบับ> assets/art
"""
import sys
import numpy as np
from PIL import Image
from scipy import ndimage

SRC, OUT = sys.argv[1], sys.argv[2]
EQUIP = ["wood_sword", "straw_hat", "pha_khao_ma", "sandals", "amulet"]
HOUSE_SPLIT = 424  # แถวในภาพต้นฉบับที่พื้นไม้ด้านหน้าเริ่ม


def key_out(im, lo, hi):
    a = np.asarray(im.convert("RGB")).astype(np.float32)
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    corner = a[:8, :8].reshape(-1, 3).mean(axis=0)
    green = corner[1] > corner[0] and corner[1] > corner[2]
    measure = (g - np.maximum(r, b)) if green else (np.minimum(r, b) - g)
    alpha = np.clip((hi - measure) / (hi - lo), 0.0, 1.0)
    near = ndimage.binary_dilation(alpha < 0.5, iterations=3)
    spill = near & (measure > 12)
    if green:
        g = np.where(spill, np.minimum(g, np.maximum(r, b) + 8), g)
    else:
        r = np.where(spill, np.minimum(r, g + 8), r)
        b = np.where(spill, np.minimum(b, g + 8), b)
    return np.dstack([r, g, b, alpha * 255.0]).clip(0, 255).astype(np.uint8)


# ฉากในบ้าน: ต่อกลับด้านให้ต่อซ้ำได้ แล้วแยกวิวด้านหลังกับพื้น
im = Image.open(f"{SRC}/naksat_bg_house.png").convert("RGB")
a = np.asarray(im).astype(np.float32)
top = a[:6].reshape(-1, 3).mean(axis=0)
fade = np.clip(np.arange(a.shape[0]) / 50.0, 0.0, 1.0)[:, None, None]
a = a * fade + top[None, None, :] * (1.0 - fade)
im = Image.fromarray(a.clip(0, 255).astype(np.uint8), "RGB")
pair = Image.new("RGB", (im.width * 2, im.height))
pair.paste(im, (0, 0))
pair.paste(im.transpose(Image.FLIP_LEFT_RIGHT), (im.width, 0))
pair.crop((0, 0, pair.width, HOUSE_SPLIT)).save(f"{OUT}/bg_house.png")
pair.crop((0, HOUSE_SPLIT, pair.width, im.height)).save(f"{OUT}/ground_house.png")
print("house top color", [round(float(v) / 255.0, 3) for v in top])

# ภาพปก
Image.open(f"{SRC}/naksat_title.png").convert("RGB").resize((1280, 715), Image.LANCZOS).save(f"{OUT}/title.png")

# ไอคอนอุปกรณ์ 5 ชิ้น
rgba = key_out(Image.open(f"{SRC}/naksat_equip.png"), 50.0, 90.0)
solid = rgba[..., 3] > 128
lab, n = ndimage.label(ndimage.binary_dilation(solid, iterations=6))
boxes = sorted([s for s in ndimage.find_objects(lab) if (s[0].stop - s[0].start) > 40], key=lambda s: s[1].start)
assert len(boxes) == len(EQUIP), len(boxes)
for name, box in zip(EQUIP, boxes):
    icon = Image.fromarray(rgba[box], "RGBA")
    icon = icon.crop(icon.getchannel("A").point(lambda v: 255 if v > 40 else 0).getbbox())
    icon.thumbnail((60, 60), Image.LANCZOS)
    canvas = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    canvas.alpha_composite(icon, ((64 - icon.width) // 2, (64 - icon.height) // 2))
    canvas.save(f"{OUT}/items/item_{name}.png")
print("equip icons", len(boxes))

# ภาพนิ่งร่างหนู (ใช้ในหน้าตัวละครและไอคอนร่าง) = ท่ายืนแบบตัดขอบพอดีตัว
idle = Image.open(f"{OUT}/frames/hero_rat_idle_0.png")
idle.crop(idle.getchannel("A").point(lambda v: 255 if v > 40 else 0).getbbox()).save(f"{OUT}/hero_rat.png")
print("hero_rat still", Image.open(f"{OUT}/hero_rat.png").size)
