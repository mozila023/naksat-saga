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
	var white := 0.85 if _flash > 0.0 else 0.0
	var warn := state.ends_with("_tel") and int(_t * 14.0) % 2 == 0
	var orange := Color(0.96, 0.58, 0.14).lerp(Color.WHITE, white)
	if warn:
		orange = orange.lerp(Color(1, 0.25, 0.2), 0.45)
	if _phase2() and not _dead:
		orange = orange.lerp(Color(1.0, 0.3, 0.1), 0.25)
	var dark := Color(0.16, 0.1, 0.07)
	var cream := Color(1.0, 0.93, 0.8).lerp(Color.WHITE, white)
	var crouch := 0.82 if state == "pounce_tel" else 1.0 + sin(_t * 4.0) * 0.02
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(facing, crouch))

	# หาง
	var tail := PackedVector2Array([Vector2(-58, -50), Vector2(-84, -64), Vector2(-96, -92 + sin(_t * 5.0) * 8.0), Vector2(-86, -112 + sin(_t * 5.0) * 10.0)])
	draw_polyline(tail, dark, 16.0)
	draw_polyline(tail, orange, 11.0)
	# ขา
	for lx in [-48.0, -24.0, 18.0, 42.0]:
		draw_rect(Rect2(lx - 10, -30, 20, 30), dark)
		draw_rect(Rect2(lx - 8, -30, 16, 27), orange)
	# ลำตัว
	draw_rect(Rect2(-66, -84, 124, 60), dark)
	draw_rect(Rect2(-63, -81, 118, 54), orange)
	draw_rect(Rect2(-50, -42, 90, 15), cream)
	for i in 4:
		var sx := -48.0 + i * 24.0
		draw_colored_polygon(PackedVector2Array([Vector2(sx, -81), Vector2(sx + 10, -81), Vector2(sx + 5, -56)]), dark)
	# หู
	for ex in [36.0, 78.0]:
		draw_circle(Vector2(ex, -120), 14.0, dark)
		draw_circle(Vector2(ex, -120), 11.0, orange)
		draw_circle(Vector2(ex, -119), 5.0, Color(1, 0.7, 0.7))
	# หัว
	draw_circle(Vector2(57, -84), 42.0, dark)
	draw_circle(Vector2(57, -84), 39.0, orange)
	draw_circle(Vector2(64, -70), 22.0, cream)
	draw_colored_polygon(PackedVector2Array([Vector2(52, -122), Vector2(62, -122), Vector2(57, -104)]), dark)
	draw_colored_polygon(PackedVector2Array([Vector2(34, -116), Vector2(42, -119), Vector2(43, -102)]), dark)
	draw_colored_polygon(PackedVector2Array([Vector2(72, -119), Vector2(80, -116), Vector2(71, -102)]), dark)
	# ตาดุ
	draw_circle(Vector2(46, -90), 7.0, Color.WHITE)
	draw_circle(Vector2(72, -90), 7.0, Color.WHITE)
	draw_circle(Vector2(48, -89), 3.5, Color(0.8, 0.1, 0.1) if _phase2() else Color.BLACK)
	draw_circle(Vector2(74, -89), 3.5, Color(0.8, 0.1, 0.1) if _phase2() else Color.BLACK)
	draw_line(Vector2(36, -102), Vector2(54, -95), dark, 4.0)
	draw_line(Vector2(84, -102), Vector2(66, -95), dark, 4.0)
	# จมูก ปาก เขี้ยว
	draw_colored_polygon(PackedVector2Array([Vector2(58, -76), Vector2(70, -76), Vector2(64, -68)]), Color(0.9, 0.4, 0.45))
	draw_arc(Vector2(57, -66), 7.0, 0.1, PI - 0.1, 8, dark, 2.5)
	draw_arc(Vector2(71, -66), 7.0, 0.1, PI - 0.1, 8, dark, 2.5)
	draw_colored_polygon(PackedVector2Array([Vector2(52, -60), Vector2(58, -60), Vector2(55, -50)]), Color.WHITE)
	draw_colored_polygon(PackedVector2Array([Vector2(70, -60), Vector2(76, -60), Vector2(73, -50)]), Color.WHITE)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
