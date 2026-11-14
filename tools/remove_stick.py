"""ลบไม้ที่ติดมือออกจากภาพท่าตีของร่างปกติ (ตอนนี้อาวุธวาดตามของที่สวม แทนไม้ในภาพ)
ใช้ครั้งเดียวกับภาพเดิม: python3 tools/remove_stick.py (อ่าน/เขียน assets/art/frames ผลออกที่ /tmp/ns)
"""
import numpy as np, cv2
from PIL import Image
# เส้นไม้ (จุดเริ่มที่มือ -> ปลายไม้) ในพิกัดเฟรม 360x300
LINES = {
 'hero': [((136,140),(104,80)), ((283,182),(356,181)), ((148,230),(208,292))],
 'heroine': [((132,120),(86,66)), ((288,196),(360,195)), ((184,234),(266,294))],
}
def seg_dist(p, a, b):
    a=np.array(a,float); b=np.array(b,float); ab=b-a
    t=np.clip(((p-a)@ab)/(ab@ab),0,1)
    proj=a+t[...,None]*ab
    return np.linalg.norm(p-proj,axis=-1), t
for who, lines in LINES.items():
    for i,(a,b) in enumerate(lines):
        path=f'assets/art/frames/{who}_normal_attack_{i}.png'
        im=np.asarray(Image.open(path).convert('RGBA')).copy()
        H,W=im.shape[:2]
        yy,xx=np.mgrid[0:H,0:W]
        d,t=seg_dist(np.dstack([xx,yy]).astype(float),a,b)
        r,g,bl=im[...,0].astype(int),im[...,1].astype(int),im[...,2].astype(int)
        al=im[...,3]
        brown=(r-bl>35)&(r>70)&(r<215)&(g<170)&(r-g>20)
        dark=(r+g+bl<200)
        skin=(r>200)&(g>150)&(bl>120)&(t<0.22)  # ผิวมือ (เฉพาะใกล้ด้ามจับ)
        corridor=(d<13)&(t>0.04)
        mask=corridor&(al>0)&(brown|dark)&~skin
        mask=cv2.dilate(mask.astype(np.uint8),np.ones((3,3),np.uint8))>0
        mask&=corridor
        # ส่วนที่ยื่นออกนอกตัว (รอบ ๆ เป็นพื้นใส) -> ลบเป็นพื้นใส, ส่วนที่ทับตัว -> เติมสีจากรอบ ๆ
        body=(al>0)&~mask
        body_near=cv2.dilate(body.astype(np.uint8),np.ones((7,7),np.uint8))>0
        inside=mask&cv2.erode(body_near.astype(np.uint8),np.ones((5,5),np.uint8)).astype(bool)
        out=im.copy()
        out[mask&~inside,3]=0
        # เส้นขอบจาง ๆ ของไม้ที่เหลือ: ในแนวไม้ เก็บไว้เฉพาะเนื้อตัวจริง (ส่วนที่หนา) กับผิว (มือ)
        core=cv2.morphologyEx(body.astype(np.uint8),cv2.MORPH_OPEN,np.ones((5,5),np.uint8))
        core=cv2.dilate(core,np.ones((3,3),np.uint8)).astype(bool)
        out[corridor&~core&~skin&~inside,3]=0
        rgb=cv2.inpaint(np.ascontiguousarray(im[...,:3]),(inside.astype(np.uint8)*255),3,cv2.INPAINT_TELEA)
        out[inside,:3]=rgb[inside]
        # เศษชิ้นเล็กที่หลุดจากตัว ลบทิ้ง
        n,lab,stats,_=cv2.connectedComponentsWithStats((out[...,3]>0).astype(np.uint8))
        big=np.argmax(stats[1:,cv2.CC_STAT_AREA])+1
        for k in range(1,n):
            if k!=big and stats[k,cv2.CC_STAT_AREA]<400: out[lab==k,3]=0
        Image.fromarray(out).save(f'/tmp/ns/{who}_normal_attack_{i}.png')
        dbg=im.copy(); dbg[mask]=[255,0,0,255]; dbg[inside]=[255,255,0,255]
        Image.fromarray(dbg).save(f'/tmp/ns/dbg_{who}_{i}.png')
print('ok')
