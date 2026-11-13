class_name ChibiVisual extends Node2D
## ภาพตัวละคร: ถ้า outfit มี "sprite" (ที่อยู่ไฟล์ภาพ) จะใช้ภาพจริง แล้วขยับด้วยโค้ด (โยกตัว เด้ง พุ่งตอนตี)
## ถ้าไม่มี จะวาดตัวชิบิด้วยโค้ดแทน (ภาพสำรอง)
## ทุกร่างใช้ขนาดเท่ากัน เปลี่ยนแค่ชุด (outfit)

var outfit := {}
var moving := false
var running := false
var in_air := false
var swing := -1.0  # ความคืบหน้าท่าตี 0..1 (ติดลบ = ไม่ได้ตี)
var _t := 0.0
var _blink_offset := randf() * 3.0
var _sprite: Sprite2D
var _sprite_path := ""


func _process(delta: float) -> void:
	_t += delta
	_update_sprite()
	queue_redraw()


func _update_sprite() -> void:
	var path: String = outfit.get("sprite", "")
	if path != _sprite_path:
		_sprite_path = path
		if path == "" or not ResourceLoader.exists(path):
			if _sprite:
				_sprite.queue_free()
				_sprite = null
		else:
			if _sprite == null:
				_sprite = Sprite2D.new()
				_sprite.centered = false
				add_child(_sprite)
			var tex: Texture2D = load(path)
			_sprite.texture = tex
			_sprite.offset = Vector2(-tex.get_width() * 0.5, -tex.get_height())
	if _sprite == null:
		return
	var rate := 20.0 if running else 13.0
	var rot := 0.0
	var pos := Vector2(0, 3)
	var breathe := 1.0 + sin(_t * 3.0) * 0.012
	if in_air:
		rot = 0.07
	elif moving:
		rot = sin(_t * rate) * 0.075
		pos.y -= absf(sin(_t * rate)) * 5.0
	if swing >= 0.0:
		rot += lerpf(-0.28, 0.3, swing)
		pos.x += sin(swing * PI) * 12.0
	_sprite.rotation = rot
	_sprite.position = pos
	_sprite.scale = Vector2(0.5, 0.5 * breathe)  # ไฟล์ภาพละเอียด 2 เท่าของขนาดที่แสดง


func _draw() -> void:
	if _sprite:
		if not in_air:
			Art.shadow(self, Vector2(0, 2), 26.0)
		return
	var skin: Color = outfit.get("skin", Color(1.0, 0.87, 0.74))
	var shirt: Color = outfit.get("shirt", Color.WHITE)
	var pants: Color = outfit.get("pants", Color(0.25, 0.35, 0.6))
	var accent: Color = outfit.get("accent", Color(0.85, 0.3, 0.3))
	var hair: Color = outfit.get("hair", Color(0.16, 0.13, 0.16))
	var ears: String = outfit.get("ears", "")
	var hat: String = outfit.get("hat", "")
	var ink := Art.INK

	var rate := 20.0 if running else 14.0
	var leg := 0.0
	var arm := 0.0
	var bob := sin(_t * 3.0) * 1.2
	if in_air:
		leg = 5.0
		arm = -5.0
	elif moving:
		leg = sin(_t * rate) * 7.0
		arm = sin(_t * rate) * 5.0
		bob = -absf(sin(_t * rate)) * 3.0

	if not in_air:
		Art.shadow(self, Vector2(0, 1), 24.0)

	# หาง
	if ears == "tiger":
		var tail := Art.bezier(Vector2(-10, -20 + bob), Vector2(-36, -12 + bob), Vector2(-31, -46 + bob + sin(_t * 4.0) * 3.0))
		Art.curve(self, tail, ink, 11.0)
		Art.curve(self, tail, shirt, 6.0)
		Art.circle(self, tail[tail.size() - 1], 3.4, accent)
		Art.circle(self, tail[7], 3.0, accent)

	# แขนหลัง
	Art.box(self, Rect2(-19, -41 + bob + arm * 0.4, 8, 17), skin, 4.0, 2.5)

	# ขา + รองเท้า
	Art.box(self, Rect2(-11 + leg, -18, 10, 14), pants, 4.0, 2.5)
	Art.box(self, Rect2(1 - leg, -18, 10, 14), pants, 4.0, 2.5)
	Art.rrect(self, Rect2(-13 + leg, -6, 16, 7), ink, 3.5)
	Art.rrect(self, Rect2(0 - leg, -6, 16, 7), ink, 3.5)

	# ลำตัว
	Art.box(self, Rect2(-14, -46 + bob, 28, 32), shirt, 10.0, 3.0)
	Art.rrect(self, Rect2(-10, -43 + bob, 9, 12), Color(1, 1, 1, 0.28), 5.0)
	if outfit.get("stripes", false):
		for i in 3:
			Art.line(self, Vector2(-13, -38 + bob + i * 7), Vector2(-6, -35 + bob + i * 7), accent, 2.6)
			Art.line(self, Vector2(13, -38 + bob + i * 7), Vector2(6, -35 + bob + i * 7), accent, 2.6)
	Art.rrect(self, Rect2(-14, -21 + bob, 28, 6), accent, 3.0)

	# แขนหน้า + อาวุธ
	var shoulder := Vector2(10, -38 + bob)
	if swing >= 0.0:
		var ang := lerpf(-2.3, 0.9, swing)
		var hand := shoulder + Vector2.RIGHT.rotated(ang) * 15.0
		var tip := shoulder + Vector2.RIGHT.rotated(ang) * 50.0
		Art.line(self, hand, tip, ink, 9.0)
		Art.line(self, hand, tip, outfit.get("weapon", Color(0.72, 0.5, 0.28)), 5.0)
		Art.line(self, shoulder, hand, ink, 10.0)
		Art.line(self, shoulder, hand, skin, 6.0)
	else:
		Art.box(self, Rect2(10, -41 + bob - arm * 0.4, 8, 17), skin, 4.0, 2.5)

	var head := Vector2(1, -67 + bob)

	# หู (วาดก่อนหัว)
	if ears == "tiger":
		for sx in [-1.0, 1.0]:
			Art.blob(self, head + Vector2(sx * 17, -19), 7.5, 7.5, shirt)
			Art.circle(self, head + Vector2(sx * 17, -18), 3.6, Color(1.0, 0.78, 0.78))

	# หัว
	Art.ellipse(self, head, 27.5, 25.5, ink)
	Art.ellipse(self, head + Vector2(-1, -1), 24.5, 22.5, hair)
	Art.ellipse(self, head + Vector2(3, 4), 20.0, 17.5, skin)
	# หน้าม้า
	Art.ellipse(self, head + Vector2(-8, -9), 12.0, 8.5, hair)
	Art.ellipse(self, head + Vector2(7, -12), 12.0, 8.0, hair)
	Art.ellipse(self, head + Vector2(18, -8), 7.0, 6.0, hair)
	draw_arc(head + Vector2(-2, -3), 19.0, -2.5, -1.6, 8, Color(1, 1, 1, 0.22), 3.0, true)
	if ears == "tiger":
		for sx in [-8.0, 1.0, 10.0]:
			Art.line(self, head + Vector2(sx, -22), head + Vector2(sx + 1, -15), accent.lerp(shirt, 0.15), 2.6)

	# ตา (กะพริบเป็นระยะ)
	var blinking := fmod(_t + _blink_offset, 3.6) < 0.12
	for ex in [5.5, 16.5]:
		if blinking:
			Art.line(self, head + Vector2(ex - 3, 5), head + Vector2(ex + 3, 5), ink, 2.2)
		else:
			Art.ellipse(self, head + Vector2(ex, 4.5), 3.5, 4.8, Color(0.22, 0.14, 0.12))
			Art.circle(self, head + Vector2(ex + 1.2, 2.8), 1.5, Color.WHITE)
			Art.circle(self, head + Vector2(ex - 1.0, 6.4), 0.8, Color(1, 1, 1, 0.8))
	# แก้ม + ปาก
	Art.ellipse(self, head + Vector2(-1, 12), 4.6, 3.0, Color(1.0, 0.5, 0.55, 0.5))
	Art.ellipse(self, head + Vector2(21, 11), 3.2, 2.6, Color(1.0, 0.5, 0.55, 0.5))
	draw_arc(head + Vector2(11, 10), 3.8, 0.25, PI - 0.25, 8, ink, 2.0, true)

	# หมวก / ทรงผม (สำหรับชาวบ้าน)
	if hat == "straw":
		Art.poly(self, PackedVector2Array([head + Vector2(-36, -9), head + Vector2(-6, -36), head + Vector2(6, -36), head + Vector2(38, -9)]), ink)
		Art.poly(self, PackedVector2Array([head + Vector2(-31, -11), head + Vector2(-4, -33), head + Vector2(4, -33), head + Vector2(33, -11)]), Color(0.93, 0.8, 0.5))
		Art.line(self, head + Vector2(-20, -19), head + Vector2(22, -19), Color(0.8, 0.62, 0.32), 2.0)
		Art.rrect(self, Rect2(head + Vector2(-37, -13), Vector2(76, 6)), Color(0.8, 0.62, 0.32), 3.0)
	elif hat == "bun":
		Art.blob(self, head + Vector2(-8, -27), 8.0, 7.5, hair, 2.5)
		Art.circle(self, head + Vector2(-2, -22), 2.5, accent)
