class_name Stage extends Node2D
## แม่แบบของทุกแผนที่: พื้น, แท่นลอย, ของประกอบฉาก, ประตู, ชาวบ้าน, จุดเกิดมอนสเตอร์
## แผนที่จริงแต่ละอัน (village.gd ฯลฯ) แค่เขียนฟังก์ชัน build() บอกว่าวางอะไรตรงไหน

const GROUND_Y := 600.0

# ภาพฉากหลังจริงของแต่ละแบบแผนที่ (ไฟล์ assets/art/bg_<style>.png และ ground_<style>.png)
#   split = แถวในภาพต้นฉบับที่พื้นเริ่ม, feet = แถวที่เท้าตัวละครเหยียบ, sky = สีขอบบนของภาพ
const ART := {
	"village": {"split": 444.0, "feet": 474.0, "sky": Color(0.374, 0.768, 0.971)},
	"field": {"split": 449.0, "feet": 474.0, "sky": Color(0.35, 0.765, 0.971)},
	"cave": {"split": 432.0, "feet": 466.0, "sky": Color(0.142, 0.119, 0.124)},
	"house": {"split": 424.0, "feet": 470.0, "sky": Color(0.362, 0.153, 0.118)},
	"village2": {"split": 480.0, "feet": 500.0, "sky": Color(0.377, 0.502, 0.695)},
	"forest": {"split": 480.0, "feet": 500.0, "sky": Color(0.173, 0.276, 0.29)},
}

var width := 4000.0
var title := ""
var style := "village"  # village / field / cave
var spawns := {}

var _platforms: Array = []
var _props: Array = []
var _spawners: Array = []
var _t := 0.0
var _layered := false
var _road_top := 0.0
var _ground_bottom := 666.0  # ขอบล่างของแถบถนน (ต่ำกว่านี้เติมสีดิน)
var _under_color := Color(0.26, 0.21, 0.2)


func _ready() -> void:
	build()
	if has_art():
		_make_art_background()
	_make_sky()
	_make_bounds()


func build() -> void:
	pass


# ---------- เครื่องมือสำหรับวางของในแผนที่ ----------

## มีภาพฉากหลังจริงสำหรับแผนที่แบบนี้ไหม (ถ้าไม่มีจะวาดด้วยโค้ดแทน)
func has_art() -> bool:
	return ART.has(style) and ResourceLoader.exists("res://assets/art/bg_%s.png" % style)


func _make_art_background() -> void:
	var info: Dictionary = ART[style]
	var s: float = GROUND_Y / info["feet"]
	var bg: Texture2D = load("res://assets/art/bg_%s.png" % style)
	var ground: Texture2D = load("res://assets/art/ground_%s.png" % style)
	var road_top: float = info["split"] * s
	var mid_path := "res://assets/art/layer_%s_mid.png" % style
	var near_path := "res://assets/art/layer_%s_near.png" % style
	if ResourceLoader.exists(mid_path) and ResourceLoader.exists(near_path):
		# ฉากหลังแยกชั้น ให้มีมิติ: ยิ่งอยู่ไกลยิ่งเลื่อนช้า
		#   ภูเขา+ท้องฟ้า (หลังสุด) -> บ้าน/ทุ่งนา -> ต้นไม้/รั้ว -> ถนน (หน้าสุด เลื่อนเท่าตัวละคร)
		var far: Texture2D = load("res://assets/art/layer_far.png")
		var mid: Texture2D = load(mid_path)
		var near: Texture2D = load(near_path)
		_layered = true
		_add_art_layer(far, 0.92, 400.0 - far.get_height() * 0.92, 0.1, -13)
		_add_art_layer(mid, s, road_top + 2.0 - mid.get_height() * s, 0.32, -12)
		# ชั้นต้นไม้/รั้วยืนอยู่บนขอบถนน จึงต้องเลื่อนเท่าถนน (ไม่งั้นโคนจะไถลเหมือนลอย)
		_add_art_layer(near, s, road_top + 8.0 - near.get_height() * s, 1.0, -11)
		_road_top = road_top
	else:
		# ภาพเดียวทั้งฉาก (เช่น ในถ้ำ): วิวเลื่อนช้ากว่าตัวละคร ส่วนพื้นเลื่อนเท่าตัวละคร
		_add_art_layer(bg, s, 0.0, 0.5, -10)
	_add_art_layer(ground, s, road_top - 1.0, 1.0, -9)
	_ground_bottom = road_top - 1.0 + ground.get_height() * s
	_under_color = ground.get_image().get_pixel(8, ground.get_height() - 2)


func _add_art_layer(tex: Texture2D, s: float, y: float, scroll: float, z: int) -> void:
	var par := Parallax2D.new()
	par.scroll_scale = Vector2(scroll, 1.0)
	par.repeat_size = Vector2(tex.get_width() * s, 0)
	par.repeat_times = 4
	par.z_index = z
	add_child(par)
	var sprite := Sprite2D.new()
	sprite.texture = tex
	sprite.centered = false
	sprite.scale = Vector2(s, s)
	sprite.position = Vector2(0, y)
	par.add_child(sprite)


func add_bg(kind: String, scroll: float, autoscroll := 0.0) -> void:
	if has_art():
		return
	var par := Parallax2D.new()
	par.scroll_scale = Vector2(scroll, 1.0)
	par.repeat_size = Vector2(BgLayer.TILE, 0)
	par.repeat_times = 4
	par.autoscroll = Vector2(autoscroll, 0)
	par.z_index = -10
	add_child(par)
	var layer := BgLayer.new()
	layer.kind = kind
	par.add_child(layer)


func add_platform(x: float, y: float, w: float) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 8
	body.collision_mask = 0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(w, 16)
	shape.shape = rect
	shape.one_way_collision = true
	body.position = Vector2(x + w * 0.5, y + 8.0)
	body.add_child(shape)
	add_child(body)
	_platforms.append(Rect2(x, y, w, 22))


func add_prop(kind: String, x: float, extra := {}) -> void:
	if has_art() and not (kind in ["sign", "gate"]):
		return  # ภาพฉากหลังจริงมีบ้าน ต้นไม้ ฯลฯ อยู่แล้ว
	var p := {"kind": kind, "x": x}
	p.merge(extra)
	_props.append(p)


func add_sign(x: float, text: String) -> void:
	add_prop("sign", x)
	var l := Label.new()
	l.text = text
	l.custom_minimum_size = Vector2(170, 0)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 18)
	l.add_theme_color_override("font_color", Color(0.25, 0.15, 0.08))
	l.position = Vector2(x - 85, GROUND_Y - 108)
	add_child(l)


func add_portal(x: float, label: String, target_stage: String, target_spawn: String, lock := Callable(), tint := Color(0.5, 0.85, 1.0)) -> Portal:
	var portal := Portal.new()
	portal.title = label
	portal.target_stage = target_stage
	portal.target_spawn = target_spawn
	portal.lock_check = lock
	portal.tint = tint
	portal.position = Vector2(x, GROUND_Y)
	add_child(portal)
	return portal


func add_npc(x: float, npc_name: String, outfit: Dictionary, on_talk: Callable, mark := Callable()) -> Npc:
	var npc := Npc.new()
	npc.title = npc_name
	npc.outfit = outfit
	npc.on_talk = on_talk
	npc.has_quest_mark = mark
	npc.position = Vector2(x, GROUND_Y)
	add_child(npc)
	return npc


func add_spawner(kind: String, x: float, y := GROUND_Y, roam := 220.0) -> void:
	var s := {"kind": kind, "pos": Vector2(x, y - 2.0), "roam": roam, "node": null, "timer": 0.0}
	_spawners.append(s)
	_spawn(s)


func _spawn(s: Dictionary) -> void:
	var e := Enemy.new()
	e.kind = s["kind"]
	e.roam = s["roam"]
	e.position = s["pos"]
	add_child(e)
	s["node"] = e
	s["timer"] = 6.0


func _process(delta: float) -> void:
	_t += delta
	for s in _spawners:
		if not is_instance_valid(s["node"]):
			s["timer"] -= delta
			if s["timer"] <= 0.0:
				_spawn(s)
	queue_redraw()


# ---------- โครงของแผนที่ ----------

func _make_sky() -> void:
	var layer := CanvasLayer.new()
	layer.layer = -100
	add_child(layer)
	var grad := Gradient.new()
	var art_sky := has_art()
	match style:
		"cave":
			grad.set_color(0, Color(0.08, 0.06, 0.1))
			grad.set_color(1, Color(0.2, 0.15, 0.2))
		"field":
			grad.set_color(0, Color(0.35, 0.65, 0.95))
			grad.set_color(1, Color(0.85, 0.95, 0.9))
		_:
			grad.set_color(0, Color(0.3, 0.68, 0.98))
			grad.set_color(1, Color(0.8, 0.95, 1.0))
	if art_sky:
		var sky: Color = Color(0.359, 0.763, 0.971) if _layered else ART[style]["sky"]
		grad.set_color(0, sky)
		grad.set_color(1, sky)
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill_from = Vector2(0, 0)
	tex.fill_to = Vector2(0, 1)
	tex.width = 8
	tex.height = 128
	var rect := TextureRect.new()
	rect.texture = tex
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(rect)
	if style != "cave" and not art_sky:
		# ดวงอาทิตย์เรืองแสงมุมขวาบน
		var sun_grad := Gradient.new()
		sun_grad.set_color(0, Color(1.0, 0.98, 0.8, 0.95))
		sun_grad.set_color(1, Color(1.0, 0.95, 0.7, 0.0))
		sun_grad.add_point(0.18, Color(1.0, 0.97, 0.75, 0.9))
		sun_grad.add_point(0.24, Color(1.0, 0.95, 0.7, 0.3))
		var sun_tex := GradientTexture2D.new()
		sun_tex.gradient = sun_grad
		sun_tex.fill = GradientTexture2D.FILL_RADIAL
		sun_tex.fill_from = Vector2(0.5, 0.5)
		sun_tex.fill_to = Vector2(1.0, 0.5)
		sun_tex.width = 256
		sun_tex.height = 256
		var sun := TextureRect.new()
		sun.texture = sun_tex
		sun.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		sun.position = Vector2(-470, -110)
		sun.size = Vector2(440, 440)
		sun.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.add_child(sun)


func _make_bounds() -> void:
	_add_wall(Rect2(-400, GROUND_Y, width + 800, 400))
	_add_wall(Rect2(-60, -2000, 60, 3000))
	_add_wall(Rect2(width, -2000, 60, 3000))


func _add_wall(r: Rect2) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = r.size
	shape.shape = rect
	body.position = r.get_center()
	body.add_child(shape)
	add_child(body)


# ---------- วาดฉาก (ภาพชั่วคราว วาดด้วยโค้ด) ----------

func _view_center_x() -> float:
	if Game.player and is_instance_valid(Game.player):
		return Game.player.camera.get_screen_center_position().x
	return 640.0


func _draw() -> void:
	var cx := _view_center_x()
	var x0 := cx - 1400.0
	var x1 := cx + 1400.0
	# ใต้ดิน (เห็นตอนจอแนวตั้ง): เติมสีดินต่อจากแถบถนนลงไป
	Art.vgrad(self, Rect2(x0, _ground_bottom - 1.0, x1 - x0, 300.0), _under_color, _under_color.darkened(0.45))
	draw_rect(Rect2(x0, _ground_bottom + 298.0, x1 - x0, 2000.0), _under_color.darkened(0.45))
	if not has_art():
		_draw_ground(x0, x1)
	elif _layered:
		# เงาจาง ๆ ตรงโคนต้นไม้/รั้วที่ขอบถนน ให้ดูติดพื้น
		Art.vgrad(self, Rect2(x0, _road_top - 10.0, x1 - x0, 12.0), Color(0.1, 0.15, 0.05, 0.0), Color(0.1, 0.15, 0.05, 0.32))
		Art.vgrad(self, Rect2(x0, _road_top + 2.0, x1 - x0, 14.0), Color(0.1, 0.1, 0.05, 0.3), Color(0.1, 0.1, 0.05, 0.0))
	for p in _props:
		if p["x"] > x0 - 300.0 and p["x"] < x1 + 300.0:
			_draw_prop(p)
	for r in _platforms:
		if r.end.x > x0 and r.position.x < x1:
			_draw_platform(r)
	_draw_ambient(x0, x1)


func _draw_ground(x0: float, x1: float) -> void:
	var w := x1 - x0
	var g := GROUND_Y
	match style:
		"village":
			Art.vgrad(self, Rect2(x0, g, w, 66), Color(0.83, 0.79, 0.89), Color(0.72, 0.67, 0.8))
			var gx := floorf(x0 / 80.0) * 80.0
			while gx < x1:
				draw_line(Vector2(gx, g + 2), Vector2(gx - 12, g + 66), Color(0.64, 0.59, 0.74, 0.7), 2.0, true)
				if int(gx / 80.0) % 3 == 0:
					Art.rrect(self, Rect2(gx, g + 30, 46, 5), Color(0.96, 0.94, 0.99, 0.9), 2.5)
				Art.rrect(self, Rect2(gx + 2, g + 66, 76, 19), Color(0.9, 0.9, 0.93), 5.0)
				Art.rrect(self, Rect2(gx + 2, g + 78, 76, 7), Color(0.76, 0.76, 0.82), 3.0)
				gx += 80.0
			draw_rect(Rect2(x0, g, w, 4), Color(0.93, 0.9, 0.97))
			Art.vgrad(self, Rect2(x0, g + 85, w, 15), Color(0.55, 0.84, 0.36), Color(0.4, 0.72, 0.3))
			Art.vgrad(self, Rect2(x0, g + 100, w, 300), Color(0.5, 0.8, 0.95), Color(0.36, 0.62, 0.86))
			gx = floorf(x0 / 46.0) * 46.0
			while gx < x1:
				Art.line(self, Vector2(gx, g + 119), Vector2(gx - 6, g + 104), Color(0.45, 0.8, 0.32), 3.0)
				Art.line(self, Vector2(gx, g + 119), Vector2(gx + 6, g + 104), Color(0.52, 0.86, 0.36), 3.0)
				Art.rrect(self, Rect2(gx + 14, g + 112, 18, 2), Color(1, 1, 1, 0.35), 1.0)
				gx += 46.0
		"field":
			Art.vgrad(self, Rect2(x0, g, w, 400), Color(0.66, 0.48, 0.3), Color(0.45, 0.31, 0.2))
			var gx := floorf(x0 / 34.0) * 34.0
			while gx < x1:
				Art.ellipse(self, Vector2(gx + 20, g + 44 + fmod(gx * 0.61, 50.0)), 6.0, 3.5, Color(0.52, 0.37, 0.24))
				gx += 34.0
			Art.vgrad(self, Rect2(x0, g, w, 18), Color(0.56, 0.86, 0.36), Color(0.4, 0.72, 0.28))
			gx = floorf(x0 / 34.0) * 34.0
			while gx < x1:
				var h := 9.0 + fmod(gx * 0.37, 8.0)
				var sway := sin(_t * 1.6 + gx * 0.05) * 2.0
				Art.leaf(self, Vector2(gx, g + 2), Vector2(gx + 2, g - h * 0.5), Vector2(gx + 4 + sway, g - h), 3.0, Color(0.46, 0.8, 0.3), Color(0.62, 0.9, 0.42))
				Art.leaf(self, Vector2(gx + 9, g + 2), Vector2(gx + 13, g - h * 0.4), Vector2(gx + 17 + sway, g - h * 0.7), 3.0, Color(0.4, 0.74, 0.27), Color(0.56, 0.86, 0.38))
				Art.ellipse(self, Vector2(gx + 17, g + 18), 9.0, 4.0, Color(0.4, 0.72, 0.28))
				gx += 34.0
		"cave":
			Art.vgrad(self, Rect2(x0, g, w, 400), Color(0.33, 0.28, 0.34), Color(0.16, 0.13, 0.18))
			draw_rect(Rect2(x0, g, w, 7), Color(0.5, 0.44, 0.5))
			var gx := floorf(x0 / 90.0) * 90.0
			while gx < x1:
				draw_line(Vector2(gx, g + 9), Vector2(gx + 20, g + 62), Color(0.18, 0.15, 0.2), 3.0, true)
				Art.ellipse(self, Vector2(gx + 50, g + 30), 12.0, 5.0, Color(0.4, 0.35, 0.42))
				gx += 90.0


func _draw_platform(r: Rect2) -> void:
	Art.ellipse(self, Vector2(r.get_center().x, GROUND_Y + 2), r.size.x * 0.42, 7.0, Color(0, 0, 0, 0.1))
	match style:
		"village":
			Art.rrect(self, Rect2(r.position.x + 12, r.end.y - 4, 9, 18), Color(0.5, 0.33, 0.2), 3.0)
			Art.rrect(self, Rect2(r.end.x - 21, r.end.y - 4, 9, 18), Color(0.5, 0.33, 0.2), 3.0)
			Art.box(self, r, Color(0.8, 0.57, 0.33), 7.0)
			Art.rrect(self, Rect2(r.position + Vector2(3, 2), Vector2(r.size.x - 6, 6)), Color(0.93, 0.74, 0.48), 3.0)
			var px := r.position.x + 44.0
			while px < r.end.x - 10.0:
				draw_line(Vector2(px, r.position.y + 2), Vector2(px, r.end.y - 2), Color(0.6, 0.4, 0.22), 2.0, true)
				px += 44.0
		"field":
			Art.box(self, r, Color(0.62, 0.45, 0.29), 9.0)
			Art.rrect(self, Rect2(r.position.x - 2, r.position.y - 2, r.size.x + 4, 12), Color(0.5, 0.82, 0.33), 6.0)
			var px := r.position.x + 8.0
			while px < r.end.x - 8.0:
				Art.ellipse(self, Vector2(px, r.position.y + 9), 9.0, 4.5, Color(0.5, 0.82, 0.33))
				Art.leaf(self, Vector2(px, r.position.y), Vector2(px + 2, r.position.y - 5), Vector2(px + 5, r.position.y - 10), 2.6, Color(0.46, 0.8, 0.3), Color(0.62, 0.9, 0.42))
				px += 22.0
		"cave":
			Art.box(self, r, Color(0.46, 0.41, 0.48), 8.0, 3.0, Color(0.12, 0.1, 0.14))
			Art.rrect(self, Rect2(r.position + Vector2(3, 2), Vector2(r.size.x - 6, 6)), Color(0.62, 0.57, 0.64), 3.0)
		"village2", "forest":
			# แคร่ไม้ไผ่: ไผ่ 2 ลำวางซ้อน มัดเชือกเป็นช่วง ๆ (ในป่ามีมอสเกาะ)
			Art.rrect(self, Rect2(r.position.x + 14, r.end.y - 4, 8, 18), Color(0.42, 0.5, 0.24), 3.0)
			Art.rrect(self, Rect2(r.end.x - 22, r.end.y - 4, 8, 18), Color(0.42, 0.5, 0.24), 3.0)
			Art.rrect(self, Rect2(r.position.x, r.position.y + 9, r.size.x, 10), Color(0.48, 0.6, 0.26), 5.0)
			Art.rrect(self, Rect2(r.position.x - 3, r.position.y, r.size.x + 6, 11), Color(0.62, 0.74, 0.32), 5.5)
			Art.rrect(self, Rect2(r.position.x + 2, r.position.y + 2, r.size.x - 4, 3), Color(0.82, 0.9, 0.5), 1.5)
			var px := r.position.x + 30.0
			while px < r.end.x - 12.0:
				draw_line(Vector2(px, r.position.y), Vector2(px, r.position.y + 19), Color(0.38, 0.46, 0.2), 2.0, true)
				Art.rrect(self, Rect2(px - 4, r.position.y + 3, 8, 13), Color(0.7, 0.55, 0.32), 2.0)
				px += 58.0
			if style == "forest":
				var mx := r.position.x + 18.0
				while mx < r.end.x - 10.0:
					Art.ellipse(self, Vector2(mx, r.position.y + 1), 10.0, 4.0, Color(0.3, 0.52, 0.26, 0.9))
					mx += 71.0


## ผีเสื้อ / หิ่งห้อย ให้ฉากดูมีชีวิต
func _draw_ambient(x0: float, x1: float) -> void:
	var step := 420.0
	var bx := floorf(x0 / step) * step
	while bx < x1:
		var seed_v := bx * 0.013
		var pos := Vector2(bx + 200.0 + sin(_t * 0.7 + seed_v * 5.0) * 90.0, GROUND_Y - 130.0 - fmod(absf(bx) * 0.37, 160.0) + sin(_t * 1.9 + seed_v * 3.0) * 30.0)
		if style in ["cave", "forest", "village2"]:
			var a := 0.5 + 0.5 * sin(_t * 3.0 + seed_v * 9.0)
			Art.glow(self, pos, 14.0, Color(1.0, 0.95, 0.5, a))
			Art.circle(self, pos, 2.5, Color(1.0, 1.0, 0.8, a))
		else:
			var flap := absf(sin(_t * 12.0 + seed_v * 7.0))
			var col := Color(1.0, 0.85, 0.3) if int(absf(bx) / step) % 2 == 0 else Color(1.0, 0.6, 0.8)
			Art.ellipse(self, pos + Vector2(-5.0 * flap - 1.0, -2), 5.0 * flap + 1.0, 6.0, col)
			Art.ellipse(self, pos + Vector2(5.0 * flap + 1.0, -2), 5.0 * flap + 1.0, 6.0, col)
			Art.ellipse(self, pos, 1.4, 5.0, Art.INK)
		bx += step


func _canopy(c: Vector2, r: float, col: Color) -> void:
	# พุ่มไม้ 3 โทน: เงา / สีหลัก / แสง
	Art.blob(self, c, r, r * 0.9, col.darkened(0.16))
	Art.ellipse(self, c + Vector2(-r * 0.12, -r * 0.14), r * 0.84, r * 0.74, col)
	Art.ellipse(self, c + Vector2(-r * 0.3, -r * 0.36), r * 0.44, r * 0.34, col.lightened(0.16))


func _trunk(x: float, top: float, w: float) -> void:
	Art.box(self, Rect2(x - w * 0.5, top, w, GROUND_Y - top + 2.0), Color(0.6, 0.42, 0.27), 5.0)
	Art.rrect(self, Rect2(x - w * 0.5 + 2, top + 4, w * 0.3, GROUND_Y - top - 8.0), Color(0.72, 0.54, 0.36), 3.0)


func _draw_prop(p: Dictionary) -> void:
	var x: float = p["x"]
	var g := GROUND_Y
	var ink := Art.INK
	var wood := Color(0.78, 0.56, 0.34)
	var wood_dark := Color(0.58, 0.39, 0.23)
	match p["kind"]:
		"house":
			var roof: Color = p.get("roof", Color(0.93, 0.42, 0.32))
			Art.ellipse(self, Vector2(x, g + 2), 130.0, 10.0, Color(0, 0, 0, 0.12))
			for sx in [-90.0, -30.0, 30.0, 90.0]:
				Art.box(self, Rect2(x + sx - 6, g - 92, 12, 92), wood_dark, 3.0, 2.5)
			# บันได
			for i in 5:
				Art.box(self, Rect2(x + 86 + i * 8, g - 86 + i * 17, 32, 6), wood, 3.0, 2.0)
			# ตัวบ้าน
			Art.box(self, Rect2(x - 108, g - 216, 216, 126), Color(1.0, 0.94, 0.8), 6.0)
			var py := g - 196.0
			while py < g - 96.0:
				draw_line(Vector2(x - 104, py), Vector2(x + 104, py), Color(0.9, 0.82, 0.66), 2.0, true)
				py += 20.0
			Art.box(self, Rect2(x - 122, g - 98, 244, 11), wood, 4.0, 2.5)
			# หน้าต่าง + กระถางดอกไม้
			Art.box(self, Rect2(x - 74, g - 190, 50, 52), Color(0.62, 0.86, 0.97), 5.0)
			Art.rrect(self, Rect2(x - 70, g - 186, 18, 44), Color(1, 1, 1, 0.35), 3.0)
			draw_line(Vector2(x - 49, g - 190), Vector2(x - 49, g - 138), ink, 2.5, true)
			Art.box(self, Rect2(x - 78, g - 136, 58, 9), wood, 3.0, 2.0)
			for fx in [-66.0, -49.0, -32.0]:
				Art.circle(self, Vector2(x + fx, g - 141), 5.0, Color(1.0, 0.55, 0.7))
				Art.circle(self, Vector2(x + fx, g - 141), 2.0, Color(1.0, 0.9, 0.4))
			# ประตู
			Art.box(self, Rect2(x + 30, g - 190, 42, 92), wood, 5.0)
			Art.circle(self, Vector2(x + 64, g - 142), 3.0, Color(1.0, 0.85, 0.4))
			# หลังคา
			Art.poly(self, PackedVector2Array([Vector2(x - 148, g - 210), Vector2(x - 64, g - 306), Vector2(x + 64, g - 306), Vector2(x + 148, g - 210)]), ink)
			Art.poly(self, PackedVector2Array([Vector2(x - 141, g - 213), Vector2(x - 61, g - 302), Vector2(x + 61, g - 302), Vector2(x + 141, g - 213)]), roof)
			for i in 3:
				var ry := g - 280.0 + i * 24.0
				var half := 80.0 + (ry - (g - 302.0)) * 0.9
				draw_line(Vector2(x - half, ry), Vector2(x + half, ry), roof.darkened(0.16), 3.0, true)
			Art.box(self, Rect2(x - 150, g - 220, 300, 10), roof.darkened(0.22), 5.0, 2.5)
		"banana":
			var sway := sin(_t * 1.4 + x) * 6.0
			Art.ellipse(self, Vector2(x, g + 2), 46.0, 7.0, Color(0, 0, 0, 0.12))
			Art.box(self, Rect2(x - 9, g - 128, 18, 130), Color(0.66, 0.76, 0.4), 7.0)
			Art.rrect(self, Rect2(x - 6, g - 122, 5, 116), Color(0.8, 0.88, 0.55), 2.5)
			var base := Vector2(x, g - 124)
			var leaves := [[-150.0, -40.0], [-110.0, -150.0], [-20.0, -200.0], [100.0, -160.0], [150.0, -50.0]]
			for i in leaves.size():
				var tip := base + Vector2(leaves[i][0] + sway, leaves[i][1])
				var ctrl := base + Vector2(leaves[i][0] * 0.45, leaves[i][1] - 60.0)
				var col := Color(0.36, 0.74, 0.3) if i % 2 == 0 else Color(0.44, 0.8, 0.34)
				Art.leaf(self, base, ctrl, tip, 25.0, ink, ink)
				Art.leaf(self, base, ctrl, tip, 22.0, col, Color(0.78, 0.92, 0.5))
		"fence":
			var fw: float = p.get("w", 200.0)
			Art.box(self, Rect2(x - 4, g - 46, fw + 8, 8), wood_dark, 3.0, 2.0)
			Art.box(self, Rect2(x - 4, g - 24, fw + 8, 8), wood_dark, 3.0, 2.0)
			var fx := x
			while fx < x + fw:
				Art.box(self, Rect2(fx, g - 64, 13, 66), Color(0.9, 0.68, 0.4), 6.0, 2.5)
				Art.rrect(self, Rect2(fx + 2, g - 60, 4, 54), Color(1.0, 0.82, 0.56), 2.0)
				fx += 30.0
		"pole":
			Art.box(self, Rect2(x - 9, g - 520, 18, 522), Color(0.8, 0.77, 0.74), 5.0)
			Art.rrect(self, Rect2(x - 6, g - 516, 5, 510), Color(0.9, 0.88, 0.86), 2.5)
			Art.box(self, Rect2(x - 52, g - 484, 104, 9), Color(0.6, 0.56, 0.54), 4.0, 2.5)
			for sx in [-44.0, 44.0]:
				Art.circle(self, Vector2(x + sx, g - 490), 5.0, Color(0.5, 0.75, 0.85))
			Art.box(self, Rect2(x - 17, g - 204, 34, 46), Color(0.82, 0.87, 0.92), 5.0)
			Art.rrect(self, Rect2(x - 11, g - 196, 22, 14), Color(0.55, 0.8, 0.9), 3.0)
		"sala":
			Art.ellipse(self, Vector2(x, g + 2), 190.0, 12.0, Color(0, 0, 0, 0.12))
			for sx in [-150.0, -50.0, 50.0, 150.0]:
				Art.box(self, Rect2(x + sx - 8, g - 192, 16, 170), Color(0.72, 0.3, 0.22), 4.0)
				Art.rrect(self, Rect2(x + sx - 11, g - 196, 22, 10), Color(1.0, 0.84, 0.36), 3.0)
			Art.box(self, Rect2(x - 174, g - 28, 348, 30), Color(0.84, 0.62, 0.4), 6.0)
			Art.rrect(self, Rect2(x - 170, g - 26, 340, 7), Color(0.95, 0.76, 0.52), 3.0)
			Art.poly(self, PackedVector2Array([Vector2(x - 214, g - 184), Vector2(x - 128, g - 258), Vector2(x + 128, g - 258), Vector2(x + 214, g - 184)]), ink)
			Art.poly(self, PackedVector2Array([Vector2(x - 206, g - 187), Vector2(x - 125, g - 254), Vector2(x + 125, g - 254), Vector2(x + 206, g - 187)]), Color(0.9, 0.36, 0.26))
			Art.poly(self, PackedVector2Array([Vector2(x - 140, g - 250), Vector2(x - 64, g - 310), Vector2(x + 64, g - 310), Vector2(x + 140, g - 250)]), ink)
			Art.poly(self, PackedVector2Array([Vector2(x - 132, g - 253), Vector2(x - 61, g - 306), Vector2(x + 61, g - 306), Vector2(x + 132, g - 253)]), Color(0.98, 0.52, 0.26))
			Art.leaf(self, Vector2(x, g - 304), Vector2(x - 4, g - 330), Vector2(x, g - 356), 7.0, Color(1.0, 0.84, 0.36), Color(1, 0.95, 0.7))
			for s in [-1.0, 1.0]:
				Art.leaf(self, Vector2(x + s * 200, g - 190), Vector2(x + s * 226, g - 196), Vector2(x + s * 236, g - 222), 6.0, Color(1.0, 0.84, 0.36), Color(1, 0.95, 0.7))
			Art.box(self, Rect2(x - 208, g - 194, 416, 10), Color(1.0, 0.84, 0.36), 5.0, 2.5)
		"shop":
			Art.ellipse(self, Vector2(x, g + 2), 120.0, 9.0, Color(0, 0, 0, 0.12))
			Art.box(self, Rect2(x - 96, g - 186, 192, 188), Color(0.72, 0.5, 0.32), 8.0)
			Art.rrect(self, Rect2(x - 86, g - 176, 172, 168), Color(0.5, 0.33, 0.22), 6.0)
			for i in 4:
				Art.box(self, Rect2(x - 78 + i * 42, g - 168, 28, 28), Color(0.98, 0.8, 0.45), 5.0, 2.0)
				Art.box(self, Rect2(x - 78 + i * 42, g - 110, 28, 26), Color(0.98, 0.6, 0.5) if i % 2 == 0 else Color(0.58, 0.8, 0.95), 5.0, 2.0)
				Art.box(self, Rect2(x - 78 + i * 42, g - 52, 28, 26), Color(0.7, 0.88, 0.55) if i % 2 == 0 else Color(0.98, 0.8, 0.45), 5.0, 2.0)
			Art.box(self, Rect2(x - 88, g - 138, 176, 7), wood, 3.0, 2.0)
			Art.box(self, Rect2(x - 88, g - 82, 176, 7), wood, 3.0, 2.0)
			# กันสาดลายทาง
			Art.poly(self, PackedVector2Array([Vector2(x - 126, g - 182), Vector2(x - 104, g - 232), Vector2(x + 104, g - 232), Vector2(x + 126, g - 182)]), ink)
			for i in 6:
				var a0 := -120.0 + i * 40.0
				var b0 := -100.0 + i * 33.4
				var col := Color(0.72, 0.55, 0.92) if i % 2 == 0 else Color(1.0, 0.97, 0.9)
				Art.poly(self, PackedVector2Array([Vector2(x + a0, g - 185), Vector2(x + b0, g - 229), Vector2(x + b0 + 33.4, g - 229), Vector2(x + a0 + 40.0, g - 185)]), col)
				Art.circle(self, Vector2(x + a0 + 20.0, g - 184), 20.0 * 0.5, col)
			for i in 5:
				Art.glow(self, Vector2(x - 80 + i * 40, g - 164), 12.0, Color(1.0, 0.9, 0.5, 0.7))
				Art.circle(self, Vector2(x - 80 + i * 40, g - 164), 4.0, Color(1.0, 0.95, 0.7))
		"mailbox":
			Art.box(self, Rect2(x - 4, g - 62, 8, 64), wood_dark, 3.0, 2.5)
			Art.box(self, Rect2(x - 23, g - 104, 46, 46), Color(0.95, 0.32, 0.3), 9.0)
			Art.rrect(self, Rect2(x - 19, g - 100, 38, 8), Color(1.0, 0.55, 0.5), 4.0)
			Art.box(self, Rect2(x - 13, g - 86, 26, 16), Color.WHITE, 3.0, 2.0)
			draw_polyline(PackedVector2Array([Vector2(x - 13, g - 86), Vector2(x, g - 77), Vector2(x + 13, g - 86)]), ink, 2.0, true)
		"rack":
			var silver := Color(0.8, 0.83, 0.88)
			Art.box(self, Rect2(x - 72, g - 124, 6, 126), silver, 3.0, 2.0)
			Art.box(self, Rect2(x + 66, g - 124, 6, 126), silver, 3.0, 2.0)
			Art.box(self, Rect2(x - 74, g - 128, 148, 6), silver, 3.0, 2.0)
			var wave := sin(_t * 2.0 + x) * 2.0
			Art.box(self, Rect2(x - 58 + wave, g - 118, 34, 46), Color(0.5, 0.7, 1.0), 6.0, 2.5)
			Art.box(self, Rect2(x - 16 + wave, g - 118, 38, 52), Color.WHITE, 6.0, 2.5)
			Art.circle(self, Vector2(x + 3 + wave, g - 94), 9.0, Color(1.0, 0.72, 0.4))
			Art.circle(self, Vector2(x - 3 + wave, g - 102), 3.5, Color(1.0, 0.72, 0.4))
			Art.circle(self, Vector2(x + 9 + wave, g - 102), 3.5, Color(1.0, 0.72, 0.4))
			Art.box(self, Rect2(x + 30 + wave, g - 118, 30, 62), Color(1.0, 0.75, 0.84), 6.0, 2.5)
		"tree":
			Art.ellipse(self, Vector2(x, g + 2), 70.0, 9.0, Color(0, 0, 0, 0.13))
			_trunk(x, g - 150.0, 26.0)
			var green := Color(0.36, 0.72, 0.38)
			_canopy(Vector2(x - 52, g - 160), 48.0, green.darkened(0.08))
			_canopy(Vector2(x + 54, g - 166), 52.0, green.darkened(0.04))
			_canopy(Vector2(x, g - 200), 72.0, green)
		"flower_tree":
			var fcol: Color = p.get("color", Color(1.0, 0.82, 0.25))
			Art.ellipse(self, Vector2(x, g + 2), 60.0, 8.0, Color(0, 0, 0, 0.13))
			_trunk(x, g - 130.0, 22.0)
			_canopy(Vector2(x, g - 176), 68.0, Color(0.4, 0.72, 0.36))
			var rng := RandomNumberGenerator.new()
			rng.seed = int(x)
			for i in 18:
				var fp := Vector2(x + rng.randf_range(-56, 56), g - 176 + rng.randf_range(-50, 46))
				for k in 5:
					Art.circle(self, fp + Vector2.RIGHT.rotated(k * TAU / 5.0) * 5.0, 4.5, fcol)
				Art.circle(self, fp, 3.0, fcol.lightened(0.5))
		"bush":
			var bcol: Color = p.get("color", Color(1.0, 0.6, 0.78))
			Art.ellipse(self, Vector2(x, g + 2), 52.0, 6.0, Color(0, 0, 0, 0.12))
			_canopy(Vector2(x - 24, g - 18), 24.0, Color(0.36, 0.7, 0.36))
			_canopy(Vector2(x + 24, g - 20), 27.0, Color(0.4, 0.74, 0.38))
			_canopy(Vector2(x, g - 30), 28.0, Color(0.45, 0.78, 0.4))
			for i in 5:
				var fp := Vector2(x - 34 + i * 17, g - 28 - (i % 2) * 14)
				for k in 5:
					Art.circle(self, fp + Vector2.RIGHT.rotated(k * TAU / 5.0) * 4.0, 3.6, bcol)
				Art.circle(self, fp, 2.4, Color(1.0, 0.95, 0.6))
		"sign":
			Art.box(self, Rect2(x - 5, g - 72, 10, 74), wood_dark, 3.0, 2.5)
			Art.box(self, Rect2(x - 90, g - 116, 180, 46), Color(0.98, 0.86, 0.62), 9.0)
			Art.rrect(self, Rect2(x - 86, g - 112, 172, 7), Color(1.0, 0.94, 0.78), 3.0)
		"haystack":
			Art.ellipse(self, Vector2(x, g + 2), 66.0, 8.0, Color(0, 0, 0, 0.13))
			Art.box(self, Rect2(x - 54, g - 104, 108, 106), Color(0.95, 0.78, 0.4), 50.0)
			Art.rrect(self, Rect2(x - 40, g - 96, 40, 60), Color(1.0, 0.88, 0.55, 0.6), 24.0)
			for i in 5:
				draw_arc(Vector2(x, g - 20 - i * 16), 50.0 - i * 4.0, 0.5, PI - 0.5, 12, Color(0.82, 0.64, 0.3), 2.0, true)
		"scarecrow":
			Art.box(self, Rect2(x - 4, g - 132, 8, 134), wood_dark, 3.0, 2.5)
			Art.box(self, Rect2(x - 52, g - 108, 104, 8), wood_dark, 3.0, 2.5)
			Art.box(self, Rect2(x - 27, g - 112, 54, 58), Color(0.5, 0.62, 0.92), 9.0)
			Art.box(self, Rect2(x - 14, g - 84, 14, 14), Color(1.0, 0.75, 0.4), 3.0, 2.0)
			Art.blob(self, Vector2(x, g - 134), 22.0, 21.0, Color(1.0, 0.9, 0.66))
			Art.poly(self, PackedVector2Array([Vector2(x - 40, g - 146), Vector2(x - 5, g - 180), Vector2(x + 5, g - 180), Vector2(x + 40, g - 146)]), ink)
			Art.poly(self, PackedVector2Array([Vector2(x - 34, g - 148), Vector2(x - 3, g - 177), Vector2(x + 3, g - 177), Vector2(x + 34, g - 148)]), Color(0.93, 0.8, 0.5))
			Art.circle(self, Vector2(x - 8, g - 134), 3.0, ink)
			Art.circle(self, Vector2(x + 8, g - 134), 3.0, ink)
			draw_arc(Vector2(x, g - 128), 6.0, 0.2, PI - 0.2, 8, ink, 2.0, true)
		"rock":
			Art.ellipse(self, Vector2(x, g + 2), 58.0, 7.0, Color(0, 0, 0, 0.13))
			Art.blob(self, Vector2(x, g - 24), 50.0, 30.0, Color(0.6, 0.58, 0.64))
			Art.rrect(self, Rect2(x - 54, g - 8, 108, 10), Color(0.6, 0.58, 0.64), 3.0)
			Art.ellipse(self, Vector2(x - 14, g - 36), 24.0, 10.0, Color(0.74, 0.72, 0.78))
			Art.blob(self, Vector2(x + 36, g - 12), 20.0, 13.0, Color(0.54, 0.52, 0.58), 2.5)
		"torch":
			var f := sin(_t * 12.0 + x) * 4.0
			Art.glow(self, Vector2(x, g - 150), 130.0, Color(1.0, 0.6, 0.25, 0.3))
			Art.box(self, Rect2(x - 4, g - 132, 8, 134), wood_dark, 3.0, 2.5)
			Art.box(self, Rect2(x - 9, g - 138, 18, 10), Color(0.4, 0.36, 0.4), 4.0, 2.0)
			Art.leaf(self, Vector2(x, g - 134), Vector2(x - 12, g - 156), Vector2(x + f, g - 186 - absf(f)), 13.0, Color(1.0, 0.5, 0.15), Color(1.0, 0.7, 0.3))
			Art.leaf(self, Vector2(x, g - 134), Vector2(x + 6, g - 150), Vector2(x - f * 0.5, g - 166), 8.0, Color(1.0, 0.88, 0.4), Color(1, 1, 0.8))
		"gate":
			# ซุ้มประตูไม้ทรงไทย หน้าบ้านผู้ใหญ่บ้าน
			var red := Color(0.72, 0.2, 0.16)
			var gold := Color(1.0, 0.82, 0.32)
			Art.ellipse(self, Vector2(x, g + 2), 120.0, 10.0, Color(0, 0, 0, 0.18))
			for sx in [-86.0, 86.0]:
				Art.box(self, Rect2(x + sx - 12, g - 230, 24, 232), red, 5.0)
				Art.rrect(self, Rect2(x + sx - 16, g - 236, 32, 12), gold, 4.0)
				Art.rrect(self, Rect2(x + sx - 16, g - 14, 32, 14), gold, 4.0)
			Art.box(self, Rect2(x - 118, g - 246, 236, 18), wood_dark, 6.0)
			Art.poly(self, PackedVector2Array([Vector2(x - 140, g - 244), Vector2(x - 70, g - 300), Vector2(x + 70, g - 300), Vector2(x + 140, g - 244)]), ink)
			Art.poly(self, PackedVector2Array([Vector2(x - 132, g - 247), Vector2(x - 67, g - 296), Vector2(x + 67, g - 296), Vector2(x + 132, g - 247)]), Color(0.9, 0.36, 0.26))
			Art.leaf(self, Vector2(x, g - 294), Vector2(x - 4, g - 318), Vector2(x, g - 342), 7.0, gold, Color(1, 0.95, 0.7))
			for s2 in [-1.0, 1.0]:
				Art.leaf(self, Vector2(x + s2 * 132, g - 248), Vector2(x + s2 * 154, g - 254), Vector2(x + s2 * 162, g - 280), 6.0, gold, Color(1, 0.95, 0.7))
			# โคมแขวน
			for lx in [-60.0, 60.0]:
				draw_line(Vector2(x + lx, g - 228), Vector2(x + lx, g - 206), ink, 2.0, true)
				Art.blob(self, Vector2(x + lx, g - 192), 12.0, 16.0, Color(1.0, 0.45, 0.3), 2.0)
				Art.glow(self, Vector2(x + lx, g - 192), 26.0, Color(1.0, 0.7, 0.3, 0.5))
		"cave_mouth":
			Art.poly(self, PackedVector2Array([Vector2(x - 196, g + 2), Vector2(x - 160, g - 190), Vector2(x - 60, g - 296), Vector2(x + 80, g - 262), Vector2(x + 170, g - 130), Vector2(x + 196, g + 2)]), ink)
			Art.poly(self, PackedVector2Array([Vector2(x - 190, g + 2), Vector2(x - 154, g - 186), Vector2(x - 58, g - 290), Vector2(x + 78, g - 256), Vector2(x + 164, g - 128), Vector2(x + 190, g + 2)]), Color(0.56, 0.54, 0.6))
			Art.ellipse(self, Vector2(x - 70, g - 230), 44.0, 22.0, Color(0.68, 0.66, 0.72))
			Art.ellipse(self, Vector2(x, g - 90), 86.0, 104.0, Color(0.1, 0.07, 0.12))
			draw_rect(Rect2(x - 86, g - 90, 172, 92), Color(0.1, 0.07, 0.12))
			for s in [-1.0, 1.0]:
				Art.glow(self, Vector2(x + s * 26, g - 112), 16.0, Color(1.0, 0.75, 0.2, 0.8))
				Art.ellipse(self, Vector2(x + s * 26, g - 112), 7.0, 5.0, Color(1.0, 0.85, 0.3))
				Art.ellipse(self, Vector2(x + s * 26, g - 112), 2.0, 5.0, Color(0.1, 0.05, 0.05))
			for i in 6:
				var vx := x - 150.0 + i * 60.0
				Art.leaf(self, Vector2(vx, g - 150 - absf(i - 2.5) * -20.0), Vector2(vx + 10, g - 100), Vector2(vx - 6, g - 60), 6.0, Color(0.36, 0.7, 0.36), Color(0.5, 0.82, 0.45))
