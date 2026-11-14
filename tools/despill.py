"""ลบสีเขียวที่ติดมากับพื้นหลัง ออกจากภาพที่ไม่มีสีเขียวในตัว (เช่น หมอกม่วงรอบตัวด้วงกว่าง)

ใช้: python3 tools/despill.py <ไฟล์.png> ...
"""
import sys
import numpy as np
from PIL import Image

for path in sys.argv[1:]:
    a = np.asarray(Image.open(path).convert("RGBA")).astype(np.float32)
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    a[..., 1] = np.minimum(g, np.maximum(r, b))
    Image.fromarray(a.clip(0, 255).astype(np.uint8), "RGBA").save(path)
