class_name TigerBoss extends CharacterBody2D
## บอสนักษัตรตัวแรก: พญาเสือโคร่ง (ปีขาล)
## ท่า: ตะปบ / กระโจนทับ / คำรามปล่อยคลื่น (เมื่อเลือดต่ำกว่าครึ่ง) — มีกรอบแดงเตือนก่อนทุกท่า

const GRAVITY := 1800.0
const MAX_HP := 650.0
const BOSS_NAME := "พญาเสือโคร่ง"
const SIZE := Vector2(130, 96)

var hp := MAX_HP
var facing := -1
var state := "idle"
var arena_left := 100.0
var arena_right := 1700.0

var _state_t := 1.5
var _flash := 0.0
var _t := 0.0
var _target_x := 0.0
var _contact_cd := 0.0
var _dead := false


func _init() -> void:
	collision_layer = 4
	collision_mask = 1
	z_index = 6


func _ready() -> void:
	add_to_group("enemies")
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = SIZE
	shape.shape = rect
	shape.position = Vector2(0, -SIZE.y * 0.5)
	add_child(shape)
	Game.boss = self


func is_alive() -> bool:
	return not _dead


func get_hurt_rect() -> Rect2:
	return Rect2(global_position + Vector2(-SIZE.x * 0.5, -SIZE.y), SIZE)


func _phase2() -> bool:
	return hp < MAX_HP * 0.5


func _set_state(s: String, t: float) -> void:
	state = s
	_state_t = t


func _physics_process(delta: float) -> void:
	_t += delta
	_flash = maxf(_flash - delta, 0.0)
	_contact_cd = maxf(_contact_cd - delta, 0.0)
	queue_redraw()
	if not is_on_floor():
		velocity.y = minf(velocity.y + GRAVITY * delta, 1500.0)

	if _dead:
		velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
		modulate.a -= delta * 0.9
		if modulate.a <= 0.0:
			queue_free()
		move_and_slide()
		return

	var p := Game.player
	if p == null or p.dead:
		velocity.x = move_toward(velocity.x, 0.0, 800.0 * delta)
		move_and_slide()
		return

	var dx := p.global_position.x - global_position.x
	var dist := absf(dx)
	_state_t -= delta

	match state:
		"idle":
			velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
			facing = 1 if dx > 0.0 else -1
			if _state_t <= 0.0:
				_choose_action(dist)
		"walk":
			facing = 1 if dx > 0.0 else -1
			velocity.x = facing * (220.0 if _phase2() else 160.0)
			if dist < 170.0:
				_start_claw()
			elif _state_t <= 0.0:
				_set_state("idle", 0.2)
		"claw_tel":
			velocity.x = 0.0
			if _state_t <= 0.0:
				var rect := _claw_rect()
				Fx.spawn(get_parent(), global_position + Vector2(facing * 40, -60), "claw", Vector2(200, 130), Color(1, 0.3, 0.2), facing, 0.3)
				if rect.intersects(p.get_hurt_rect()):
					p.take_damage(16.0, global_position.x)
				_set_state("recover", 0.45 if _phase2() else 0.7)
		"pounce_tel":
			velocity.x = 0.0
			if _state_t <= 0.0:
				velocity.x = clampf((_target_x - global_position.x) / 0.75, -760.0, 760.0)
				velocity.y = -720.0
				_set_state("pounce", 0.15)
		"pounce":
			if is_on_floor() and _state_t <= 0.0:
				velocity.x = 0.0
				var rect := Rect2(global_position + Vector2(-150, -110), Vector2(300, 110))
				Fx.spawn(get_parent(), global_position + Vector2(0, -20), "ring", Vector2(160, 160), Color(1, 0.6, 0.2), 1, 0.35)
				if rect.intersects(p.get_hurt_rect()):
					p.take_damage(20.0, global_position.x)
				_set_state("recover", 0.6 if _phase2() else 0.9)
		"roar_tel":
			velocity.x = 0.0
			if _state_t <= 0.0:
				Fx.spawn(get_parent(), global_position + Vector2(0, -60), "ring", Vector2(220, 220), Color(1, 0.85, 0.3), 1, 0.5)
				for d in [-1, 1]:
					var wave := Shockwave.new()
					wave.dir = d
					get_parent().add_child(wave)
					wave.global_position = global_position + Vector2(d * 70, 0)
				_set_state("recover", 0.9)
		"recover":
			velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
			if _state_t <= 0.0:
				_set_state("idle", 0.35 if _phase2() else 0.7)

	move_and_slide()
	global_position.x = clampf(global_position.x, arena_left, arena_right)

	if _contact_cd <= 0.0 and get_hurt_rect().grow(-10.0).intersects(p.get_hurt_rect()):
		p.take_damage(10.0, global_position.x)
		_contact_cd = 0.5


func _choose_action(dist: float) -> void:
	if _phase2() and randf() < 0.3:
		_set_state("roar_tel", 0.8)
		return
	if dist < 190.0:
		if randf() < 0.75:
			_start_claw()
		else:
			_start_pounce()
	elif dist > 430.0:
		if randf() < 0.65:
			_start_pounce()
		else:
			_set_state("walk", 1.4)
	else:
		if randf() < 0.5:
			_set_state("walk", 1.2)
		else:
			_start_pounce()


func _claw_rect() -> Rect2:
	var w := 200.0
	var x0 := global_position.x if facing > 0 else global_position.x - w
	return Rect2(Vector2(x0, global_position.y - 130.0), Vector2(w, 130.0))


func _start_claw() -> void:
	var t := 0.38 if _phase2() else 0.5
	_set_state("claw_tel", t)
	Fx.spawn(get_parent(), _claw_rect().position, "warn", _claw_rect().size, Color(1, 0.2, 0.2), 1, t)


func _start_pounce() -> void:
	var t := 0.5 if _phase2() else 0.65
	_target_x = clampf(Game.player.global_position.x, arena_left, arena_right)
	_set_state("pounce_tel", t)
	Fx.spawn(get_parent(), Vector2(_target_x - 150.0, global_position.y - 110.0), "warn", Vector2(300, 110), Color(1, 0.5, 0.1), 1, t + 0.7)


func take_hit(dmg: float, _dir: float, _stun: float) -> void:
	if _dead:
		return
	hp -= dmg
	_flash = 0.12
	Game.spawn_number(global_position + Vector2(0, -SIZE.y - 20.0), str(int(dmg)), Color(1, 0.95, 0.5))
	if hp <= 0.0:
		hp = 0.0
		_dead = true
		remove_from_group("enemies")
		Fx.spawn(get_parent(), global_position + Vector2(0, -50), "ring", Vector2(260, 260), Color(1, 0.9, 0.5), 1, 0.7)
		Game.on_boss_defeated("tiger")


func _draw() -> void:
	modulate = Color(2.0, 2.0, 2.0, modulate.a) if _flash > 0.0 else Color(1, 1, 1, modulate.a)
	var warn := state.ends_with("_tel") and int(_t * 14.0) % 2 == 0
	var orange := Color(0.99, 0.64, 0.2)
	if warn:
		orange = orange.lerp(Color(1, 0.3, 0.25), 0.45)
	elif _phase2() and not _dead:
		orange = orange.lerp(Color(1.0, 0.36, 0.14), 0.3)
	var ink := Art.INK
	var dark := Color(0.24, 0.15, 0.12)
	var cream := Color(1.0, 0.95, 0.84)
	var crouch := 0.82 if state == "pounce_tel" else 1.0 + sin(_t * 4.0) * 0.02
	Art.shadow(self, Vector2(0, 2), 80.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(facing, crouch))

	# หาง
	var sway := sin(_t * 5.0) * 9.0
	var tail := Art.bezier(Vector2(-58, -52), Vector2(-104, -54), Vector2(-92, -112 + sway), 14)
	Art.curve(self, tail, ink, 19.0)
	Art.curve(self, tail, orange, 13.0)
	for i in [4, 8, 12]:
		Art.circle(self, tail[i], 6.0, dark)
	# ขาหลัง (ไกล)
	for lx in [-44.0, 22.0]:
		Art.box(self, Rect2(lx - 9, -34, 20, 34), orange.darkened(0.14), 8.0)
	# ลำตัว
	Art.blob(self, Vector2(-6, -56), 62.0, 32.0, orange)
	Art.ellipse(self, Vector2(-4, -38), 46.0, 12.0, cream)
	Art.ellipse(self, Vector2(-22, -76), 26.0, 7.0, Color(1, 1, 1, 0.16))
	for i in 4:
		var sx := -50.0 + i * 24.0
		Art.poly(self, PackedVector2Array([Vector2(sx, -84), Vector2(sx + 11, -86), Vector2(sx + 7, -60)]), dark)
	# ขาหน้า (ใกล้)
	for lx in [-26.0, 40.0]:
		Art.box(self, Rect2(lx - 10, -34, 22, 34), orange, 9.0)
		Art.rrect(self, Rect2(lx - 10, -11, 22, 11), cream, 6.0)
		Art.line(self, Vector2(lx - 6, -24), Vector2(lx + 2, -22), dark, 3.0)
	# หู
	for ex in [32.0, 82.0]:
		Art.blob(self, Vector2(ex, -122), 13.0, 13.0, orange)
		Art.circle(self, Vector2(ex, -120), 6.0, Color(1, 0.74, 0.74))
	# หัว
	Art.blob(self, Vector2(57, -86), 42.0, 39.0, orange)
	Art.ellipse(self, Vector2(22, -74), 9.0, 12.0, cream)
	Art.ellipse(self, Vector2(92, -74), 9.0, 12.0, cream)
	Art.ellipse(self, Vector2(62, -70), 23.0, 19.0, cream)
	Art.ellipse(self, Vector2(40, -106), 16.0, 6.0, Color(1, 1, 1, 0.18))
	# ลายหน้าผาก + แก้ม
	Art.poly(self, PackedVector2Array([Vector2(52, -124), Vector2(62, -124), Vector2(57, -104)]), dark)
	Art.poly(self, PackedVector2Array([Vector2(35, -118), Vector2(43, -121), Vector2(44, -104)]), dark)
	Art.poly(self, PackedVector2Array([Vector2(71, -121), Vector2(79, -118), Vector2(70, -104)]), dark)
	Art.line(self, Vector2(17, -88), Vector2(28, -85), dark, 3.5)
	Art.line(self, Vector2(97, -88), Vector2(86, -85), dark, 3.5)
	# ตาดุ
	var pupil := Color(0.85, 0.12, 0.1) if _phase2() else Color(0.18, 0.1, 0.08)
	for ex in [45.0, 71.0]:
		Art.blob(self, Vector2(ex, -91), 7.0, 7.5, Color.WHITE, 2.0)
		Art.ellipse(self, Vector2(ex + 2, -90), 3.2, 4.4, pupil)
		Art.circle(self, Vector2(ex + 3, -92), 1.2, Color.WHITE)
	Art.line(self, Vector2(34, -104), Vector2(53, -97), ink, 4.5)
	Art.line(self, Vector2(84, -104), Vector2(65, -97), ink, 4.5)
	# จมูก ปาก เขี้ยว
	Art.poly(self, PackedVector2Array([Vector2(56, -78), Vector2(70, -78), Vector2(63, -69)]), Color(0.95, 0.45, 0.5))
	draw_arc(Vector2(56, -67), 7.0, 0.1, PI - 0.1, 10, ink, 2.6, true)
	draw_arc(Vector2(70, -67), 7.0, 0.1, PI - 0.1, 10, ink, 2.6, true)
	Art.poly(self, PackedVector2Array([Vector2(50, -61), Vector2(57, -61), Vector2(54, -50)]), Color.WHITE)
	Art.poly(self, PackedVector2Array([Vector2(70, -61), Vector2(77, -61), Vector2(73, -50)]), Color.WHITE)
	# หนวด
	for s in [-1.0, 1.0]:
		Art.line(self, Vector2(63 + s * 20, -70), Vector2(63 + s * 44, -74), Color(1, 1, 1, 0.8), 1.6)
		Art.line(self, Vector2(63 + s * 20, -66), Vector2(63 + s * 44, -64), Color(1, 1, 1, 0.8), 1.6)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
