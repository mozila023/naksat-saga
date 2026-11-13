class_name Stage extends Node2D
## แม่แบบของทุกแผนที่: พื้น, แท่นลอย, ของประกอบฉาก, ประตู, ชาวบ้าน, จุดเกิดมอนสเตอร์
## แผนที่จริงแต่ละอัน (village.gd ฯลฯ) แค่เขียนฟังก์ชัน build() บอกว่าวางอะไรตรงไหน

const GROUND_Y := 600.0

var width := 4000.0
var title := ""
var style := "village"  # village / field / cave
var spawns := {}

var _platforms: Array = []
var _props: Array = []
var _spawners: Array = []
var _t := 0.0


func _ready() -> void:
	build()
	_make_sky()
	_make_bounds()


func build() -> void:
	pass


# ---------- เครื่องมือสำหรับวางของในแผนที่ ----------

func add_bg(kind: String, scroll: float, autoscroll := 0.0) -> void:
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


# ---------- วาดฉาก (ภาพชั่วคราว) ----------

func _view_center_x() -> float:
	if Game.player and is_instance_valid(Game.player):
		return Game.player.camera.get_screen_center_position().x
	return 640.0


func _draw() -> void:
	var cx := _view_center_x()
	var x0 := cx - 1400.0
	var x1 := cx + 1400.0
	_draw_ground(x0, x1)
	for p in _props:
		if p["x"] > x0 - 300.0 and p["x"] < x1 + 300.0:
			_draw_prop(p)
	for r in _platforms:
		if r.end.x > x0 and r.position.x < x1:
			_draw_platform(r)


func _draw_ground(x0: float, x1: float) -> void:
	var w := x1 - x0
	match style:
		"village":
			draw_rect(Rect2(x0, GROUND_Y, w, 66), Color(0.74, 0.69, 0.8))
			var gx := floorf(x0 / 80.0) * 80.0
			while gx < x1:
				draw_line(Vector2(gx, GROUND_Y), Vector2(gx - 12, GROUND_Y + 66), Color(0.64, 0.59, 0.72), 2.0)
				if int(gx / 80.0) % 3 == 0:
					draw_rect(Rect2(gx, GROUND_Y + 30, 46, 4), Color(0.92, 0.9, 0.95))
				draw_rect(Rect2(gx + 2, GROUND_Y + 66, 76, 18), Color(0.82, 0.82, 0.84))
				gx += 80.0
			draw_rect(Rect2(x0, GROUND_Y, w, 4), Color(0.84, 0.8, 0.9))
			draw_rect(Rect2(x0, GROUND_Y + 84, w, 14), Color(0.45, 0.75, 0.3))
			draw_rect(Rect2(x0, GROUND_Y + 98, w, 300), Color(0.45, 0.72, 0.9))
			gx = floorf(x0 / 46.0) * 46.0
			while gx < x1:
				draw_line(Vector2(gx, GROUND_Y + 120), Vector2(gx - 5, GROUND_Y + 104), Color(0.4, 0.75, 0.3), 3.0)
				draw_line(Vector2(gx, GROUND_Y + 120), Vector2(gx + 5, GROUND_Y + 104), Color(0.4, 0.75, 0.3), 3.0)
				gx += 46.0
		"field":
			draw_rect(Rect2(x0, GROUND_Y, w, 400), Color(0.55, 0.4, 0.26))
			draw_rect(Rect2(x0, GROUND_Y, w, 16), Color(0.45, 0.76, 0.3))
			var gx := floorf(x0 / 34.0) * 34.0
			while gx < x1:
				draw_colored_polygon(PackedVector2Array([Vector2(gx, GROUND_Y), Vector2(gx + 7, GROUND_Y - 12 - fmod(gx * 0.37, 8.0)), Vector2(gx + 14, GROUND_Y)]), Color(0.4, 0.72, 0.28))
				draw_circle(Vector2(gx + 20, GROUND_Y + 40 + fmod(gx * 0.61, 50.0)), 4.0, Color(0.48, 0.34, 0.22))
				gx += 34.0
		"cave":
			draw_rect(Rect2(x0, GROUND_Y, w, 400), Color(0.24, 0.2, 0.24))
			draw_rect(Rect2(x0, GROUND_Y, w, 8), Color(0.42, 0.36, 0.4))
			var gx := floorf(x0 / 90.0) * 90.0
			while gx < x1:
				draw_line(Vector2(gx, GROUND_Y + 8), Vector2(gx + 20, GROUND_Y + 60), Color(0.18, 0.15, 0.19), 3.0)
				gx += 90.0


func _draw_platform(r: Rect2) -> void:
	match style:
		"village":
			draw_rect(r.grow(2.0), Color(0.3, 0.2, 0.12))
			draw_rect(r, Color(0.72, 0.5, 0.28))
			draw_rect(Rect2(r.position, Vector2(r.size.x, 5)), Color(0.85, 0.64, 0.38))
			draw_rect(Rect2(r.position.x + 10, r.end.y, 8, 16), Color(0.5, 0.34, 0.2))
			draw_rect(Rect2(r.end.x - 18, r.end.y, 8, 16), Color(0.5, 0.34, 0.2))
		"field":
			draw_rect(r.grow(2.0), Color(0.25, 0.17, 0.1))
			draw_rect(r, Color(0.55, 0.4, 0.26))
			draw_rect(Rect2(r.position, Vector2(r.size.x, 8)), Color(0.45, 0.76, 0.3))
		"cave":
			draw_rect(r.grow(2.0), Color(0.12, 0.1, 0.13))
			draw_rect(r, Color(0.4, 0.35, 0.4))
			draw_rect(Rect2(r.position, Vector2(r.size.x, 5)), Color(0.55, 0.5, 0.55))


func _draw_prop(p: Dictionary) -> void:
	var x: float = p["x"]
	var g := GROUND_Y
	var wood := Color(0.6, 0.4, 0.22)
	var dark := Color(0.3, 0.2, 0.12)
	match p["kind"]:
		"house":
			var roof: Color = p.get("roof", Color(0.85, 0.35, 0.25))
			for sx in [-90.0, -30.0, 30.0, 90.0]:
				draw_rect(Rect2(x + sx - 6, g - 90, 12, 90), dark)
			draw_rect(Rect2(x - 112, g - 220, 224, 134), dark)
			draw_rect(Rect2(x - 108, g - 216, 216, 126), Color(0.95, 0.88, 0.74))
			draw_rect(Rect2(x - 120, g - 96, 240, 10), wood)
			draw_colored_polygon(PackedVector2Array([Vector2(x - 140, g - 214), Vector2(x - 60, g - 300), Vector2(x + 60, g - 300), Vector2(x + 140, g - 214)]), roof)
			draw_rect(Rect2(x - 140, g - 220, 280, 8), roof.darkened(0.25))
			draw_rect(Rect2(x - 70, g - 190, 46, 50), Color(0.5, 0.75, 0.9))
			draw_rect(Rect2(x - 70, g - 190, 46, 50), dark, false, 3.0)
			draw_rect(Rect2(x + 30, g - 196, 40, 106), wood)
			# บันได
			for i in 5:
				draw_rect(Rect2(x + 84 + i * 8, g - 86 + i * 17, 30, 5), wood)
		"banana":
			var sway := sin(_t * 1.5 + x) * 0.05
			draw_rect(Rect2(x - 8, g - 120, 16, 120), Color(0.55, 0.65, 0.3))
			for a in [-2.7, -2.15, -1.57, -1.0, -0.45]:
				var dirv := Vector2.RIGHT.rotated(a + sway)
				var base := Vector2(x, g - 116)
				var tip := base + dirv * 120.0
				var side := dirv.orthogonal() * 22.0
				draw_colored_polygon(PackedVector2Array([base, base + dirv * 50.0 + side, tip, base + dirv * 50.0 - side]), Color(0.3, 0.68, 0.25))
				draw_line(base, tip, Color(0.75, 0.88, 0.4), 3.0)
		"fence":
			var fw: float = p.get("w", 200.0)
			draw_rect(Rect2(x, g - 44, fw, 7), wood)
			draw_rect(Rect2(x, g - 22, fw, 7), wood)
			var fx := x
			while fx < x + fw:
				draw_rect(Rect2(fx, g - 62, 12, 62), Color(0.78, 0.56, 0.3))
				draw_rect(Rect2(fx, g - 62, 12, 62), dark, false, 2.0)
				fx += 30.0
		"pole":
			draw_rect(Rect2(x - 9, g - 520, 18, 520), Color(0.72, 0.68, 0.64))
			draw_rect(Rect2(x - 50, g - 480, 100, 8), Color(0.5, 0.46, 0.44))
			draw_rect(Rect2(x - 16, g - 200, 32, 44), Color(0.7, 0.75, 0.8))
			draw_rect(Rect2(x - 16, g - 200, 32, 44), dark, false, 2.0)
		"sala":
			for sx in [-150.0, -50.0, 50.0, 150.0]:
				draw_rect(Rect2(x + sx - 7, g - 190, 14, 190), Color(0.55, 0.25, 0.15))
			draw_rect(Rect2(x - 170, g - 26, 340, 26), Color(0.7, 0.5, 0.3))
			draw_colored_polygon(PackedVector2Array([Vector2(x - 200, g - 186), Vector2(x - 120, g - 250), Vector2(x + 120, g - 250), Vector2(x + 200, g - 186)]), Color(0.8, 0.3, 0.2))
			draw_colored_polygon(PackedVector2Array([Vector2(x - 130, g - 246), Vector2(x - 60, g - 300), Vector2(x + 60, g - 300), Vector2(x + 130, g - 246)]), Color(0.9, 0.45, 0.2))
			draw_colored_polygon(PackedVector2Array([Vector2(x - 8, g - 300), Vector2(x, g - 340), Vector2(x + 8, g - 300)]), Color(0.95, 0.8, 0.3))
			draw_rect(Rect2(x - 200, g - 192, 400, 8), Color(0.95, 0.8, 0.3))
		"shop":
			draw_rect(Rect2(x - 100, g - 190, 200, 190), dark)
			draw_rect(Rect2(x - 96, g - 186, 192, 186), Color(0.55, 0.36, 0.22))
			draw_rect(Rect2(x - 86, g - 140, 172, 6), wood)
			draw_rect(Rect2(x - 86, g - 84, 172, 6), wood)
			for i in 4:
				draw_rect(Rect2(x - 78 + i * 42, g - 172, 28, 30), Color(0.9, 0.7, 0.35))
				draw_rect(Rect2(x - 78 + i * 42, g - 114, 28, 28), Color(0.85, 0.5, 0.4) if i % 2 == 0 else Color(0.5, 0.7, 0.85))
			draw_colored_polygon(PackedVector2Array([Vector2(x - 120, g - 186), Vector2(x - 100, g - 226), Vector2(x + 100, g - 226), Vector2(x + 120, g - 186)]), Color(0.6, 0.45, 0.8))
			for i in 5:
				draw_circle(Vector2(x - 80 + i * 40, g - 180), 5.0, Color(1.0, 0.9, 0.5))
		"mailbox":
			draw_rect(Rect2(x - 4, g - 60, 8, 60), dark)
			draw_rect(Rect2(x - 22, g - 100, 44, 44), Color(0.85, 0.2, 0.2))
			draw_rect(Rect2(x - 22, g - 100, 44, 44), dark, false, 2.5)
			draw_rect(Rect2(x - 12, g - 86, 24, 14), Color.WHITE)
		"rack":
			draw_rect(Rect2(x - 70, g - 120, 5, 120), Color(0.7, 0.72, 0.76))
			draw_rect(Rect2(x + 65, g - 120, 5, 120), Color(0.7, 0.72, 0.76))
			draw_rect(Rect2(x - 70, g - 122, 140, 5), Color(0.7, 0.72, 0.76))
			draw_rect(Rect2(x - 58, g - 114, 34, 46), Color(0.4, 0.6, 0.95))
			draw_rect(Rect2(x - 16, g - 114, 36, 50), Color.WHITE)
			draw_circle(Vector2(x + 2, g - 90), 8.0, Color(0.95, 0.65, 0.3))
			draw_rect(Rect2(x + 28, g - 114, 30, 60), Color(1.0, 0.7, 0.8))
		"tree":
			draw_rect(Rect2(x - 12, g - 150, 24, 150), Color(0.45, 0.3, 0.18))
			draw_circle(Vector2(x, g - 190), 70.0, Color(0.2, 0.52, 0.25))
			draw_circle(Vector2(x - 50, g - 160), 46.0, Color(0.25, 0.58, 0.28))
			draw_circle(Vector2(x + 52, g - 165), 50.0, Color(0.28, 0.62, 0.3))
			draw_circle(Vector2(x + 10, g - 215), 40.0, Color(0.35, 0.68, 0.33))
		"flower_tree":
			draw_rect(Rect2(x - 10, g - 130, 20, 130), Color(0.45, 0.3, 0.18))
			draw_circle(Vector2(x, g - 170), 62.0, Color(0.3, 0.6, 0.28))
			var rng := RandomNumberGenerator.new()
			rng.seed = int(x)
			for i in 16:
				draw_circle(Vector2(x + rng.randf_range(-55, 55), g - 170 + rng.randf_range(-50, 45)), 8.0, p.get("color", Color(1.0, 0.8, 0.2)))
		"bush":
			draw_circle(Vector2(x - 22, g - 16), 22.0, Color(0.25, 0.6, 0.28))
			draw_circle(Vector2(x + 20, g - 18), 26.0, Color(0.3, 0.66, 0.3))
			draw_circle(Vector2(x, g - 30), 24.0, Color(0.36, 0.7, 0.33))
			for i in 4:
				draw_circle(Vector2(x - 28 + i * 18, g - 24 - (i % 2) * 12), 5.0, p.get("color", Color(1.0, 0.55, 0.75)))
		"sign":
			draw_rect(Rect2(x - 5, g - 70, 10, 70), dark)
			draw_rect(Rect2(x - 92, g - 116, 184, 50), dark)
			draw_rect(Rect2(x - 88, g - 112, 176, 42), Color(0.9, 0.75, 0.5))
		"haystack":
			draw_circle(Vector2(x, g - 60), 56.0, Color(0.8, 0.62, 0.25))
			draw_rect(Rect2(x - 56, g - 60, 112, 60), Color(0.8, 0.62, 0.25))
			draw_circle(Vector2(x, g - 66), 48.0, Color(0.9, 0.75, 0.35))
			draw_rect(Rect2(x - 48, g - 66, 96, 66), Color(0.9, 0.75, 0.35))
		"scarecrow":
			draw_rect(Rect2(x - 4, g - 130, 8, 130), dark)
			draw_rect(Rect2(x - 50, g - 104, 100, 8), dark)
			draw_rect(Rect2(x - 26, g - 108, 52, 56), Color(0.4, 0.5, 0.8))
			draw_circle(Vector2(x, g - 130), 22.0, Color(0.92, 0.82, 0.55))
			draw_colored_polygon(PackedVector2Array([Vector2(x - 34, g - 144), Vector2(x, g - 172), Vector2(x + 34, g - 144)]), Color(0.87, 0.72, 0.4))
			draw_circle(Vector2(x - 7, g - 132), 3.0, Color.BLACK)
			draw_circle(Vector2(x + 7, g - 132), 3.0, Color.BLACK)
		"rock":
			draw_colored_polygon(PackedVector2Array([Vector2(x - 50, g), Vector2(x - 34, g - 44), Vector2(x + 6, g - 62), Vector2(x + 44, g - 30), Vector2(x + 56, g)]), Color(0.45, 0.42, 0.46))
			draw_colored_polygon(PackedVector2Array([Vector2(x - 30, g - 40), Vector2(x + 6, g - 58), Vector2(x + 20, g - 40), Vector2(x - 8, g - 30)]), Color(0.58, 0.55, 0.58))
		"torch":
			draw_rect(Rect2(x - 4, g - 130, 8, 130), dark)
			var f := sin(_t * 12.0 + x) * 4.0
			draw_circle(Vector2(x, g - 140), 60.0, Color(1.0, 0.6, 0.2, 0.12))
			draw_colored_polygon(PackedVector2Array([Vector2(x - 12, g - 130), Vector2(x + f, g - 170 - absf(f)), Vector2(x + 12, g - 130)]), Color(1.0, 0.55, 0.15))
			draw_colored_polygon(PackedVector2Array([Vector2(x - 6, g - 130), Vector2(x - f * 0.5, g - 152), Vector2(x + 6, g - 130)]), Color(1.0, 0.9, 0.4))
		"cave_mouth":
			draw_colored_polygon(PackedVector2Array([Vector2(x - 190, g), Vector2(x - 150, g - 200), Vector2(x - 40, g - 290), Vector2(x + 90, g - 250), Vector2(x + 190, g)]), Color(0.42, 0.4, 0.44))
			draw_colored_polygon(PackedVector2Array([Vector2(x - 90, g), Vector2(x - 70, g - 130), Vector2(x, g - 180), Vector2(x + 70, g - 130), Vector2(x + 90, g)]), Color(0.1, 0.08, 0.1))
			draw_circle(Vector2(x - 26, g - 110), 6.0, Color(1.0, 0.8, 0.2))
			draw_circle(Vector2(x + 26, g - 110), 6.0, Color(1.0, 0.8, 0.2))
