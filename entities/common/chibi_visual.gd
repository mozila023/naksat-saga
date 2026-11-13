class_name ChibiVisual extends Node2D
## ภาพตัวละครชิบิแบบวาดด้วยโค้ด (ภาพชั่วคราว รอเปลี่ยนเป็นภาพจริง)
## ทุกร่างใช้โครงตัวเดียวกัน ขนาดเท่ากัน เปลี่ยนแค่ชุด (outfit)

var outfit := {}
var moving := false
var in_air := false
var swing := -1.0  # ความคืบหน้าท่าตี 0..1 (ติดลบ = ไม่ได้ตี)
var _t := 0.0


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var skin: Color = outfit.get("skin", Color(0.98, 0.83, 0.68))
	var shirt: Color = outfit.get("shirt", Color.WHITE)
	var pants: Color = outfit.get("pants", Color(0.25, 0.35, 0.6))
	var accent: Color = outfit.get("accent", Color(0.85, 0.3, 0.3))
	var hair: Color = outfit.get("hair", Color(0.12, 0.1, 0.12))
	var ears: String = outfit.get("ears", "")
	var hat: String = outfit.get("hat", "")
	var outline := Color(0.2, 0.13, 0.1)

	var leg := 0.0
	var bob := sin(_t * 3.0) * 1.2
	if in_air:
		leg = 5.0
	elif moving:
		leg = sin(_t * 14.0) * 6.0
		bob = -absf(sin(_t * 14.0)) * 2.5

	# หาง
	if ears == "tiger":
		var pts := PackedVector2Array([Vector2(-12, -18 + bob), Vector2(-24, -20 + bob), Vector2(-30, -30 + bob), Vector2(-27, -42 + bob)])
		draw_polyline(pts, outline, 9.0)
		draw_polyline(pts, shirt, 6.0)
		draw_circle(Vector2(-27, -42 + bob), 4.0, accent)

	# ขา + เท้า
	draw_rect(Rect2(-11 + leg, -16, 9, 14), pants)
	draw_rect(Rect2(2 - leg, -16, 9, 14), pants)
	draw_rect(Rect2(-12 + leg, -4, 12, 4), outline)
	draw_rect(Rect2(1 - leg, -4, 12, 4), outline)

	# แขนหลัง
	draw_rect(Rect2(-18, -40 + bob, 6, 15), skin)

	# ลำตัว
	draw_rect(Rect2(-15, -43 + bob, 30, 29), outline)
	draw_rect(Rect2(-13, -41 + bob, 26, 25), shirt)
	if outfit.get("stripes", false):
		for i in 3:
			draw_line(Vector2(-13, -36 + bob + i * 7), Vector2(-4, -33 + bob + i * 7), accent, 3.0)
			draw_line(Vector2(13, -36 + bob + i * 7), Vector2(4, -33 + bob + i * 7), accent, 3.0)
	draw_rect(Rect2(-13, -21 + bob, 26, 5), accent)

	# แขนหน้า + อาวุธ
	var shoulder := Vector2(9, -37 + bob)
	if swing >= 0.0:
		var ang := lerpf(-2.3, 0.9, swing)
		var hand := shoulder + Vector2.RIGHT.rotated(ang) * 15.0
		var tip := shoulder + Vector2.RIGHT.rotated(ang) * 48.0
		draw_line(hand, tip, outline, 8.0)
		draw_line(hand, tip, outfit.get("weapon", Color(0.65, 0.45, 0.25)), 5.0)
		draw_line(shoulder, hand, skin, 7.0)
	else:
		draw_rect(Rect2(10, -40 + bob, 6, 15), skin)

	# หู (วาดก่อนหัว)
	var head := Vector2(1, -62 + bob)
	if ears == "tiger":
		for sx in [-1.0, 1.0]:
			draw_circle(head + Vector2(sx * 15, -19), 9.0, outline)
			draw_circle(head + Vector2(sx * 15, -19), 7.0, shirt)
			draw_circle(head + Vector2(sx * 15, -18), 3.5, Color(1.0, 0.75, 0.75))

	# หัว
	draw_circle(head, 24.0, outline)
	draw_circle(head + Vector2(-2, -3), 22.0, hair)
	draw_circle(head + Vector2(2, 2), 19.5, skin)
	# หน้าม้า
	draw_colored_polygon(PackedVector2Array([head + Vector2(-18, -8), head + Vector2(-4, -20), head + Vector2(20, -12), head + Vector2(14, -6), head + Vector2(6, -11), head + Vector2(-2, -5), head + Vector2(-10, -10)]), hair)
	if ears == "tiger":
		draw_line(head + Vector2(2, -21), head + Vector2(2, -13), accent, 3.0)
		draw_line(head + Vector2(-7, -19), head + Vector2(-5, -13), accent, 3.0)
		draw_line(head + Vector2(11, -19), head + Vector2(9, -13), accent, 3.0)
	# ตา แก้ม ปาก
	draw_circle(head + Vector2(5, 2), 3.6, outline)
	draw_circle(head + Vector2(15, 2), 3.6, outline)
	draw_circle(head + Vector2(6, 1), 1.2, Color.WHITE)
	draw_circle(head + Vector2(16, 1), 1.2, Color.WHITE)
	draw_circle(head + Vector2(1, 9), 3.8, Color(1.0, 0.55, 0.55, 0.55))
	draw_circle(head + Vector2(18, 9), 3.0, Color(1.0, 0.55, 0.55, 0.55))
	draw_arc(head + Vector2(10, 8), 4.0, 0.3, PI - 0.3, 8, outline, 2.0)

	# หมวก (สำหรับชาวบ้าน)
	if hat == "straw":
		draw_colored_polygon(PackedVector2Array([head + Vector2(-32, -10), head + Vector2(0, -34), head + Vector2(34, -10)]), Color(0.87, 0.72, 0.4))
		draw_line(head + Vector2(-32, -10), head + Vector2(34, -10), Color(0.6, 0.45, 0.2), 3.0)
	elif hat == "bun":
		draw_circle(head + Vector2(-6, -24), 9.0, hair)
