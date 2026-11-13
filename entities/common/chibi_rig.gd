class_name ChibiRig extends Node2D
## ทำให้ภาพตัวละครภาพเดียว "ขยับเป็นท่า" ได้ โดยตัดภาพเป็นชิ้น (หัว ลำตัว แขน ขา) แล้วหมุนแต่ละชิ้นด้วยโค้ด
## ท่าที่มี: ยืนหายใจ / เดิน / วิ่ง / กระโดดขึ้น-ลง / ฟันอาวุธ / ชูแขนร่ายสกิล / โดนตี
##
## rig = ตำแหน่งรอยตัด เป็นสัดส่วน 0..1 ของภาพ:
##   head_y = ใต้คาง, hip_y = เอว/ต้นขา, arm_l / arm_r = ขอบลำตัวซ้าย/ขวา, leg_split = ระหว่างขาสองข้าง
##   leg_x0 = ขอบซ้ายของขาซ้าย, back_static = ชิ้นซ้ายมีหางติดมาด้วย (แกว่งเบา ๆ แทนการแกว่งแขน)

var moving := false
var running := false
var in_air := false
var vy := 0.0
var swing := -1.0
var hurt := 0.0
var cast := 0.0

var _parts := {}
var _rest := {}
var _weapon: WeaponDraw
var _back_static := false
var _phase := 0.0
var _t := 0.0
var _flash := 0.0
var _flash_time := 0.2
var _flash_color := Color.WHITE


func setup(tex: Texture2D, rig: Dictionary, weapon_kind: String) -> void:
	scale = Vector2(0.5, 0.5)  # ไฟล์ภาพละเอียด 2 เท่าของขนาดที่แสดง
	position = Vector2(0, 3)
	var w := float(tex.get_width())
	var h := float(tex.get_height())
	var hy := roundf(float(rig["head_y"]) * h)
	var py := roundf(float(rig["hip_y"]) * h)
	var al := roundf(float(rig["arm_l"]) * w)
	var ar := roundf(float(rig["arm_r"]) * w)
	var ls := roundf(float(rig["leg_split"]) * w)
	var lx0 := roundf(float(rig.get("leg_x0", 0.0)) * w)
	var ov := 6.0
	_back_static = rig.get("back_static", false)

	# ลำดับการสร้าง = ลำดับการวาด (ชิ้นหลังสุดก่อน)
	if _back_static:
		_add(tex, "back", Rect2(0, hy, al, h - hy), Vector2(al, (hy + h) * 0.5), w, h)
	else:
		_add(tex, "back", Rect2(0, hy, al, py - hy), Vector2(al * 0.72, hy + 10.0), w, h)
	_add(tex, "leg_b", Rect2(lx0, py, ls - lx0, h - py), Vector2((lx0 + ls) * 0.5, py + 2.0), w, h)
	_add(tex, "leg_f", Rect2(ls, py, w - ls, h - py), Vector2((ls + ar) * 0.5, py + 2.0), w, h)
	_add(tex, "torso", Rect2(al, hy - ov, ar - al, py - hy + ov * 2.0), Vector2((al + ar) * 0.5, py), w, h)
	_add(tex, "arm_f", Rect2(ar, hy, w - ar, py - hy), Vector2(ar + (w - ar) * 0.28, hy + 10.0), w, h)
	_add(tex, "head", Rect2(0, 0, w, hy), Vector2(w * 0.5, hy), w, h)

	_weapon = WeaponDraw.new()
	_weapon.kind = weapon_kind
	_weapon.show_behind_parent = true
	_weapon.position = Vector2((w - ar) * 0.1, py - hy - 26.0)
	_weapon.rotation = -0.35
	_weapon.visible = false
	_parts["arm_f"].add_child(_weapon)


func _add(tex: Texture2D, part: String, region: Rect2, pivot: Vector2, w: float, h: float) -> void:
	var s := Sprite2D.new()
	s.texture = tex
	s.region_enabled = true
	s.region_rect = region
	s.centered = false
	s.offset = region.position - pivot   # ให้จุดหมุนอยู่ที่ pivot
	s.position = pivot - Vector2(w * 0.5, h)
	add_child(s)
	_parts[part] = s
	_rest[part] = s.position


## กะพริบสี (ขาว = เปลี่ยนร่าง, แดง = โดนตี)
func flash(color: Color, time := 0.2) -> void:
	_flash_color = color
	_flash_time = time
	_flash = time


func animate(delta: float) -> void:
	_t += delta
	var rate := 17.0 if running else 11.5
	if moving and not in_air:
		_phase += delta * rate
	else:
		_phase = 0.0
	var s := sin(_phase)
	var c := cos(_phase)

	# ค่าเริ่มต้น = ท่ายืนหายใจ
	var leg_f := 0.0
	var leg_b := 0.0
	var leg_f_y := 0.0
	var leg_b_y := 0.0
	var arm_f := sin(_t * 2.2) * 0.05
	var arm_b := -arm_f
	var body_y := sin(_t * 3.0) * 1.6
	var head_y := sin(_t * 3.0 - 0.7) * 1.8
	var head_rot := 0.0
	var lean := 0.0

	if in_air:
		var rising := vy < 0.0
		leg_f = -0.6 if rising else -0.25
		leg_b = 0.5 if rising else 0.35
		leg_f_y = -10.0
		leg_b_y = -4.0
		arm_f = -0.9 if rising else -1.5
		arm_b = 0.9 if rising else 1.5
		lean = 0.08 if rising else -0.05
		head_y = -2.0 if rising else 2.0
	elif moving:
		leg_f = s * 0.55
		leg_b = -s * 0.55
		leg_f_y = -maxf(c, 0.0) * 9.0
		leg_b_y = -maxf(-c, 0.0) * 9.0
		arm_f = -s * 0.7
		arm_b = s * 0.7
		body_y = -absf(c) * 5.0
		head_y = body_y - absf(s) * 1.5
		head_rot = s * 0.035
		lean = 0.14 if running else 0.05

	if cast > 0.0:
		arm_f = -2.7
		arm_b = 2.7
		head_y -= 3.0
		lean -= 0.05
	if swing >= 0.0:
		arm_f = lerpf(-3.0, -0.25, ease(swing, 0.4))
		arm_b = lerpf(0.5, -0.3, swing)
		lean += lerpf(-0.14, 0.2, ease(swing, 0.5))
		head_rot += lerpf(-0.06, 0.08, swing)
	if hurt > 0.0:
		lean = -0.28
		arm_f = -1.3
		arm_b = 1.3
		head_rot = -0.16

	var k := minf(1.0, delta * 24.0)  # ไล่เข้าหาท่าเป้าหมายอย่างนุ่มนวล
	var snap := swing >= 0.0
	_pose("leg_f", leg_f, Vector2(0, leg_f_y), k)
	_pose("leg_b", leg_b, Vector2(0, leg_b_y), k)
	_pose("torso", 0.0, Vector2(0, body_y), k)
	_pose("arm_f", arm_f, Vector2(0, body_y), 1.0 if snap else k)
	if _back_static:
		_pose("back", clampf(arm_b, -1.0, 1.0) * 0.07 + sin(_t * 5.0) * 0.05, Vector2(0, body_y * 0.5), k)
	else:
		_pose("back", arm_b, Vector2(0, body_y), k)
	_pose("head", head_rot, Vector2(0, head_y), k)
	rotation = lerp_angle(rotation, lean, k)
	_weapon.visible = swing >= 0.0 or cast > 0.0

	if _flash > 0.0:
		_flash -= delta
		modulate = Color.WHITE.lerp(_flash_color, clampf(_flash / _flash_time, 0.0, 1.0))
	else:
		modulate = Color.WHITE


func _pose(part: String, rot: float, offset: Vector2, k: float) -> void:
	var s: Sprite2D = _parts[part]
	s.rotation = lerp_angle(s.rotation, rot, k)
	s.position = s.position.lerp(_rest[part] + offset, k)


## อาวุธที่โผล่มาตอนโจมตี (ดาบไม้ของร่างปกติ / กรงเล็บของร่างเสือ) วาดแบบเหลี่ยมให้เข้ากับพิกเซลอาร์ต
class WeaponDraw extends Node2D:
	var kind := "sword"

	func _draw() -> void:
		var ink := Color(0.13, 0.09, 0.12)
		if kind == "claw":
			for i in 3:
				var x := (i - 1) * 15.0
				var tip := Vector2(x * 1.9, 66.0 - absf(i - 1) * 8.0)
				draw_colored_polygon(PackedVector2Array([Vector2(x - 8, 6), Vector2(x + 8, 6), tip + Vector2(3, 4), tip + Vector2(-3, 4)]), ink)
				draw_colored_polygon(PackedVector2Array([Vector2(x - 5, 9), Vector2(x + 5, 9), tip]), Color(1.0, 0.97, 0.86))
				draw_line(Vector2(x - 2, 12), tip + Vector2(-1, -8), Color(1.0, 0.8, 0.35), 2.0)
		else:
			# ดาบ: ด้าม กระบัง ใบดาบ
			draw_rect(Rect2(-7, -12, 14, 24), ink)
			draw_rect(Rect2(-4, -9, 8, 18), Color(0.55, 0.33, 0.2))
			draw_rect(Rect2(-15, 8, 30, 10), ink)
			draw_rect(Rect2(-12, 10, 24, 5), Color(0.98, 0.8, 0.3))
			draw_colored_polygon(PackedVector2Array([Vector2(-9, 16), Vector2(9, 16), Vector2(9, 84), Vector2(0, 100), Vector2(-9, 84)]), ink)
			draw_colored_polygon(PackedVector2Array([Vector2(-6, 18), Vector2(6, 18), Vector2(6, 82), Vector2(0, 93), Vector2(-6, 82)]), Color(0.84, 0.9, 0.96))
			draw_rect(Rect2(-4, 20, 4, 60), Color(1, 1, 1))
