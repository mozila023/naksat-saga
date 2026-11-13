"""ตัดชีตท่าทาง (หลายเฟรมเรียงแนวนอนบนพื้นเขียว/ชมพู) ออกเป็นเฟรมเดี่ยว พื้นใส ขนาดผืนผ้าใบเท่ากัน เท้าอยู่กึ่งกลางล่าง

ใช้: python3 tools/prep_frames.py <โฟลเดอร์ภาพต้นฉบับ> assets/art/frames [ร่าง ...]
    (ไม่ใส่ชื่อร่าง = ทำ normal กับ tiger; ตัวเอกหญิงใช้ชื่อขึ้นต้นด้วย heroine_ เช่น heroine_rat
     อ่าน naksat_heroine_rat_*.png แล้วได้ heroine_rat_*.png)
"""
import sys
import numpy as np
from PIL import Image
from scipy import ndimage

SRC, OUT = sys.argv[1], sys.argv[2]
CANVAS = (360, 300)      # ขนาดผืนผ้าใบของทุกเฟรม (ละเอียด 2 เท่าของขนาดที่แสดง)
STAND_H = 216.0          # ความสูงตัวละครตอนยืน (2 เท่าของ 108 พิกเซลในเกม)

# ชีต -> (ชื่อเฟรมเรียงซ้ายไปขวา, เฟรมที่ใช้วัดความสูงยืน, วิธีจัดกึ่งกลางแนวนอน)
SHEETS = {
    "walk": (["walk_0", "walk_1", "walk_2", "walk_3"], 1, "head"),
    "attack": (["attack_0", "attack_1", "attack_2"], None, "feet"),
    "poses": (["idle_0", "land_0", "jump_0", "fall_0"], 0, "head"),
}


def key_out(im):
    a = np.asarray(im.convert("RGB")).astype(np.float32)
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    corner = a[:8, :8].reshape(-1, 3).mean(axis=0)
    green = corner[1] > corner[0] and corner[1] > corner[2]
    measure = (g - np.maximum(r, b)) if green else (np.minimum(r, b) - g)
    alpha = np.clip((90.0 - measure) / 40.0, 0.0, 1.0)
    near_edge = ndimage.binary_dilation(alpha < 0.5, iterations=4)
    spill = near_edge & (measure > 12)
    if green:
        g = np.where(spill, np.minimum(g, np.maximum(r, b) + 8), g)
    else:
        r = np.where(spill, np.minimum(r, g + 8), r)
        b = np.where(spill, np.minimum(b, g + 8), b)
    return np.dstack([r, g, b, alpha * 255.0]).clip(0, 255).astype(np.uint8)


def split_frames(rgba, count):
    """หาช่วงคอลัมน์ที่มีตัวละคร แล้วรวมช่วงที่ชิดกันจนเหลือเท่าจำนวนเฟรม"""
    solid = rgba[..., 3] > 128
    lab, n = ndimage.label(solid)
    sizes = ndimage.sum(solid, lab, range(1, n + 1))
    keep = np.isin(lab, [i + 1 for i, s in enumerate(sizes) if s > 150])
    cols = keep.any(axis=0)
    runs, start = [], None
    for x, on in enumerate(cols):
        if on and start is None:
            start = x
        if not on and start is not None:
            runs.append([start, x])
            start = None
    if start is not None:
        runs.append([start, len(cols)])
    counts = keep.sum(axis=0)
    while len(runs) < count:  # เฟรมติดกัน (เช่น หางยาวชนเฟรมถัดไป): ผ่าช่วงที่กว้างที่สุดตรงคอลัมน์ที่บางที่สุด
        i = int(np.argmax([r[1] - r[0] for r in runs]))
        x0, x1 = runs[i]
        lo, hi = x0 + (x1 - x0) // 5, x1 - (x1 - x0) // 5
        cut = lo + int(np.argmin(counts[lo:hi]))
        runs[i:i + 1] = [[x0, cut], [cut, x1]]
    while len(runs) > count:  # รวมคู่ที่ช่องว่างแคบที่สุด
        gaps = [runs[i + 1][0] - runs[i][1] for i in range(len(runs) - 1)]
        i = int(np.argmin(gaps))
        runs[i][1] = runs[i + 1][1]
        del runs[i + 1]
    if len(runs) != count:
        raise SystemExit("expected %d frames, found %d" % (count, len(runs)))
    out = []
    for x0, x1 in runs:
        part = rgba[:, x0:x1].copy()
        mask = keep[:, x0:x1]
        # เก็บเฉพาะตัวละครหลัก (ตัดเศษหางของเฟรมข้างเคียงที่ติดมา)
        plab, pn = ndimage.label(mask)
        if pn > 1:
            psizes = ndimage.sum(mask, plab, range(1, pn + 1))
            mask = np.isin(plab, [i + 1 for i, v in enumerate(psizes) if v > psizes.max() * 0.15])
        part[..., 3] = np.where(mask, part[..., 3], 0)
        rows = np.where((part[..., 3] > 128).any(axis=1))[0]
        out.append(part[rows[0]:rows[-1] + 1])
    return out


def anchor_x(frame, mode):
    solid = frame[..., 3] > 128
    h = frame.shape[0]
    band = solid[: int(h * 0.42)] if mode == "head" else solid[int(h * 0.88):]
    xs = np.where(band.any(axis=0))[0]
    return (xs[0] + xs[-1]) * 0.5


# ชีตที่ AI วาดเฟรมเกินมา: {ร่าง: {ชีต: จำนวนเฟรมจริงในภาพ}} (ใช้แค่เฟรมแรก ๆ ตามจำนวนชื่อ)
EXTRA = {"rat": {"attack": 4}}
FORMS = sys.argv[3:] or ["normal", "tiger"]

for form in FORMS:
    scale = None
    for sheet in ["poses", "walk", "attack"]:  # poses ก่อน เพื่อใช้ท่ายืนเป็นตัวกำหนดขนาด
        names, ref, mode = SHEETS[sheet]
        count = max(len(names), EXTRA.get(form, {}).get(sheet, 0))
        src_name = f"naksat_{form}" if form.startswith("heroine_") else f"naksat_hero_{form}"
        frames = split_frames(key_out(Image.open(f"{SRC}/{src_name}_{sheet}.png")), count)[: len(names)]
        if ref is not None:
            sheet_scale = STAND_H / frames[ref].shape[0]
            if sheet == "poses":
                scale = sheet_scale
        else:
            sheet_scale = scale  # ชีตท่าตีไม่มีท่ายืนตรง ใช้สัดส่วนเดียวกับท่ายืน
        for name, fr in zip(names, frames):
            ax = anchor_x(fr, mode)
            im = Image.fromarray(fr, "RGBA")
            im = im.resize((max(1, round(im.width * sheet_scale)), max(1, round(im.height * sheet_scale))), Image.LANCZOS)
            canvas = Image.new("RGBA", CANVAS, (0, 0, 0, 0))
            canvas.alpha_composite(im, (round(CANVAS[0] / 2 - ax * sheet_scale), CANVAS[1] - im.height))
            out_name = form if form.startswith("heroine_") else f"hero_{form}"
            canvas.save(f"{OUT}/{out_name}_{name}.png")
        print(form, sheet, [f.shape[:2] for f in frames], "scale %.3f" % sheet_scale)
