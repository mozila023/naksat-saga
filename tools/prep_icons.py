"""ตัดไอคอนไอเทมจากชีตไอคอน (ไอคอนวางเป็นแถว บนพื้นเขียว/ชมพู) เป็นไฟล์ 64x64 พื้นใส

ใช้: python3 tools/prep_icons.py <ชีต.png> <ชื่อ1> <ชื่อ2> ... [--out assets/art/items]
    ชื่อเรียงตามตำแหน่งในภาพ: ซ้ายไปขวา แถวบนลงล่าง ได้ไฟล์ item_<ชื่อ>.png
"""
import sys
import numpy as np
from PIL import Image
from scipy import ndimage



def key_out(im):
    """ตัดพื้นหลังด้วยระยะห่างจากสีพื้น (มุมภาพ) — ไม่กินสีม่วง/เขียวในไอคอนที่ใกล้สีพื้น"""
    a = np.asarray(im.convert("RGB")).astype(np.float32)
    bg = a[:8, :8].reshape(-1, 3).mean(axis=0)
    dist = np.sqrt(((a - bg) ** 2).sum(axis=2))
    alpha = np.clip((dist - 45.0) / 45.0, 0.0, 1.0)
    return np.dstack([a, alpha * 255.0]).clip(0, 255).astype(np.uint8)


args = sys.argv[1:]
out_dir = "assets/art/items"
DILATE = 8  # ระยะรวมชิ้นส่วนเล็ก ๆ ของไอคอนเดียวกัน (ไอคอนชิดกันมากให้ลดลงด้วย --dilate)
if "--out" in args:
    i = args.index("--out")
    out_dir = args[i + 1]
    del args[i:i + 2]
if "--dilate" in args:
    i = args.index("--dilate")
    DILATE = int(args[i + 1])
    del args[i:i + 2]
src, names = args[0], args[1:]

rgba = key_out(Image.open(src))
solid = rgba[..., 3] > 128
lab, n = ndimage.label(ndimage.binary_dilation(solid, iterations=DILATE))
boxes = [s for s in ndimage.find_objects(lab) if (s[0].stop - s[0].start) > 30 and (s[1].stop - s[1].start) > 20]
# จัดเป็นแถวตามตำแหน่งกึ่งกลางแนวตั้ง แล้วเรียงซ้ายไปขวาในแต่ละแถว
boxes.sort(key=lambda s: (s[0].start + s[0].stop) / 2)
rows, cur = [], []
for b in boxes:
    cy = (b[0].start + b[0].stop) / 2
    if cur and cy - (cur[-1][0].start + cur[-1][0].stop) / 2 > 60:
        rows.append(cur)
        cur = []
    cur.append(b)
rows.append(cur)
ordered = [b for r in rows for b in sorted(r, key=lambda s: s[1].start)]
print("rows", [len(r) for r in rows])
if len(ordered) != len(names):
    raise SystemExit("found %d icons, expected %d" % (len(ordered), len(names)))
for name, box in zip(names, ordered):
    icon = Image.fromarray(rgba[box], "RGBA")
    icon = icon.crop(icon.getchannel("A").point(lambda v: 255 if v > 40 else 0).getbbox())
    icon.thumbnail((60, 60), Image.LANCZOS)
    canvas = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    canvas.alpha_composite(icon, ((64 - icon.width) // 2, (64 - icon.height) // 2))
    canvas.save(f"{out_dir}/item_{name}.png")
print("icons", len(names))
