class_name Fx extends Node2D
## เอฟเฟกต์ชั่วคราวทั้งหมดของเกม
##   slash  = รอยฟันรูปเสี้ยวพระจันทร์      claw  = รอยกรงเล็บ 3 เส้น
##   spin   = ใบมีดหมุนรอบตัว              ring  = วงคลื่นกระแทก
##   spark  = ประกายตอนตีโดน                burst = ระเบิดควัน (ศัตรูตาย / เปลี่ยนร่าง)
##   star   = ดาวประกายลอยขึ้น              puff  = ฝุ่น
##   ghost  = เงาตามตัวตอนพุ่ง              pillar = ลำแสงพุ่งขึ้น
##   warn   = กรอบเตือนท่าบอส

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
			# กรอบเตือนพื้นที่ที่บอสกำลังจะตี (จุดกำเนิดคือมุมซ้ายบน)
			var blink := 0.3 + 0.2 * sin(_t * 26.0)
			var r := Rect2(Vector2.ZERO, size)
			Art.rrect(self, r, Color(color.r, color.g, color.b, 0.12 + blink * 0.5), 12.0)
			draw_rect(r.grow(-2.0), Color(color.r, color.g, color.b, 0.95), false, 4.0, true)


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
