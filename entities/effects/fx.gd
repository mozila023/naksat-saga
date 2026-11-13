class_name Fx extends Node2D
## เอฟเฟกต์ชั่วคราว (รอยฟัน, กรงเล็บ, วงคลื่น, ควัน, กรอบเตือนท่าบอส)

var kind := "slash"
var size := Vector2(90, 80)
var color := Color.WHITE
var dir := 1
var life := 0.25
var _t := 0.0


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


func _process(delta: float) -> void:
	_t += delta
	if _t >= life:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var p := clampf(_t / life, 0.0, 1.0)
	var fade := 1.0 - p
	var c := Color(color.r, color.g, color.b, color.a * fade)
	var white := Color(1, 1, 1, 0.9 * fade)
	match kind:
		"slash":
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(dir, 1))
			var r := size.x * 0.72
			var a0 := -1.25 + p * 0.9
			var a1 := 1.15 + p * 0.35
			# เสี้ยวพระจันทร์ซ้อนกัน 3 ชั้นให้ดูนุ่ม
			draw_arc(Vector2.ZERO, r, a0, a1, 24, Color(c.r, c.g, c.b, c.a * 0.35), 22.0 * fade + 4.0, true)
			draw_arc(Vector2.ZERO, r, a0 + 0.15, a1 - 0.1, 24, Color(c.r, c.g, c.b, c.a * 0.7), 12.0 * fade + 3.0, true)
			draw_arc(Vector2.ZERO, r + 2.0, a0 + 0.3, a1 - 0.2, 24, white, 4.0 * fade + 1.0, true)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"claw":
			for i in 3:
				var y := (i - 1) * size.y * 0.28
				var a := Vector2(dir * size.x * 0.12, y - size.y * 0.26)
				var b := Vector2(dir * size.x * (0.55 + p * 0.45), y + size.y * 0.26)
				var ctrl := (a + b) * 0.5 + Vector2(dir * 26.0, -10.0)
				var pts := Art.bezier(a, ctrl, b, 10)
				draw_polyline(pts, Color(c.r, c.g, c.b, c.a * 0.5), 14.0 * fade + 3.0, true)
				draw_polyline(pts, white, 5.0 * fade + 1.0, true)
		"ring":
			var r := size.x * (0.25 + 0.75 * ease(p, 0.4))
			draw_arc(Vector2.ZERO, r, 0, TAU, 48, Color(c.r, c.g, c.b, c.a * 0.35), 26.0 * fade + 2.0, true)
			draw_arc(Vector2.ZERO, r, 0, TAU, 48, c, 10.0 * fade + 2.0, true)
			draw_arc(Vector2.ZERO, r * 0.97, 0, TAU, 48, white, 3.0 * fade + 0.5, true)
			for i in 8:
				var ang := i * TAU / 8.0 + 0.3
				Art.circle(self, Vector2.RIGHT.rotated(ang) * r * 1.08, 5.0 * fade, white)
		"puff":
			for i in 7:
				var ang := i * TAU / 7.0
				Art.circle(self, Vector2.RIGHT.rotated(ang) * size.x * ease(p, 0.4), size.y * (1.0 - p * 0.7) + 2.0, c)
		"warn":
			# กรอบเตือนพื้นที่ที่บอสกำลังจะตี (จุดกำเนิดคือมุมซ้ายบน)
			var blink := 0.3 + 0.2 * sin(_t * 26.0)
			var r := Rect2(Vector2.ZERO, size)
			Art.rrect(self, r, Color(color.r, color.g, color.b, 0.12 + blink * 0.5), 12.0)
			draw_rect(r.grow(-2.0), Color(color.r, color.g, color.b, 0.95), false, 4.0, true)
