class_name TigerBoss extends CharacterBody2D
## บอสนักษัตรตัวแรก: พญาเสือโคร่ง (ปีขาล)
## ท่า: ตะปบ / กระโจนทับ / คำรามปล่อยคลื่น (เมื่อเลือดต่ำกว่าครึ่ง) — มีกรอบแดงเตือนก่อนทุกท่า

const GRAVITY := 1800.0
const MAX_HP := 650.0
const BOSS_NAME := "พญาเสือโคร่ง"
const SIZE := Vector2(170, 118)

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
var _sprite: Sprite2D


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
	var tex: Texture2D = load("res://assets/art/tiger_boss.png")
	_sprite = Sprite2D.new()
	_sprite.texture = tex
	_sprite.centered = false
	_sprite.offset = Vector2(-tex.get_width() * 0.5, -tex.get_height())
	_sprite.position = Vector2(0, 4)
	add_child(_sprite)
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
			if dist < 200.0:
				_start_claw()
			elif _state_t <= 0.0:
				_set_state("idle", 0.2)
		"claw_tel":
			velocity.x = 0.0
			if _state_t <= 0.0:
				var rect := _claw_rect()
				Fx.spawn(get_parent(), global_position + Vector2(facing * 60, -70), "claw", Vector2(220, 150), Color(1, 0.3, 0.2), facing, 0.3)
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
				var rect := Rect2(global_position + Vector2(-170, -110), Vector2(340, 110))
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
	if dist < 220.0:
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
	var w := 240.0
	var x0 := global_position.x if facing > 0 else global_position.x - w
	return Rect2(Vector2(x0, global_position.y - 150.0), Vector2(w, 150.0))


func _start_claw() -> void:
	var t := 0.38 if _phase2() else 0.5
	_set_state("claw_tel", t)
	Fx.spawn(get_parent(), _claw_rect().position, "warn", _claw_rect().size, Color(1, 0.2, 0.2), 1, t)


func _start_pounce() -> void:
	var t := 0.5 if _phase2() else 0.65
	_target_x = clampf(Game.player.global_position.x, arena_left, arena_right)
	_set_state("pounce_tel", t)
	Fx.spawn(get_parent(), Vector2(_target_x - 170.0, global_position.y - 110.0), "warn", Vector2(340, 110), Color(1, 0.5, 0.1), 1, t + 0.7)


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
	if warn:
		_sprite.modulate = Color(1.0, 0.55, 0.5)
	elif _phase2() and not _dead:
		_sprite.modulate = Color(1.0, 0.8, 0.74)
	else:
		_sprite.modulate = Color.WHITE
	# ภาพต้นฉบับหันซ้าย / ย่อตัวก่อนกระโจน / หายใจเบา ๆ
	var crouch := 0.84 if state == "pounce_tel" else 1.0 + sin(_t * 4.0) * 0.015
	var lunge := 14.0 if state == "recover" and _state_t > 0.3 else 0.0
	_sprite.flip_h = facing > 0
	_sprite.scale = Vector2(0.5, 0.5 * crouch)
	_sprite.position = Vector2(facing * lunge, 4)
	_sprite.rotation = -0.12 * facing if state == "pounce" else 0.0
	Art.shadow(self, Vector2(0, 3), 100.0)
