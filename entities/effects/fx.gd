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
	var c := color
	c.a *= 1.0 - p
	match kind:
		"slash":
			var a0 := -1.1 + p * 0.6
			var a1 := 1.1 + p * 0.3
			if dir < 0:
				draw_arc(Vector2.ZERO, size.x * 0.75, PI - a1, PI - a0, 16, c, 14.0 * (1.0 - p) + 3.0)
			else:
				draw_arc(Vector2.ZERO, size.x * 0.75, a0, a1, 16, c, 14.0 * (1.0 - p) + 3.0)
		"claw":
			for i in 3:
				var y := (i - 1) * size.y * 0.28
				var from := Vector2(dir * size.x * 0.15, y - size.y * 0.25)
				var to := Vector2(dir * size.x * (0.5 + p * 0.5), y + size.y * 0.25)
				draw_line(from, to, c, 9.0 * (1.0 - p) + 2.0)
		"ring":
			var r := size.x * (0.25 + 0.75 * p)
			draw_arc(Vector2.ZERO, r, 0, TAU, 40, c, 12.0 * (1.0 - p) + 2.0)
			draw_arc(Vector2.ZERO, r * 0.6, 0, TAU, 32, Color(c.r, c.g, c.b, c.a * 0.5), 6.0)
		"puff":
			for i in 6:
				var ang := i * TAU / 6.0
				draw_circle(Vector2.RIGHT.rotated(ang) * size.x * p, size.y * (1.0 - p * 0.6), c)
		"warn":
			# กรอบเตือนพื้นที่ที่บอสกำลังจะตี (จุดกำเนิดคือมุมซ้ายบน)
			var blink := 0.35 + 0.25 * sin(_t * 30.0)
			draw_rect(Rect2(Vector2.ZERO, size), Color(color.r, color.g, color.b, blink * 0.6))
			draw_rect(Rect2(Vector2.ZERO, size), Color(color.r, color.g, color.b, 0.9), false, 3.0)
