"""ตัดพื้นหลังสี (เขียว/ชมพู) ออกจากภาพตัวละคร และเตรียมฉากหลังให้ต่อซ้ำได้"""
import sys
import numpy as np
from PIL import Image
from scipy import ndimage

SRC, OUT = sys.argv[1], sys.argv[2]
ONLY = set(sys.argv[3:])  # ใส่ชื่อในเกม (เช่น village2 npc_elder) = ทำเฉพาะตัวนั้น

# ชื่อไฟล์ -> (ชื่อในเกม, ความสูงที่แสดงในเกมเป็นพิกเซล)
CHARS = {
    "naksat_hero_normal": ("hero_normal", 108),
    "naksat_hero_tiger": ("hero_tiger", 108),
    "naksat_npc_chief": ("npc_chief", 108),
    "naksat_npc_auntie": ("npc_auntie", 108),
    "naksat_npc_uncle": ("npc_uncle", 104),
    "naksat_npc_elder": ("npc_elder", 100),
    "naksat_npc_merchant": ("npc_merchant", 108),
    "naksat_frog": ("frog", 62),
    "naksat_mushroom": ("mushroom", 84),
    "naksat_tiger_boss": ("tiger_boss", 160),
}
# ชื่อไฟล์ -> (ชื่อในเกม, แถวที่พื้นเริ่ม)
BGS = {
    "naksat_bg_village": ("village", 444),
    "naksat_bg_field": ("field", 449),
    "naksat_bg_cave": ("cave", 432),
    "naksat_bg_village2": ("village2", 480),
    "naksat_bg_forest": ("forest", 480),
}


def key_out(im):
    a = np.asarray(im.convert("RGB")).astype(np.float32)
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    corner = a[:8, :8].reshape(-1, 3).mean(axis=0)
    if corner[1] > corner[0] and corner[1] > corner[2]:
        measure = g - np.maximum(r, b)          # พื้นเขียว
        green = True
    else:
        measure = np.minimum(r, b) - g          # พื้นชมพู
        green = False
    alpha = np.clip((90.0 - measure) / 40.0, 0.0, 1.0)
    # เก็บเฉพาะก้อนใหญ่ (ตัดเศษจุดเล็ก ๆ ทิ้ง)
    lab, n = ndimage.label(alpha > 0.5)
    if n > 1:
        sizes = ndimage.sum(alpha > 0.5, lab, range(1, n + 1))
        keep = np.isin(lab, [i + 1 for i, s in enumerate(sizes) if s > sizes.max() * 0.02])
        alpha = alpha * ndimage.binary_dilation(keep, iterations=2)
    # ลบสีพื้นที่เลอะขอบ
    near_edge = ndimage.binary_dilation(alpha < 0.5, iterations=4)
    spill = near_edge & (measure > 12)
    if green:
        g = np.where(spill, np.minimum(g, np.maximum(r, b) + 8), g)
    else:
        lim = g + 8
        r = np.where(spill, np.minimum(r, np.maximum(lim, b * 0.0 + lim)), r)
        b = np.where(spill, np.minimum(b, lim), b)
    out = np.dstack([r, g, b, alpha * 255.0]).clip(0, 255).astype(np.uint8)
    return Image.fromarray(out, "RGBA")


for src, (name, h) in CHARS.items():
    if ONLY and name not in ONLY:
        continue
    im = key_out(Image.open(f"{SRC}/{src}.png"))
    im = im.crop(im.getchannel("A").point(lambda v: 255 if v > 40 else 0).getbbox())
    th = h * 2  # เก็บละเอียด 2 เท่าของขนาดที่แสดง ให้คมบนจอใหญ่
    im = im.resize((round(im.width * th / im.height), th), Image.LANCZOS)
    im.save(f"{OUT}/{name}.png")
    print(name, im.size)

for src, (name, gy) in BGS.items():
    if ONLY and name not in ONLY:
        continue
    im = Image.open(f"{SRC}/{src}.png").convert("RGB")
    a = np.asarray(im).astype(np.float32)
    top = a[:6].reshape(-1, 3).mean(axis=0)
    # ไล่ขอบบนของภาพให้กลืนกับสีท้องฟ้า (เผื่อกล้องเลื่อนขึ้น)
    fade = np.clip(np.arange(a.shape[0]) / 70.0, 0.0, 1.0)[:, None, None]
    a = a * fade + top[None, None, :] * (1.0 - fade)
    im = Image.fromarray(a.clip(0, 255).astype(np.uint8), "RGB")
    pair = Image.new("RGB", (im.width * 2, im.height))
    pair.paste(im, (0, 0))
    pair.paste(im.transpose(Image.FLIP_LEFT_RIGHT), (im.width, 0))
    pair.crop((0, 0, pair.width, gy)).save(f"{OUT}/bg_{name}.png")
    pair.crop((0, gy, pair.width, im.height)).save(f"{OUT}/ground_{name}.png")
    print(name, "sky color", [round(float(v) / 255.0, 3) for v in top])
