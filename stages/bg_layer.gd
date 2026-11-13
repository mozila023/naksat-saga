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
				var c := Vector2(rng.randf_range(80, TILE - 80), rng.randf_range(40, 230))
				for j in 4:
					draw_circle(c + Vector2(j * 34 - 50, sin(j * 2.0) * 10.0), rng.randf_range(26, 40), Color(1, 1, 1, 0.85))
		"hills":
			_hills(rng, 330.0, 90.0, Color(0.42, 0.66, 0.72))
			_hills(rng, 390.0, 60.0, Color(0.36, 0.62, 0.5))
		"village_mid":
			_rice_bands(350.0)
			for i in 5:
				_far_house(Vector2(100 + i * 256 + rng.randf_range(-40, 40), 350), rng)
			for i in 14:
				_palm(Vector2(rng.randf_range(0, TILE), 352), rng.randf_range(50, 90))
		"field_mid":
			_rice_bands(380.0)
			for i in 10:
				var x := rng.randf_range(0, TILE)
				draw_rect(Rect2(x - 4, 330, 8, 52), Color(0.4, 0.3, 0.2))
				draw_circle(Vector2(x, 318), rng.randf_range(26, 40), Color(0.2, 0.5, 0.28))
				draw_circle(Vector2(x + 18, 330), 22, Color(0.25, 0.56, 0.3))
			for i in 3:
				var hx := rng.randf_range(100, TILE - 100)
				draw_circle(Vector2(hx, 440), 30, Color(0.86, 0.72, 0.35))
				draw_rect(Rect2(hx - 30, 440, 60, 30), Color(0.86, 0.72, 0.35))
		"cave_far":
			draw_rect(Rect2(0, -900, TILE, 1600), Color(0.16, 0.13, 0.18))
			for i in 16:
				var x := rng.randf_range(0, TILE)
				var h := rng.randf_range(80, 260)
				draw_colored_polygon(PackedVector2Array([Vector2(x - 40, -40), Vector2(x + 40, -40), Vector2(x, -40 + h)]), Color(0.22, 0.18, 0.25))
			for i in 10:
				var x := rng.randf_range(0, TILE)
				var h := rng.randf_range(60, 180)
				draw_colored_polygon(PackedVector2Array([Vector2(x - 50, 600), Vector2(x + 50, 600), Vector2(x, 600 - h)]), Color(0.22, 0.18, 0.25))
			for i in 8:
				var c := Vector2(rng.randf_range(0, TILE), rng.randf_range(150, 520))
				draw_colored_polygon(PackedVector2Array([c + Vector2(-8, 0), c + Vector2(0, -22), c + Vector2(8, 0), c + Vector2(0, 10)]), Color(0.95, 0.65, 0.25, 0.5))


func _hills(rng: RandomNumberGenerator, base_y: float, amp: float, color: Color) -> void:
	var pts := PackedVector2Array([Vector2(0, 620)])
	var steps := 16
	var first := base_y - rng.randf() * amp
	for i in steps + 1:
		var y := base_y - rng.randf() * amp
		if i == 0 or i == steps:
			y = first
		pts.append(Vector2(i * TILE / steps, y))
	pts.append(Vector2(TILE, 620))
	draw_colored_polygon(pts, color)


func _rice_bands(top: float) -> void:
	var greens := [Color(0.62, 0.8, 0.3), Color(0.72, 0.86, 0.35), Color(0.55, 0.76, 0.3), Color(0.8, 0.9, 0.42)]
	var y := top
	var h := 10.0
	var i := 0
	while y < 620.0:
		draw_rect(Rect2(0, y, TILE, h + 1.0), greens[i % greens.size()])
		y += h
		h *= 1.22
		i += 1


func _far_house(pos: Vector2, rng: RandomNumberGenerator) -> void:
	var roof := Color(0.85, 0.35, 0.25) if rng.randf() < 0.5 else Color(0.45, 0.5, 0.8)
	draw_rect(Rect2(pos.x - 30, pos.y - 34, 60, 26), Color(0.93, 0.87, 0.75))
	draw_colored_polygon(PackedVector2Array([pos + Vector2(-38, -34), pos + Vector2(0, -56), pos + Vector2(38, -34)]), roof)
	draw_rect(Rect2(pos.x - 26, pos.y - 8, 4, 10), Color(0.45, 0.32, 0.2))
	draw_rect(Rect2(pos.x + 22, pos.y - 8, 4, 10), Color(0.45, 0.32, 0.2))


func _palm(pos: Vector2, h: float) -> void:
	draw_rect(Rect2(pos.x - 2, pos.y - h, 4, h), Color(0.45, 0.35, 0.22))
	for a in [-2.6, -2.0, -1.57, -1.1, -0.5]:
		var tip := pos + Vector2(0, -h) + Vector2.RIGHT.rotated(a) * 26.0
		draw_line(pos + Vector2(0, -h), tip, Color(0.2, 0.55, 0.25), 5.0)
