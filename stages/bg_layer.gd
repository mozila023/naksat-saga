class_name BgLayer extends Node2D
## ฉากหลัง 1 ชั้น (วาดด้วยโค้ดเป็นแผ่นกว้าง 1280 แล้วให้ Parallax2D ต่อซ้ำไปเรื่อย ๆ)

const TILE := 1280.0
var kind := "hills"


func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(kind)
	match kind:
		"clouds":
			for i in 5:
				var c := Vector2(120 + i * 250 + rng.randf_range(-40, 40), rng.randf_range(60, 230))
				var s := rng.randf_range(0.8, 1.25)
				# เงาใต้เมฆ แล้วตามด้วยก้อนขาว
				for part in [[-58, 8, 30], [-22, -10, 42], [22, -4, 38], [58, 10, 28], [0, 14, 40]]:
					Art.circle(self, c + Vector2(part[0], part[1] + 8) * s, part[2] * s, Color(0.78, 0.88, 0.98, 0.9))
				for part in [[-58, 8, 30], [-22, -10, 42], [22, -4, 38], [58, 10, 28], [0, 14, 40]]:
					Art.circle(self, c + Vector2(part[0], part[1]) * s, part[2] * s, Color(1, 1, 1, 0.96))
		"hills":
			_hills(300.0, 110.0, 1.3, Color(0.56, 0.76, 0.86), Color(0.74, 0.9, 0.94))
			_hills(360.0, 80.0, 4.1, Color(0.42, 0.7, 0.66), Color(0.66, 0.86, 0.74))
			_hills(410.0, 50.0, 2.2, Color(0.4, 0.72, 0.48), Color(0.62, 0.84, 0.5))
		"village_mid":
			_rice_bands(352.0)
			for i in 9:
				_far_tree(Vector2(rng.randf_range(0, TILE), 356), rng.randf_range(22, 34))
			for i in 5:
				_far_house(Vector2(110 + i * 256 + rng.randf_range(-40, 40), 354), rng)
			for i in 12:
				_palm(Vector2(rng.randf_range(20, TILE - 20), 356), rng.randf_range(60, 100), rng)
		"field_mid":
			_rice_bands(380.0)
			for i in 12:
				_far_tree(Vector2(rng.randf_range(0, TILE), 384), rng.randf_range(28, 46))
			for i in 4:
				_palm(Vector2(rng.randf_range(20, TILE - 20), 384), rng.randf_range(70, 110), rng)
			for i in 3:
				var hx := 200 + i * 420 + rng.randf_range(-60, 60)
				Art.rrect(self, Rect2(hx - 30, 420, 60, 62), Color(0.93, 0.8, 0.45), 28.0)
				Art.rrect(self, Rect2(hx - 22, 426, 22, 36), Color(1.0, 0.9, 0.6, 0.6), 12.0)
		"cave_far":
			Art.vgrad(self, Rect2(-1, -900, TILE + 2, 1520), Color(0.1, 0.08, 0.14), Color(0.26, 0.2, 0.28))
			for i in 14:
				var x := rng.randf_range(40, TILE - 40)
				var h := rng.randf_range(90, 280)
				var w := rng.randf_range(26, 48)
				Art.leaf(self, Vector2(x, -60), Vector2(x + 6, -60 + h * 0.5), Vector2(x, -60 + h), w, Color(0.2, 0.16, 0.24), Color(0.26, 0.21, 0.3))
			for i in 9:
				var x := rng.randf_range(60, TILE - 60)
				var h := rng.randf_range(70, 190)
				Art.leaf(self, Vector2(x, 610), Vector2(x - 6, 610 - h * 0.5), Vector2(x, 610 - h), rng.randf_range(30, 52), Color(0.22, 0.18, 0.26), Color(0.3, 0.25, 0.34))
			for i in 9:
				var c := Vector2(rng.randf_range(40, TILE - 40), rng.randf_range(140, 520))
				var col := Color(1.0, 0.7, 0.3) if i % 3 != 0 else Color(0.5, 0.9, 1.0)
				Art.glow(self, c, 26.0, Color(col.r, col.g, col.b, 0.35))
				Art.poly(self, PackedVector2Array([c + Vector2(-7, 0), c + Vector2(0, -20), c + Vector2(7, 0), c + Vector2(0, 9)]), Color(col.r, col.g, col.b, 0.9))


## เนินเขาโค้งนุ่ม ไล่สีจากยอด (เข้ม) ลงตีน (จางเหมือนมีหมอก) — ต่อซ้ำกันได้พอดี
func _hills(base_y: float, amp: float, phase: float, top: Color, bottom: Color) -> void:
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	var x := -2.0
	while x <= TILE + 2.0:
		var u := TAU * x / TILE
		var y := base_y - amp * (0.5 + 0.32 * sin(u * 2.0 + phase) + 0.18 * sin(u * 5.0 + phase * 2.3))
		pts.append(Vector2(x, y))
		cols.append(top)
		x += 16.0
	pts.append(Vector2(TILE + 2.0, 620))
	cols.append(bottom)
	pts.append(Vector2(-2.0, 620))
	cols.append(bottom)
	draw_polygon(pts, cols)
	var ridge := pts.slice(0, pts.size() - 2)
	draw_polyline(ridge, top.lightened(0.12), 2.0, true)


func _rice_bands(top: float) -> void:
	var greens := [Color(0.66, 0.84, 0.36), Color(0.78, 0.9, 0.42), Color(0.58, 0.8, 0.34), Color(0.84, 0.93, 0.48)]
	var y := top
	var h := 10.0
	var i := 0
	while y < 620.0:
		var c: Color = greens[i % greens.size()]
		Art.vgrad(self, Rect2(-1, y, TILE + 2, h + 1.0), c.lightened(0.1), c.darkened(0.06))
		draw_line(Vector2(-1, y), Vector2(TILE + 1, y), Color(0.42, 0.68, 0.3, 0.55), 1.5, true)
		y += h
		h *= 1.22
		i += 1


func _far_tree(pos: Vector2, r: float) -> void:
	Art.rrect(self, Rect2(pos.x - 3, pos.y - r, 6, r), Color(0.5, 0.38, 0.26), 2.0)
	Art.circle(self, pos + Vector2(0, -r * 1.3), r, Color(0.3, 0.62, 0.36))
	Art.circle(self, pos + Vector2(-r * 0.5, -r * 1.0), r * 0.7, Color(0.34, 0.66, 0.38))
	Art.circle(self, pos + Vector2(r * 0.5, -r * 1.05), r * 0.75, Color(0.36, 0.68, 0.4))
	Art.circle(self, pos + Vector2(-r * 0.25, -r * 1.6), r * 0.45, Color(0.46, 0.76, 0.44))


func _far_house(pos: Vector2, rng: RandomNumberGenerator) -> void:
	var roof := Color(0.93, 0.45, 0.35) if rng.randf() < 0.5 else Color(0.5, 0.58, 0.9)
	Art.rrect(self, Rect2(pos.x - 27, pos.y - 10, 5, 12), Color(0.5, 0.36, 0.24), 2.0)
	Art.rrect(self, Rect2(pos.x + 22, pos.y - 10, 5, 12), Color(0.5, 0.36, 0.24), 2.0)
	Art.rrect(self, Rect2(pos.x - 32, pos.y - 38, 64, 30), Color(1.0, 0.94, 0.82), 4.0)
	Art.rrect(self, Rect2(pos.x - 8, pos.y - 30, 14, 14), Color(0.6, 0.82, 0.95), 3.0)
	Art.poly(self, PackedVector2Array([pos + Vector2(-42, -36), pos + Vector2(-12, -62), pos + Vector2(12, -62), pos + Vector2(42, -36)]), roof)
	Art.rrect(self, Rect2(pos.x - 44, pos.y - 40, 88, 6), roof.darkened(0.18), 3.0)


func _palm(pos: Vector2, h: float, rng: RandomNumberGenerator) -> void:
	var lean := rng.randf_range(-10, 10)
	var top := pos + Vector2(lean, -h)
	Art.curve(self, Art.bezier(pos, pos + Vector2(lean * 0.2, -h * 0.5), top, 8), Color(0.55, 0.42, 0.28), 5.0)
	for a in [-2.75, -2.2, -1.57, -0.95, -0.4]:
		var tip := top + Vector2.RIGHT.rotated(a) * 34.0 + Vector2(0, 12)
		var ctrl := top + Vector2.RIGHT.rotated(a) * 22.0 + Vector2(0, -12)
		Art.leaf(self, top, ctrl, tip, 5.5, Color(0.28, 0.62, 0.32), Color(0.42, 0.74, 0.4))
	Art.circle(self, top, 4.0, Color(0.5, 0.38, 0.24))
