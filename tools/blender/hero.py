# ปั้นฮีโร่เด็กผู้ชาย (ชุดปกติ) แบบชิ้นส่วนแยก: หัว ผม ลำตัว แขนซ้าย/ขวา ขาซ้าย/ขวา
# แต่ละชิ้นมีจุดหมุนที่ข้อต่อ เพื่อให้ Unity ขยับท่าทางได้ด้วยโค้ด
import bpy, bmesh, math, sys
from mathutils import Vector

out = sys.argv[sys.argv.index("--")+1] if "--" in sys.argv else "/tmp/hero.glb"
bpy.ops.wm.read_factory_settings(use_empty=True)

def mat(name, rgb, rough=0.6, metal=0.0, sss=0.0):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (*rgb, 1)
    b.inputs["Roughness"].default_value = rough
    b.inputs["Metallic"].default_value = metal
    if sss:
        b.inputs["Subsurface Weight"].default_value = sss
    return m

SKIN = mat("skin", (0.93, 0.72, 0.58), 0.55, sss=0.15)
HAIR = mat("hair", (0.05, 0.045, 0.05), 0.4)
SHIRT = mat("shirt", (0.95, 0.95, 0.93), 0.8)
PANTS = mat("pants", (0.12, 0.2, 0.42), 0.85)
SHOE = mat("shoe", (0.35, 0.22, 0.12), 0.5)
EYE = mat("eye", (0.04, 0.03, 0.05), 0.15)
EYEW = mat("eyewhite", (1, 1, 1), 0.2)
SASH = mat("sash", (0.8, 0.15, 0.15), 0.7)

def smooth(o, level=2):
    for p in o.data.polygons: p.use_smooth = True
    mod = o.modifiers.new("sub", "SUBSURF"); mod.levels = level; mod.render_levels = level
    return o

def empty(name, loc, parent=None):
    e = bpy.data.objects.new(name, None)
    bpy.context.collection.objects.link(e)
    e.location = loc
    if parent: e.parent = parent
    return e

def add(prim, name, loc, scale, m, parent=None, **kw):
    getattr(bpy.ops.mesh, prim)(location=loc, **kw)
    o = bpy.context.active_object
    o.name = name
    o.scale = scale
    bpy.ops.object.transform_apply(scale=True)
    o.data.materials.append(m)
    if parent:
        o.parent = parent
        o.matrix_parent_inverse = parent.matrix_world.inverted()
    return o

root = empty("Hero", (0, 0, 0))
# ข้อต่อ (จุดหมุน)
hips = empty("hips", (0, 0, 0.62), root)
torso = empty("torso", (0, 0, 0.62), hips)
head = empty("head", (0, 0, 1.08), torso)
arm_l = empty("arm_l", (0.2, 0, 1.0), torso)
arm_r = empty("arm_r", (-0.2, 0, 1.0), torso)
leg_l = empty("leg_l", (0.09, 0, 0.6), hips)
leg_r = empty("leg_r", (-0.09, 0, 0.6), hips)

# ลำตัว
smooth(add("primitive_cube_add", "body", (0, 0, 0.82), (0.17, 0.12, 0.2), SHIRT, torso))
smooth(add("primitive_cube_add", "belt", (0, 0, 0.64), (0.175, 0.125, 0.04), SASH, torso), 1)
# หัว (โต แบบชิบิ)
smooth(add("primitive_uv_sphere_add", "face", (0, 0, 1.3), (0.26, 0.24, 0.25), SKIN, head, segments=32, ring_count=16), 1)
# ผมยุ่ง ๆ: ครอบหัว + ปอยแหลม
smooth(add("primitive_uv_sphere_add", "hair_cap", (0, 0.03, 1.36), (0.275, 0.26, 0.24), HAIR, head, segments=24, ring_count=12), 1)
import random
random.seed(3)
for i in range(11):
    a = -1.2 + i * 0.24
    x = math.sin(a) * 0.25
    z = 1.5 + math.cos(a) * 0.08 - abs(a) * 0.05
    o = add("primitive_cone_add", f"spike{i}", (x, -0.12 + random.uniform(-0.03, 0.03), z), (0.06, 0.06, 0.12), HAIR, head, vertices=8)
    o.rotation_euler = (math.radians(-35), math.radians(-math.degrees(a) * 0.6), 0)
# หน้าม้า
for i in range(5):
    x = -0.14 + i * 0.07
    o = add("primitive_cone_add", f"bang{i}", (x, -0.21, 1.4), (0.045, 0.03, 0.09), HAIR, head, vertices=8)
    o.rotation_euler = (math.radians(200), 0, math.radians(random.uniform(-15, 15)))
# ตาโต
for s in (1, -1):
    add("primitive_uv_sphere_add", f"eyew{s}", (0.09 * s, -0.215, 1.28), (0.055, 0.02, 0.065), EYEW, head, segments=16, ring_count=8)
    add("primitive_uv_sphere_add", f"eye{s}", (0.09 * s, -0.232, 1.275), (0.038, 0.012, 0.05), EYE, head, segments=16, ring_count=8)
# แขน
for s, j in ((1, arm_l), (-1, arm_r)):
    smooth(add("primitive_cylinder_add", f"sleeve{s}", (0.23 * s, 0, 0.92), (0.06, 0.06, 0.1), SHIRT, j, vertices=12), 1)
    smooth(add("primitive_cylinder_add", f"forearm{s}", (0.24 * s, 0, 0.78), (0.045, 0.045, 0.08), SKIN, j, vertices=12), 1)
    smooth(add("primitive_uv_sphere_add", f"hand{s}", (0.245 * s, 0, 0.68), (0.055, 0.055, 0.055), SKIN, j, segments=12, ring_count=8), 1)
# ขา
for s, j in ((1, leg_l), (-1, leg_r)):
    smooth(add("primitive_cylinder_add", f"thigh{s}", (0.09 * s, 0, 0.45), (0.07, 0.07, 0.15), PANTS, j, vertices=12), 1)
    smooth(add("primitive_cube_add", f"shoe{s}", (0.09 * s, -0.03, 0.06), (0.065, 0.11, 0.05), SHOE, j), 1)
    smooth(add("primitive_cylinder_add", f"shin{s}", (0.09 * s, 0, 0.2), (0.05, 0.05, 0.1), SKIN, j, vertices=12), 1)

bpy.ops.export_scene.gltf(filepath=out, export_format="GLB", export_apply=True)
print("saved", out)
