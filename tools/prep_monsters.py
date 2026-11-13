"""ตัดชีตท่าทางของมอนสเตอร์และบอส (เฟรมเรียงเป็นแถวหรือเป็นตาราง บนพื้นเขียว/ชมพู) ออกเป็นเฟรมเดี่ยวพื้นใส

ใช้: python3 tools/prep_monsters.py <โฟลเดอร์ภาพต้นฉบับ> assets/art/frames [ชื่อ ...]
    (ไม่ใส่ชื่อ = ทำทุกตัว, ใส่ เช่น rat_boss = ทำเฉพาะตัวนั้น)
"""
import sys
import numpy as np
from PIL import Image
from scipy import ndimage

SRC, OUT = sys.argv[1], sys.argv[2]

# ไฟล์ -> ชื่อผลลัพธ์, จำนวนแถว, ชื่อเฟรม (ไล่ซ้ายไปขวา บนลงล่าง), เฟรมอ้างอิงขนาด, ความสูงเป้าหมาย (2 เท่าของที่แสดง), ผืนผ้าใบ, ช่วงค่าตัดพื้น
SHEETS = [
    ("naksat_frog_hop", "frog", 1, ["idle_0", "hop_0", "hop_1", "hop_2"], 0, 124.0, (280, 220), (50, 90)),
    ("naksat_mushroom_walk", "mushroom", 1, ["walk_0", "walk_1", "walk_2", "walk_3"], 1, 168.0, (220, 200), (110, 150)),
    ("naksat_tiger_boss_walk", "tiger_boss", 2, ["walk_0", "walk_1", "walk_2", "walk_3"], 0, 300.0, (680, 420), (50, 90)),
    ("naksat_tiger_boss_actions", "tiger_boss", 2, ["crouch_0", "leap_0", "swipe_0", "roar_0"], None, 300.0, (680, 420), (50, 90)),
    ("naksat_rat_boss_walk", "rat_boss", 2, ["walk_0", "walk_1", "walk_2", "walk_3"], 0, 150.0, (560, 300), (50, 90)),
    ("naksat_rat_boss_actions", "rat_boss", 2, ["crouch_0", "leap_0", "swipe_0", "roar_0"], None, 150.0, (560, 300), (50, 90)),
]
ONLY = set(sys.argv[3:])


# เฟรมที่ AI วาดหันผิดด้าน (ต้องหันซ้ายเหมือนเฟรมอื่น) ให้กลับด้าน
FLIP = {("frog", "hop_1")}


def key_out(im, lo, hi):
    a = np.asarray(im.convert("RGB")).astype(np.float32)
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    corner = a[:8, :8].reshape(-1, 3).mean(axis=0)
    green = corner[1] > corner[0] and corner[1] > corner[2]
    measure = (g - np.maximum(r, b)) if green else (np.minimum(r, b) - g)
    alpha = np.clip((hi - measure) / (hi - lo), 0.0, 1.0)
    near_edge = ndimage.binary_dilation(alpha < 0.5, iterations=4)
    spill = near_edge & (measure > 12)
    if green:
        g = np.where(spill, np.minimum(g, np.maximum(r, b) + 8), g)
    else:
        r = np.where(spill, np.minimum(r, g + 8), r)
        b = np.where(spill, np.minimum(b, g + 8), b)
    return np.dstack([r, g, b, alpha * 255.0]).clip(0, 255).astype(np.uint8)


def runs_of(mask, count):
    runs, start = [], None
    for i, on in enumerate(mask):
        if on and start is None:
            start = i
        if not on and start is not None:
            runs.append([start, i])
            start = None
    if start is not None:
        runs.append([start, len(mask)])
    while len(runs) > count:
        gaps = [runs[i + 1][0] - runs[i][1] for i in range(len(runs) - 1)]
        i = int(np.argmin(gaps))
        runs[i][1] = runs[i + 1][1]
        del runs[i + 1]
    if len(runs) != count:
        raise SystemExit("expected %d, found %d" % (count, len(runs)))
    return runs


def split(rgba, rows, total):
    solid = rgba[..., 3] > 128
    lab, n = ndimage.label(solid)
    sizes = ndimage.sum(solid, lab, range(1, n + 1))
    keep = np.isin(lab, [i + 1 for i, s in enumerate(sizes) if s > 150])
    out = []
    for y0, y1 in runs_of(keep.any(axis=1), rows):
        band = keep[y0:y1]
        for x0, x1 in runs_of(band.any(axis=0), total // rows):
            part = rgba[y0:y1, x0:x1].copy()
            part[..., 3] = np.where(band[:, x0:x1], part[..., 3], 0)
            ys = np.where((part[..., 3] > 128).any(axis=1))[0]
            out.append(part[ys[0]:ys[-1] + 1])
    return out


scales = {}
for src, name, rows, names, ref, target_h, canvas_size, (lo, hi) in SHEETS:
    if ONLY and name not in ONLY:
        continue
    frames = split(key_out(Image.open(f"{SRC}/{src}.png"), lo, hi), rows, len(names))
    if ref is not None:
        scales[name] = target_h / frames[ref].shape[0]
    s = scales[name]
    for fname, fr in zip(names, frames):
        im = Image.fromarray(fr, "RGBA")
        if (name, fname) in FLIP:
            im = im.transpose(Image.FLIP_LEFT_RIGHT)
        im = im.resize((max(1, round(im.width * s)), max(1, round(im.height * s))), Image.LANCZOS)
        canvas = Image.new("RGBA", canvas_size, (0, 0, 0, 0))
        canvas.alpha_composite(im, ((canvas_size[0] - im.width) // 2, canvas_size[1] - im.height))
        canvas.save(f"{OUT}/{name}_{fname}.png")
    print(name, [f.shape[:2] for f in frames], "scale %.3f" % s)
