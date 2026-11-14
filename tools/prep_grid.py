"""ตัดชีตรวมแบบ 3 แถว (แถว 1 = เดิน, แถว 2 = ยืน/ลงพื้น/กระโดด/ตก, แถว 3 = โจมตี 3 ท่า) บนพื้นเขียว
ออกเป็นเฟรมเดี่ยวขนาดเท่ากัน เท้าอยู่กึ่งกลางล่าง พร้อมภาพนิ่ง assets/art/<ชื่อ>.png

ใช้: python3 tools/prep_grid.py <ชีต.png> <ชื่อออก เช่น heroine_rat> [assets/art]
    แถวเดินใช้ได้ 4-6 เฟรม (ใช้ทุกเฟรมที่ AI วาดมา)
"""
import sys
import numpy as np
from PIL import Image
from scipy import ndimage

sys.path.insert(0, __file__.rsplit("/", 1)[0])
from prep_frames import key_out, anchor_x, CANVAS, STAND_H  # noqa: E402

SRC, NAME = sys.argv[1], sys.argv[2]
ART = sys.argv[3] if len(sys.argv) > 3 else "assets/art"

rgba = key_out(Image.open(SRC))
# ลบเส้นพื้นบาง ๆ ที่ AI ชอบวาด (แถวแนวนอนยาวที่หนาไม่เกิน 4 พิกเซล)
solid = rgba[..., 3] > 128
thin = solid & ~ndimage.binary_opening(solid, structure=np.ones((5, 1)))
lines = ndimage.binary_opening(thin, structure=np.ones((1, 60)))
rgba[..., 3] = np.where(lines, 0, rgba[..., 3])
solid = rgba[..., 3] > 128

# เก็บเฉพาะก้อนใหญ่ แล้วจัดกลุ่มเป็นตัวละครแต่ละตัว
lab, n = ndimage.label(ndimage.binary_dilation(solid, iterations=3))
objs = []
for i, sl in enumerate(ndimage.find_objects(lab)):
    m = (lab[sl] == i + 1) & solid[sl]
    if m.sum() < 1500:
        continue
    objs.append((sl, m))
# เรียงเป็นแถวตามตำแหน่งเท้า (ขอบล่าง)
objs.sort(key=lambda o: o[0][0].stop)
rows, cur = [], []
for o in objs:
    if cur and o[0][0].stop - cur[-1][0][0].stop > 60:
        rows.append(cur)
        cur = []
    cur.append(o)
rows.append(cur)
rows = [sorted(r, key=lambda o: o[0][1].start) for r in rows]
print("rows:", [len(r) for r in rows])
if len(rows) != 3 or len(rows[0]) < 4 or len(rows[1]) != 4 or len(rows[2]) < 3:
    raise SystemExit("unexpected layout")


def crop(o):
    sl, m = o
    part = rgba[sl].copy()
    part[..., 3] = np.where(m, part[..., 3], 0)
    return part


walk = [crop(o) for o in rows[0][:6]]
poses = [crop(o) for o in rows[1]]
attack = [crop(o) for o in rows[2][-3:]]
scale = STAND_H / poses[0].shape[0]
sets = [
    (["walk_%d" % i for i in range(len(walk))], walk, "head"),
    (["idle_0", "land_0", "jump_0", "fall_0"], poses, "head"),
    (["attack_0", "attack_1", "attack_2"], attack, "feet"),
]
import glob, os  # noqa: E402
for old in glob.glob(f"{ART}/frames/{NAME}_walk_*.png"):  # ลบเฟรมเดินเก่าที่อาจเกินจำนวนใหม่
    os.remove(old)
for names, frames, mode in sets:
    for name, fr in zip(names, frames):
        ax = anchor_x(fr, mode)
        im = Image.fromarray(fr, "RGBA")
        im = im.resize((round(im.width * scale), round(im.height * scale)), Image.LANCZOS)
        canvas = Image.new("RGBA", CANVAS, (0, 0, 0, 0))
        canvas.alpha_composite(im, (round(CANVAS[0] / 2 - ax * scale), CANVAS[1] - im.height))
        canvas.save(f"{ART}/frames/{NAME}_{name}.png")
# ภาพนิ่ง (ใช้ในหน้าเลือกตัว/วิญญาณ ฯลฯ): ท่ายืน ตัดขอบใส
idle = Image.fromarray(poses[0], "RGBA")
idle = idle.resize((round(idle.width * scale), round(idle.height * scale)), Image.LANCZOS)
idle.crop(idle.getbbox()).save(f"{ART}/{NAME}.png")
print(NAME, "scale %.3f" % scale)
