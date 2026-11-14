"""ตัดชีตมอนสเตอร์แถวเดียวที่ตัวมีสีเขียวปนอยู่ (เช่น ผีไผ่) — ตัดพื้นด้วยระยะห่างจากสีพื้น แทนการดูค่าเขียว

ใช้: python3 tools/prep_sprite_row.py <ชีต.png> <ชื่อ> <ความสูง> [--flip]
    ได้ assets/art/frames/<ชื่อ>_walk_<0-3>.png (เท้าชิดขอบล่าง กึ่งกลาง) และภาพนิ่ง assets/art/<ชื่อ>.png
"""
import sys
import numpy as np
from PIL import Image
from scipy import ndimage

src, name, height = sys.argv[1], sys.argv[2], int(sys.argv[3])
flip = "--flip" in sys.argv
a = np.asarray(Image.open(src).convert("RGB")).astype(np.float32)
bg = np.median(np.concatenate([a[:10].reshape(-1, 3), a[-10:].reshape(-1, 3)]), axis=0)
dist = np.sqrt(((a - bg) ** 2).sum(axis=2))
alpha = np.clip((dist - 60.0) / 50.0, 0.0, 1.0)
# ลดสีพื้นที่ติดขอบ
edge = (alpha > 0) & (alpha < 1)
rgb = a.copy()
k = alpha[..., None]
rgb = np.where(edge[..., None], (a - bg * (1 - k)) / np.maximum(k, 0.2), a)
# ส่วนโปร่งแสง (หมอก/แสงเรือง) ไม่ควรมีสีพื้นปน
soft = ndimage.binary_dilation(alpha < 0.98, iterations=3)
rgb[..., 1] = np.where(soft, np.minimum(rgb[..., 1], np.maximum(rgb[..., 0], rgb[..., 2])), rgb[..., 1])
rgba = np.dstack([rgb, alpha * 255]).clip(0, 255).astype(np.uint8)
solid = alpha > 0.5
lab, n = ndimage.label(ndimage.binary_dilation(solid, iterations=12))
boxes = [s for s in ndimage.find_objects(lab) if (s[0].stop - s[0].start) * (s[1].stop - s[1].start) > 4000]
boxes.sort(key=lambda s: s[1].start)
assert len(boxes) == 4, len(boxes)
frames = []
for s in boxes:
    im = Image.fromarray(rgba[s], "RGBA")
    m = np.asarray(im)[..., 3] > 40
    lab2, n2 = ndimage.label(m)
    sizes = ndimage.sum(m, lab2, range(1, n2 + 1))
    keep = np.isin(lab2, [i + 1 for i, v in enumerate(sizes) if v > 30])
    arr = np.asarray(im).copy()
    arr[..., 3] = np.where(ndimage.binary_dilation(keep, iterations=2), arr[..., 3], 0)
    im = Image.fromarray(arr, "RGBA")
    im = im.crop(im.getchannel("A").point(lambda v: 255 if v > 40 else 0).getbbox())
    # ครึ่งล่าง (หางผี) ไม่มีสีเขียวจริง: เขียวที่เหลือคือแสงพื้นหลังติดมา
    arr = np.asarray(im).astype(np.float32)
    low = np.zeros(arr.shape[:2], bool)
    low[int(arr.shape[0] * 0.62):] = True
    mx = np.maximum(arr[..., 0], arr[..., 2])
    arr[..., 1] = np.where(low, np.minimum(arr[..., 1], mx + 6), arr[..., 1])
    im = Image.fromarray(arr.clip(0, 255).astype(np.uint8), "RGBA")
    if flip:
        im = im.transpose(Image.FLIP_LEFT_RIGHT)
    frames.append(im)
scale = height / max(f.height for f in frames)
W = int(max(f.width for f in frames) * scale) + 8
H = height + 4
for i, f in enumerate(frames):
    f = f.resize((round(f.width * scale), round(f.height * scale)), Image.LANCZOS)
    c = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    c.alpha_composite(f, ((W - f.width) // 2, H - f.height))
    c.save(f"assets/art/frames/{name}_walk_{i}.png")
    if i == 0:
        c.save(f"assets/art/{name}.png")
print(name, W, H)
