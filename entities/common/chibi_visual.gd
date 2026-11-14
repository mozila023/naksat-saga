class_name ChibiVisual extends Node2D
## ภาพตัวละคร มี 3 แบบ เลือกตามข้อมูลใน outfit (เรียงตามลำดับที่ใช้ก่อน):
##   1) "frames" = ภาพวาดทีละท่า (ยืน เดิน 4 ภาพ ตี 3 ภาพ กระโดด ตก ลงพื้น) — เป็นธรรมชาติที่สุด
##   2) "rig"    = ตัดภาพนิ่งเป็นชิ้นแล้วหมุนแขนขา (สำรอง)
##   3) "sprite" = ภาพนิ่งภาพเดียว โยกตัวเบา ๆ (ใช้กับชาวบ้าน)
## รายละเอียดเดิม: ถ้า outfit มี "sprite" (ที่อยู่ไฟล์ภาพ) จะใช้ภาพจริง แล้วขยับด้วยโค้ด (โยกตัว เด้ง พุ่งตอนตี)
## ถ้าไม่มี จะวาดตัวชิบิด้วยโค้ดแทน (ภาพสำรอง)
## ทุกร่างใช้ขนาดเท่ากัน เปลี่ยนแค่ชุด (outfit)

var outfit := {}
var moving := false
var running := false
var in_air := false
var swing := -1.0  # ความคืบหน้าท่าตี 0..1 (ติดลบ = ไม่ได้ตี)
var vy := 0.0      # ความเร็วแนวตั้ง (ไว้เลือกท่ากระโดดขึ้น/ลง)
var hurt := 0.0    # เวลาที่เหลือของท่าโดนตี
var cast := 0.0    # เวลาที่เหลือของท่าชูแขนร่ายสกิล
var _rig: ChibiRig
var _frames := {}        # ชื่อท่า -> [ภาพ]
var _fsprite: Sprite2D
var _frames_key := ""
var _walk_t := 0.0
var _land_t := 0.0
var _was_air := false
var _flash := 0.0
var _flash_time := 0.2
var _flash_color := Color.WHITE
var _t := 0.0
var _blink_offset := randf() * 3.0
var _sprite: Sprite2D
var _sprite_path := ""

# ---------- อาวุธที่ถือ (เปลี่ยนตามอาวุธที่สวมในช่องอาวุธ) ----------
## ไอคอนอาวุธ (ชื่อไฟล์ item_<ชื่อ>.png) "" = ไม่ถือ
var weapon_icon := ""
var _wep_hand: Sprite2D
var _wep_back: Sprite2D
var _wep_key := ""
var _wep_fist: Sprite2D  # มือที่กำอาวุธ วาดทับด้ามอาวุธอีกชั้น (ตัว -> อาวุธ -> มือ)
var _fist_tex := {}       # เฟรมท่าตี -> ภาพมือ
# ตำแหน่งมือในภาพท่าตีแต่ละเฟรม (พิกัดในไฟล์ภาพ 360x300 เท้าอยู่กึ่งกลางล่าง) และทิศของอาวุธ (องศา, 0 = ชี้ไปหน้า)
#   normal = ร่างปกติ (ถือไม้), paw = ร่างนักษัตร (ตอนนี้ร่างนักษัตรไม่แสดงอาวุธ เก็บไว้เผื่อใช้)
const GRIPS := {
	"normal": [[Vector2(141, 142), -118.0], [Vector2(279, 189), -1.0], [Vector2(151, 232), 46.0]],
	"normal_girl": [[Vector2(133, 121), -130.0], [Vector2(283, 199), -1.0], [Vector2(188, 232), 36.0]],
	"paw": [[Vector2(232, 114), -100.0], [Vector2(326, 184), -6.0], [Vector2(266, 266), 38.0]],
}
const BACK_GRIP := [Vector2(150, 206), -122.0]  # ตอนไม่ได้ตี: สะพายหลังเฉียง ๆ
const ICON_HANDLE := Vector2(17, 47)  # จุดด้ามจับในไอคอน 64x64 (ไอคอนอาวุธวาดเฉียง ด้ามล่างซ้าย ปลายขวาบน)


func _process(delta: float) -> void:
	_t += delta
	hurt = maxf(hurt - delta, 0.0)
	cast = maxf(cast - delta, 0.0)
	_update_frames(delta)
	if _fsprite:
		queue_redraw()
		return
	_update_sprite()
	if _rig:
		_rig.moving = moving
		_rig.running = running
		_rig.in_air = in_air
		_rig.vy = vy
		_rig.swing = swing
		_rig.hurt = hurt
		_rig.cast = cast
		_rig.animate(delta)
	queue_redraw()


## กะพริบสีทั้งตัว (ขาว = เปลี่ยนร่าง, แดง = โดนตี)
func flash(color: Color, time := 0.2) -> void:
	_flash_color = color
	_flash_time = time
	_flash = time
	if _rig:
		_rig.flash(color, time)


## ภาพของท่าปัจจุบัน (ใช้ทำเงาตามตัวตอนพุ่ง)
func current_texture() -> Texture2D:
	return _fsprite.texture if _fsprite else null


func _load_frames(prefix: String) -> void:
	_frames.clear()
	for anim in [["idle", 1], ["walk", 6], ["attack", 3], ["jump", 1], ["fall", 1], ["land", 1]]:
		var list: Array = []
		for i in int(anim[1]):
			var path := "%s%s_%d.png" % [prefix, anim[0], i]
			if ResourceLoader.exists(path):
				list.append(load(path))
		if list.is_empty():
			_frames.clear()
			return
		_frames[anim[0]] = list


func _update_frames(delta: float) -> void:
	var prefix: String = outfit.get("frames", "")
	if prefix != _frames_key:
		_frames_key = prefix
		if prefix != "":
			_load_frames(prefix)
		else:
			_frames.clear()
		if _frames.is_empty():
			if _fsprite:
				_fsprite.queue_free()
				_fsprite = null
		else:
			for old in [_sprite, _rig]:
				if old:
					old.queue_free()
			_sprite = null
			_rig = null
			_sprite_path = ""
			if _fsprite == null:
				_fsprite = Sprite2D.new()
				_fsprite.centered = false
				_fsprite.scale = Vector2(0.5, 0.5)  # ไฟล์ภาพละเอียด 2 เท่าของขนาดที่แสดง
				add_child(_fsprite)
	if _fsprite == null:
		return

	# เลือกท่าตามสถานะ
	if _was_air and not in_air:
		_land_t = 0.1
	_was_air = in_air
	_land_t = maxf(_land_t - delta, 0.0)
	var tex: Texture2D = _frames["idle"][0]
	var rot := 0.0
	var pos := Vector2(0, 3)
	var sy := 1.0
	if hurt > 0.0:
		tex = _frames["fall"][0]
		rot = -0.22
	elif swing >= 0.0:
		tex = _frames["attack"][0 if swing < 0.22 else (1 if swing < 0.62 else 2)]
	elif cast > 0.0:
		tex = _frames["attack"][0]
	elif in_air:
		tex = _frames["jump"][0] if vy < 0.0 else _frames["fall"][0]
	elif _land_t > 0.0:
		tex = _frames["land"][0]
	elif moving:
		_walk_t += delta * (13.0 if running else 8.5) * _frames["walk"].size() / 4.0  # เฟรมมากขึ้น เปลี่ยนเร็วขึ้น ก้าวเท่าเดิม
		tex = _frames["walk"][int(_walk_t) % _frames["walk"].size()]  # เดินได้ 4-6 เฟรม (มีเท่าไรใช้เท่านั้น)
		pos.y -= absf(sin(_walk_t * PI)) * 2.0
		rot = 0.07 if running else 0.0
	else:
		_walk_t = 0.0
		sy = 1.0 + sin(_t * 3.0) * 0.015
	_fsprite.texture = tex
	_fsprite.offset = Vector2(-tex.get_width() * 0.5, -tex.get_height())
	_fsprite.position = pos
	_fsprite.rotation = rot
	_fsprite.scale = Vector2(0.5, 0.5 * sy)
	var attack_frame := -1
	if hurt <= 0.0 and swing >= 0.0:
		attack_frame = 0 if swing < 0.22 else (1 if swing < 0.62 else 2)
	elif hurt <= 0.0 and cast > 0.0:
		attack_frame = 0
	_update_weapon(attack_frame, pos, sy)
	if _flash > 0.0:
		_flash -= delta
		_fsprite.modulate = Color.WHITE.lerp(_flash_color, clampf(_flash / _flash_time, 0.0, 1.0))
	else:
		_fsprite.modulate = Color.WHITE


## วาดอาวุธ: ตอนตีอยู่ในมือตามท่า ตอนอื่นสะพายหลัง
func _update_weapon(attack_frame: int, pos: Vector2, sy: float) -> void:
	if _wep_hand == null:
		_wep_back = Sprite2D.new()
		_wep_back.centered = false
		_wep_back.z_index = -1  # อยู่หลังตัวละคร
		add_child(_wep_back)
		_wep_hand = Sprite2D.new()
		_wep_hand.centered = false
		_wep_hand.z_index = 1   # อยู่หน้าตัวละคร
		add_child(_wep_hand)
		_wep_fist = Sprite2D.new()
		_wep_fist.centered = false
		_wep_fist.z_index = 2   # มือทับด้ามอาวุธ
		add_child(_wep_fist)
	if weapon_icon != _wep_key:
		_wep_key = weapon_icon
		var path := "res://assets/art/items/item_%s.png" % weapon_icon
		var tex: Texture2D = load(path) if weapon_icon != "" and ResourceLoader.exists(path) else null
		for s in [_wep_hand, _wep_back]:
			s.texture = tex
			s.offset = -ICON_HANDLE
	# ถืออาวุธเฉพาะร่างปกติ (ร่างแปลงนักษัตรสู้ด้วยอุ้งมือ ไม่แสดงอาวุธ)
	_wep_fist.visible = false
	if _wep_hand.texture == null or not outfit.has("grip"):
		_wep_hand.visible = false
		_wep_back.visible = false
		return
	var grip: Array
	var s: Sprite2D
	if attack_frame >= 0:
		grip = GRIPS[outfit.get("grip", "paw")][attack_frame]
		s = _wep_hand
		_wep_back.visible = false
	else:
		grip = BACK_GRIP
		s = _wep_back
		_wep_hand.visible = false
	s.visible = true
	var p: Vector2 = grip[0]
	s.position = pos + Vector2((p.x - 180.0) * 0.5, (p.y - 300.0) * 0.5 * sy)
	s.rotation = deg_to_rad(float(grip[1]) + 45.0)
	s.scale = Vector2(0.72, 0.72) if attack_frame >= 0 else Vector2(0.56, 0.56)
	s.modulate = _fsprite.modulate * (Color.WHITE if attack_frame >= 0 else Color(0.85, 0.85, 0.85))
	# มือ (ตัดจากภาพท่าตีเดียวกัน) วาดทับด้ามอาวุธ ให้ดูเหมือนกำอยู่จริง
	if attack_frame >= 0:
		var key: String = str(outfit.get("frames", "")) + str(attack_frame)
		if not _fist_tex.has(key):
			var path := "%shand_%d.png" % [outfit.get("frames", ""), attack_frame]
			_fist_tex[key] = load(path) if ResourceLoader.exists(path) else null
		if _fist_tex[key]:
			_wep_fist.texture = _fist_tex[key]
			_wep_fist.offset = _fsprite.offset
			_wep_fist.position = _fsprite.position
			_wep_fist.rotation = _fsprite.rotation
			_wep_fist.scale = _fsprite.scale
			_wep_fist.modulate = _fsprite.modulate
			_wep_fist.visible = true


func _update_sprite() -> void:
	var path: String = outfit.get("sprite", "")
	if path != _sprite_path:
		_sprite_path = path
		if _rig:
			_rig.queue_free()
			_rig = null
		if path != "" and ResourceLoader.exists(path) and outfit.has("rig"):
			# มีข้อมูลรอยตัด -> ตัดภาพเป็นชิ้นแล้วขยับเป็นท่า
			if _sprite:
				_sprite.queue_free()
				_sprite = null
			_rig = ChibiRig.new()
			add_child(_rig)
			_rig.setup(load(path), outfit["rig"], outfit.get("weapon_kind", "sword"))
		elif path == "" or not ResourceLoader.exists(path):
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
	if _sprite or _rig or _fsprite:
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
