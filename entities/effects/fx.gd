class_name Fx extends Node2D
## เอฟเฟกต์ชั่วคราวทั้งหมดของเกม
##   slash  = รอยฟันรูปเสี้ยวพระจันทร์      claw  = รอยกรงเล็บ 3 เส้น
##   spin   = ใบมีดหมุนรอบตัว              ring  = วงคลื่นกระแทก
##   spark  = ประกายตอนตีโดน                burst = ระเบิดควัน (ศัตรูตาย / เปลี่ยนร่าง)
##   star   = ดาวประกายลอยขึ้น              puff  = ฝุ่น
##   ghost  = เงาตามตัวตอนพุ่ง              pillar = ลำแสงพุ่งขึ้น
##   warn   = วงเวทเตือนบนพื้นก่อนบอสออกท่า

var kind := "slash"
var size := Vector2(90, 80)
var color := Color.WHITE
var dir := 1
var life := 0.25
var tex: Texture2D  # ใช้กับ ghost
var _t := 0.0
var _seed := randf() * 100.0


static func spawn(parent: Node, pos: Vector2, fx_kind: String, fx_size: Vector2, fx_color: Color, fx_dir := 1, fx_life := 0.25) -> Fx:
	var fx := Fx.new()
	fx.kind = fx_kind
	fx.size = fx_size
	fx.color = fx_color
	fx.dir = fx_dir
	fx.life = fx_life
	fx.z_index = 20
	parent.add_child(fx)
	fx.global_position = pos
	return fx


## เงาตามตัว (ใช้ภาพตัวละครทั้งตัว จางหายไป)
static func ghost(parent: Node, pos: Vector2, texture: Texture2D, tint: Color, fx_dir: int) -> void:
	var fx := spawn(parent, pos, "ghost", Vector2.ZERO, tint, fx_dir, 0.28)
	fx.tex = texture
	fx.z_index = 9


func _process(delta: float) -> void:
	_t += delta
	if _t >= life:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var p := clampf(_t / life, 0.0, 1.0)
	var fade := 1.0 - p
	var c := Color(color.r, color.g, color.b, color.a * fade)
	var white := Color(1, 1, 1, 0.95 * fade)
	match kind:
		"slash":
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(dir, 1))
			var r := size.x * 0.72
			var a0 := -1.35 + ease(p, 0.4) * 1.1
			var a1 := 1.2 + p * 0.3
			# เสี้ยวพระจันทร์: ปลายเรียว กลางหนา ซ้อน 3 ชั้น (เรืองแสง / สีหลัก / แกนขาว)
			_crescent(r, a0, a1, 30.0 * fade + 5.0, Color(c.r, c.g, c.b, c.a * 0.3))
			_crescent(r, a0 + 0.08, a1 - 0.05, 19.0 * fade + 3.0, Color(c.r, c.g, c.b, c.a * 0.85))
			_crescent(r + 2.0, a0 + 0.2, a1 - 0.12, 8.0 * fade + 1.0, white)
			# สะเก็ดแสงที่ปลายรอยฟัน
			for i in 4:
				var a := a1 - i * 0.22
				var d := r + 12.0 + p * (26.0 + i * 9.0)
				Art.circle(self, Vector2(cos(a), sin(a)) * d, 4.0 * fade, white)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"claw":
			for i in 3:
				var y := (i - 1) * size.y * 0.3
				var a := Vector2(dir * size.x * 0.08, y - size.y * 0.3)
				var b := Vector2(dir * size.x * (0.6 + p * 0.45), y + size.y * 0.3)
				var ctrl := (a + b) * 0.5 + Vector2(dir * 34.0, -14.0)
				var pts := Art.bezier(a, ctrl, b, 12)
				_taper(pts, 30.0 * fade + 4.0, Color(c.r, c.g, c.b, c.a * 0.35))
				_taper(pts, 18.0 * fade + 3.0, Color(c.r, c.g, c.b, c.a * 0.9))
				_taper(pts, 7.0 * fade + 1.0, white)
		"spin":
			var r := size.x
			var rot := _t * 22.0 * dir
			for j in 2:
				draw_set_transform(Vector2.ZERO, rot + j * PI, Vector2(1.0, 0.42))
				_crescent(r, -1.5, 1.5, 34.0 * fade + 6.0, Color(c.r, c.g, c.b, c.a * 0.3))
				_crescent(r, -1.3, 1.3, 20.0 * fade + 4.0, Color(c.r, c.g, c.b, c.a * 0.9))
				_crescent(r + 2.0, -1.0, 1.0, 7.0 * fade + 1.5, white)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"ring":
			var r := size.x * (0.2 + 0.8 * ease(p, 0.35))
			draw_arc(Vector2.ZERO, r, 0, TAU, 56, Color(c.r, c.g, c.b, c.a * 0.3), 34.0 * fade + 2.0, true)
			draw_arc(Vector2.ZERO, r, 0, TAU, 56, c, 13.0 * fade + 2.0, true)
			draw_arc(Vector2.ZERO, r * 0.97, 0, TAU, 56, white, 4.0 * fade + 0.5, true)
			for i in 10:
				var ang := i * TAU / 10.0 + _seed
				Art.circle(self, Vector2.RIGHT.rotated(ang) * r * 1.1, 6.0 * fade, white)
		"spark":
			# แฉกแสงตอนตีโดน + ประกายกระเด็น
			var core := size.x * (0.5 + 0.5 * ease(p, 0.3))
			for i in 4:
				var ang := i * PI / 4.0 + _seed
				var v := Vector2.RIGHT.rotated(ang)
				var len := core * (1.0 if i % 2 == 0 else 0.55)
				draw_line(-v * len, v * len, c, 9.0 * fade + 1.0, true)
				draw_line(-v * len * 0.8, v * len * 0.8, white, 4.0 * fade + 0.5, true)
			Art.circle(self, Vector2.ZERO, size.x * 0.32 * fade, white)
			for i in 7:
				var ang := i * TAU / 7.0 + _seed * 3.0
				var d := size.x * (0.5 + ease(p, 0.4) * (0.9 + fmod(_seed * (i + 1), 0.7)))
				Art.circle(self, Vector2.RIGHT.rotated(ang) * d + Vector2(0, p * p * 30.0), 4.5 * fade, c)
		"burst":
			draw_arc(Vector2.ZERO, size.x * ease(p, 0.35), 0, TAU, 40, white, 8.0 * fade, true)
			for i in 9:
				var ang := i * TAU / 9.0 + _seed
				var d := size.x * ease(p, 0.4) * (0.7 + fmod(_seed * (i + 2), 0.5))
				Art.circle(self, Vector2.RIGHT.rotated(ang) * d, size.y * (1.0 - p * 0.75) + 1.0, Color(c.r, c.g, c.b, color.a * fade * 0.9))
				Art.circle(self, Vector2.RIGHT.rotated(ang) * d + Vector2(-3, -3), size.y * 0.5 * fade, white)
		"star":
			for i in 8:
				var x := (fmod(_seed * (i + 3), 1.0) - 0.5) * size.x * 2.0
				var y := -p * size.y * (0.6 + fmod(_seed * (i + 7), 0.8)) + (fmod(_seed * (i + 5), 1.0) - 0.5) * 30.0
				var r := (5.0 + fmod(_seed * (i + 1), 5.0)) * sin(PI * p) + 0.5
				var at := Vector2(x, y)
				draw_colored_polygon(PackedVector2Array([at + Vector2(0, -r * 2.0), at + Vector2(r * 0.5, -r * 0.5), at + Vector2(r * 2.0, 0), at + Vector2(r * 0.5, r * 0.5), at + Vector2(0, r * 2.0), at + Vector2(-r * 0.5, r * 0.5), at + Vector2(-r * 2.0, 0), at + Vector2(-r * 0.5, -r * 0.5)]), Color(color.r, color.g, color.b, 1.0))
				Art.circle(self, at, r * 0.6, Color(1, 1, 1, 1))
		"pillar":
			var w := size.x * (1.0 - p * 0.6)
			Art.vgrad(self, Rect2(-w, -size.y, w * 2.0, size.y), Color(c.r, c.g, c.b, 0.0), Color(c.r, c.g, c.b, 0.7 * fade))
			Art.vgrad(self, Rect2(-w * 0.4, -size.y, w * 0.8, size.y), Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.9 * fade))
			Art.ellipse(self, Vector2.ZERO, size.x * 1.4, size.x * 0.35, Color(1, 1, 1, 0.6 * fade))
		"puff":
			for i in 7:
				var ang := i * TAU / 7.0
				Art.circle(self, Vector2.RIGHT.rotated(ang) * size.x * ease(p, 0.4) + Vector2(0, -p * 8.0), size.y * (1.0 - p * 0.7) + 2.0, c)
		"ghost":
			if tex:
				draw_set_transform(Vector2.ZERO, 0.0, Vector2(dir, 1))
				var w := tex.get_width() * 0.5
				var h := tex.get_height() * 0.5
				draw_texture_rect(tex, Rect2(-w * 0.5, -h + 3.0, w, h), false, Color(color.r, color.g, color.b, 0.6 * fade))
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"warn":
			# วงเวทเตือนบนพื้น ตรงที่บอสกำลังจะตี (จุดกำเนิดคือมุมซ้ายบนของพื้นที่โจมตี)
			# วงรีเรืองแสงบนพื้น + แสงชาร์จที่ขยายจากกลางออกไปจนเต็มตอนบอสตีจริง + ลำแสงลอยขึ้น
			_warn_mark(p)


## วาดวงรี (แบบทึบใช้วงกลมรัศมี 100 แล้วบีบด้วย transform, แบบเส้นขอบคำนวณจุดเอง ให้เส้นหนาเท่ากันทั้งวง)
func _ellipse(center: Vector2, radii: Vector2, col: Color, filled := true, width := 3.0) -> void:
	if radii.x < 1.0 or radii.y < 1.0:
		return
	if filled:
		draw_set_transform(center, 0.0, radii / 100.0)
		draw_circle(Vector2.ZERO, 100.0, col, true, -1.0, true)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		var pts := PackedVector2Array()
		for i in 49:
			var ang := TAU * i / 48.0
			pts.append(center + Vector2(cos(ang) * radii.x, sin(ang) * radii.y))
		draw_polyline(pts, col, width, true)


func _warn_mark(p: float) -> void:
	var appear := clampf(_t / 0.12, 0.0, 1.0)  # ค่อย ๆ โผล่ตอนเริ่ม
	var out := clampf((1.0 - p) / 0.08, 0.0, 1.0)  # จางตอนจบ
	var a := appear * out
	var pulse := 0.5 + 0.5 * sin(_t * 18.0)
	var ground := Vector2(size.x * 0.5, size.y)
	var rad := Vector2(size.x * 0.5, clampf(size.x * 0.09, 16.0, 30.0))
	var col := Color(color.r, color.g, color.b)
	var hot := col.lerp(Color(1, 1, 0.85), 0.55)
	# แสงหมอกจาง ๆ ลอยเหนือพื้นที่ (ไล่จากพื้นขึ้นไป)
	var top := Color(col.r, col.g, col.b, 0.0)
	# (สว่างตรงกลางล่าง จางออกทุกขอบ จะได้ไม่เห็นเป็นกล่องสี่เหลี่ยม)
	var glow := Color(col.r, col.g, col.b, 0.32 * a)
	var cb := Vector2(size.x * 0.5, size.y)
	for tri in [[Vector2(0, size.y), Vector2(0, size.y * 0.25)], [Vector2(0, size.y * 0.25), Vector2(size.x, size.y * 0.25)], [Vector2(size.x, size.y * 0.25), Vector2(size.x, size.y)]]:
		draw_polygon(PackedVector2Array([cb, tri[0], tri[1]]), PackedColorArray([glow, top, top]))
	# วงรีบนพื้น: เงาเรือง 3 ชั้น
	_ellipse(ground, rad * 1.12, Color(col.r, col.g, col.b, 0.16 * a))
	_ellipse(ground, rad, Color(col.r * 0.5, col.g * 0.2, col.b * 0.2, 0.35 * a))
	# แสงชาร์จ ขยายจากกลางจนเต็มวง
	var fill := ease(p, 0.6)
	_ellipse(ground, rad * fill, Color(hot.r, hot.g, hot.b, (0.28 + 0.2 * pulse) * a))
	# ขอบวงเรืองแสง (กระพริบเร็วขึ้นเมื่อใกล้ตี)
	_ellipse(ground, rad, Color(col.r, col.g, col.b, (0.75 + 0.25 * pulse) * a), false, 4.0)
	_ellipse(ground, rad * 0.72, Color(hot.r, hot.g, hot.b, 0.45 * a), false, 2.0)
	# ลายหัวลูกศรชี้เข้ากลาง 2 ข้าง (ขยับเข้าหากลางเรื่อย ๆ)
	for side: float in [-1.0, 1.0]:
		for i in 3:
			var k := fposmod(_t * 1.6 + i / 3.0, 1.0)
			var x := ground.x + side * rad.x * (0.92 - k * 0.6)
			var h := rad.y * 0.55
			var ca := Color(hot.r, hot.g, hot.b, a * (1.0 - k) * 0.9)
			draw_polyline(PackedVector2Array([Vector2(x + side * h * 0.6, ground.y - h), Vector2(x, ground.y), Vector2(x + side * h * 0.6, ground.y + h)]), ca, 3.0, true)
	# ประกายลอยขึ้นจากวง
	for i in 9:
		var r := fposmod(_seed * 7.3 + i * 0.618, 1.0)
		var k := fposmod(_t * 0.9 + r, 1.0)
		var x := ground.x + (r * 2.0 - 1.0) * rad.x * 0.85
		var y := ground.y - k * size.y * 0.8
		var streak := 10.0 + 14.0 * (1.0 - k)
		draw_line(Vector2(x, y), Vector2(x, y + streak), Color(hot.r, hot.g, hot.b, a * (1.0 - k) * 0.8), 3.0, true)
	# เครื่องหมาย ! ในรูปข้าวหลามตัด เหนือกลางวง
	var ic := Vector2(ground.x, size.y * 0.3 - pulse * 4.0)
	var d := 15.0
	draw_colored_polygon(PackedVector2Array([ic + Vector2(0, -d), ic + Vector2(d, 0), ic + Vector2(0, d), ic + Vector2(-d, 0)]), Color(0.18, 0.04, 0.04, 0.85 * a))
	draw_polyline(PackedVector2Array([ic + Vector2(0, -d), ic + Vector2(d, 0), ic + Vector2(0, d), ic + Vector2(-d, 0), ic + Vector2(0, -d)]), Color(hot.r, hot.g, hot.b, a), 3.0, true)
	draw_line(ic + Vector2(0, -8), ic + Vector2(0, 2), Color(1, 1, 1, a), 3.5, true)
	draw_circle(ic + Vector2(0, 6.5), 2.2, Color(1, 1, 1, a), true, -1.0, true)


## เส้นโค้งปลายเรียว (หนาตรงกลาง) ตามจุดที่ให้มา
func _taper(pts: PackedVector2Array, width: float, col: Color) -> void:
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	var n := pts.size()
	for i in n:
		var t := float(i) / (n - 1)
		var d := (pts[mini(i + 1, n - 1)] - pts[maxi(i - 1, 0)]).normalized().orthogonal()
		var half := width * 0.5 * maxf(sin(PI * t), 0.08)
		left.append(pts[i] + d * half)
		right.append(pts[i] - d * half)
	right.reverse()
	left.append_array(right)
	draw_colored_polygon(left, col)


func _crescent(r: float, a0: float, a1: float, width: float, col: Color) -> void:
	if a1 - a0 < 0.15 or width < 1.0:
		return
	var pts := PackedVector2Array()
	for i in 17:
		var a := lerpf(a0, a1, i / 16.0)
		pts.append(Vector2(cos(a), sin(a)) * r)
	_taper(pts, width, col)
