# เรนเดอร์ภาพตัวอย่างโมเดล .glb (เช็กหน้าตาก่อนส่งเข้า Unity)
import bpy, sys, math
args = sys.argv[sys.argv.index("--")+1:]
src, out = args[0], args[1]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=src)
sc = bpy.context.scene
sc.render.engine = "CYCLES"
sc.cycles.samples = 48
sc.cycles.device = "CPU"
sc.render.resolution_x = 640
sc.render.resolution_y = 640
w = bpy.data.worlds.new("w"); sc.world = w; w.use_nodes = True
w.node_tree.nodes["Background"].inputs[0].default_value = (0.55, 0.7, 0.9, 1)
w.node_tree.nodes["Background"].inputs[1].default_value = 0.6
cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam")); sc.collection.objects.link(cam)
cam.location = (1.6, -2.6, 1.3); 
import mathutils
d = mathutils.Vector((0, 0, 0.8)) - cam.location
cam.rotation_euler = d.to_track_quat('-Z', 'Y').to_euler()
sc.camera = cam
sun = bpy.data.objects.new("sun", bpy.data.lights.new("sun", "SUN")); sc.collection.objects.link(sun)
sun.data.energy = 3.5; sun.rotation_euler = (math.radians(50), math.radians(20), math.radians(30))
sc.render.filepath = out
bpy.ops.render.render(write_still=True)
