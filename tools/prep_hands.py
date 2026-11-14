"""ตัดเฉพาะ "มือ" จากภาพท่าตีของร่างปกติ ไว้วาดทับด้ามอาวุธ (ตัว -> อาวุธ -> มือ ทับบนสุด = เหมือนกำอาวุธจริง)
ใช้: python3 tools/prep_hands.py   (อ่าน assets/art/frames/<hero|heroine>_normal_attack_<n>.png เขียน ..._hand_<n>.png)
ตำแหน่งมือต้องตรงกับ ChibiVisual.GRIPS["normal"] (ชาย) / ["normal_girl"] (หญิง)
"""
import numpy as np
from PIL import Image

GRIPS = {"hero": [(141, 142), (279, 189), (151, 232)], "heroine": [(133, 121), (283, 199), (188, 232)]}
RADIUS = 13
for who in ["hero", "heroine"]:
    for i, (gx, gy) in enumerate(GRIPS[who]):
        src = f"assets/art/frames/{who}_normal_attack_{i}.png"
        im = np.asarray(Image.open(src).convert("RGBA")).copy()
        h, w = im.shape[:2]
        yy, xx = np.mgrid[0:h, 0:w]
        d = np.hypot(xx - gx, yy - gy)
        r, g, b, a = [im[..., k].astype(int) for k in range(4)]
        skin = (r > 170) & (g > 110) & (b > 80) & (r > b + 30)
        outline = (r + g + b < 160)
        keep = (d < RADIUS) & (a > 0) & (skin | outline)
        # ขอบนอกค่อย ๆ จาง
        alpha = np.where(keep, np.clip((RADIUS + 2 - d) / 4.0, 0, 1) * a, 0)
        im[..., 3] = alpha.astype(np.uint8)
        Image.fromarray(im).save(f"assets/art/frames/{who}_normal_hand_{i}.png")
print("ok")
