class_name Player extends CharacterBody2D
## ตัวเอก: เดิน กระโดด ตี ใช้สกิล 3 ช่อง และสลับร่าง

const SPEED := 280.0
const RUN_MULT := 1.6  # กด Shift ค้างเพื่อวิ่งไว
const ACCEL := 3200.0
const JUMP_VELOCITY := -660.0
const GRAVITY := 1800.0
const BASE_ATK := 10.0
const ATTACK_COOLDOWN := 0.36
const SWING_TIME := 0.22

var facing := 1
var dead := false
var visual: ChibiVisual
var camera: Camera2D

var _attack_cd := 0.0
var _swing_t := 0.0
var _cds := {}  # "ร่าง:ช่อง" -> วินาทีที่เหลือ
var _invuln := 0.0
var _dash_t := 0.0
var _dash_speed := 0.0
var _dash_dmg := 0.0
var _dash_hit: Array = []
var _queued: Array = []  # การตีที่รอเวลา (สกิลตีหลายครั้ง)
var _drop_t := 0.0
var _knock_t := 0.0
var _regen_wait := 0.0
var _was_on_floor := true
var _squash := 0.0  # ยุบตัวตอนลงพื้น ให้ดูนุ่ม
var _dust_t := 0.0


func _init() -> void:
	collision_layer = 2
	collision_mask = 1 | 8
	floor_snap_length = 6.0
	z_index = 10


func _ready() -> void:
	add_to_group("player")
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(32, 72)
	shape.shape = rect
	shape.position = Vector2(0, -36)
	add_child(shape)

	visual = ChibiVisual.new()
	add_child(visual)

	camera = Camera2D.new()
	camera.position = Vector2(0, -150)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 7.0
	add_child(camera)
	camera.make_current()

	Game.player = self
	Game.form_changed.connect(_apply_form)
	_apply_form()


func _apply_form() -> void:
	visual.outfit = Game.current_form()["outfit"]


func set_camera_limits(stage_width: float) -> void:
	camera.limit_left = 0
	camera.limit_right = int(stage_width)
	camera.limit_bottom = 720
	camera.limit_top = -700
	camera.reset_smoothing()


func get_hurt_rect() -> Rect2:
	return Rect2(global_position + Vector2(-17, -74), Vector2(34, 74))


func _physics_process(delta: float) -> void:
	_tick_timers(delta)
	if dead:
		velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
		velocity.y = minf(velocity.y + GRAVITY * delta, 1400.0)
		move_and_slide()
		return

	var form := Game.current_form()
	var locked := Game.in_dialogue
	if not is_on_floor():
		velocity.y = minf(velocity.y + GRAVITY * delta, 1400.0)

	var dir := 0.0
	if not locked:
		dir = Input.get_axis("move_left", "move_right")

	if _dash_t > 0.0:
		velocity.x = _dash_speed
	elif _knock_t > 0.0:
		velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
	else:
		var running := not locked and Input.is_action_pressed("run")
		var target := dir * SPEED * float(form["speed"]) * (RUN_MULT if running else 1.0)
		velocity.x = move_toward(velocity.x, target, ACCEL * delta)
		if dir != 0.0:
			facing = 1 if dir > 0.0 else -1
		visual.running = running and dir != 0.0
		# ฝุ่นตอนวิ่งไว
		_dust_t -= delta
		if visual.running and is_on_floor() and _dust_t <= 0.0:
			_dust_t = 0.16
			Fx.spawn(get_parent(), global_position + Vector2(-facing * 14, -4), "puff", Vector2(12, 5), Color(1, 1, 1, 0.5), facing, 0.3)

	if not locked and _dash_t <= 0.0:
		if Input.is_action_just_pressed("jump") and is_on_floor():
			if Input.is_action_pressed("move_down"):
				# ลงจากแท่นลอย
				_drop_t = 0.25
				set_collision_mask_value(4, false)
			else:
				velocity.y = JUMP_VELOCITY * float(form["jump"])
		if Input.is_action_pressed("attack"):
			_basic_attack()
		for i in 3:
			if Input.is_action_just_pressed("skill_%d" % (i + 1)):
				use_skill(i)
		if Input.is_action_just_pressed("form_next"):
			cycle_form(1)
		if Input.is_action_just_pressed("form_prev"):
			cycle_form(-1)
		if Input.is_action_just_pressed("interact"):
			_interact()

	move_and_slide()
	_process_dash_hits()
	_process_queued(delta)

	if is_on_floor() and not _was_on_floor:
		_squash = 1.0
		Fx.spawn(get_parent(), global_position + Vector2(0, -4), "puff", Vector2(16, 5), Color(1, 1, 1, 0.45), facing, 0.25)
	_was_on_floor = is_on_floor()
	_squash = move_toward(_squash, 0.0, delta * 6.0)
	var stretch := clampf(absf(velocity.y) / 1600.0, 0.0, 0.14) if not is_on_floor() else 0.0
	visual.scale = Vector2(facing * (1.0 + _squash * 0.16 - stretch), 1.0 - _squash * 0.16 + stretch)
	visual.moving = absf(velocity.x) > 10.0 and is_on_floor()
	visual.in_air = not is_on_floor()
	visual.swing = 1.0 - _swing_t / SWING_TIME if _swing_t > 0.0 else -1.0
	visual.modulate.a = 0.45 if _invuln > 0.0 and int(_invuln * 16.0) % 2 == 0 else 1.0


func _tick_timers(delta: float) -> void:
	_attack_cd = maxf(_attack_cd - delta, 0.0)
	_swing_t = maxf(_swing_t - delta, 0.0)
	_invuln = maxf(_invuln - delta, 0.0)
	_knock_t = maxf(_knock_t - delta, 0.0)
	if _dash_t > 0.0:
		_dash_t = maxf(_dash_t - delta, 0.0)
	if _drop_t > 0.0:
		_drop_t -= delta
		if _drop_t <= 0.0:
			set_collision_mask_value(4, true)
	for key in _cds:
		_cds[key] = maxf(_cds[key] - delta, 0.0)
	# ฟื้นเลือดช้า ๆ เมื่อไม่โดนตีสักพัก
	if not dead and Game.hp < Game.max_hp:
		_regen_wait -= delta
		if _regen_wait <= 0.0:
			Game.set_hp(Game.hp + 4.0 * delta)


# ---------- โจมตี ----------

func _damage(mult: float) -> float:
	return BASE_ATK * float(Game.current_form()["atk"]) * mult * randf_range(0.9, 1.1)


func _basic_attack() -> void:
	if _attack_cd > 0.0:
		return
	_attack_cd = ATTACK_COOLDOWN
	_swing_t = SWING_TIME
	_melee(95.0, 90.0, 1.0, "slash", Color(1, 1, 1, 0.9))


func _melee(w: float, h: float, mult: float, fx_kind: String, color: Color) -> void:
	var x0 := global_position.x if facing > 0 else global_position.x - w
	var rect := Rect2(Vector2(x0, global_position.y - 40.0 - h * 0.5), Vector2(w, h))
	Fx.spawn(get_parent(), global_position + Vector2(facing * 14, -40), fx_kind, Vector2(w, h), color, facing)
	Game.hit_enemies(rect, _damage(mult), global_position.x)


func use_skill(index: int) -> void:
	var form := Game.current_form()
	var key := "%s:%d" % [form["id"], index]
	if _cds.get(key, 0.0) > 0.0:
		return
	var spec: Dictionary = form["skills"][index]
	_cds[key] = float(spec["cd"])
	var color: Color = form["outfit"]["shirt"].lerp(Color(1, 0.9, 0.4), 0.5)
	match spec["kind"]:
		"melee":
			for i in int(spec["hits"]):
				_queued.append({"t": i * float(spec["interval"]), "spec": spec, "color": color})
		"dash":
			_dash_t = float(spec["time"])
			_dash_speed = float(spec["speed"]) * facing
			_dash_dmg = float(spec["dmg"])
			_dash_hit = []
			if float(spec["jump"]) != 0.0:
				velocity.y = float(spec["jump"])
			if spec["invuln"]:
				_invuln = maxf(_invuln, _dash_t + 0.1)
			Fx.spawn(get_parent(), global_position + Vector2(0, -36), "puff", Vector2(40, 10), Color(1, 1, 1, 0.7), facing, 0.3)
		"aoe":
			var r := float(spec["radius"])
			_swing_t = SWING_TIME
			var rect := Rect2(global_position + Vector2(-r, -40.0 - r * 0.7), Vector2(r * 2.0, r * 1.4))
			Fx.spawn(get_parent(), global_position + Vector2(0, -40), "ring", Vector2(r, r), color, facing, 0.4)
			Game.hit_enemies(rect, _damage(float(spec["dmg"])), global_position.x, float(spec["stun"]))


func _process_queued(delta: float) -> void:
	if _queued.is_empty():
		return
	var remaining: Array = []
	for q in _queued:
		q["t"] -= delta
		if q["t"] <= 0.0:
			var spec: Dictionary = q["spec"]
			_swing_t = SWING_TIME
			_melee(float(spec["w"]), float(spec["h"]), float(spec["dmg"]), spec["fx"], q["color"])
		else:
			remaining.append(q)
	_queued = remaining


func _process_dash_hits() -> void:
	if _dash_t > 0.0 and _dash_dmg > 0.0:
		var rect := get_hurt_rect().grow(18.0)
		Game.hit_enemies(rect, _damage(_dash_dmg), global_position.x - facing * 10.0, 0.0, _dash_hit)


func get_cd(index: int) -> float:
	return _cds.get("%s:%d" % [Game.form_id, index], 0.0)


# ---------- สลับร่าง ----------

func cycle_form(step: int) -> void:
	var ids: Array = []
	for f in Forms.LIST:
		if f["id"] in Game.unlocked:
			ids.append(f["id"])
	if ids.size() <= 1:
		Game.banner.emit("ยังไม่มีร่างอื่น — ปราบบอสนักษัตรเพื่อปลดล็อกร่างใหม่")
		return
	var i := ids.find(Game.form_id)
	Game.set_form(ids[posmod(i + step, ids.size())])
	Fx.spawn(get_parent(), global_position + Vector2(0, -40), "ring", Vector2(70, 70), Game.current_form()["outfit"]["shirt"], 1, 0.35)


# ---------- คุย / เข้าประตู ----------

func _interact() -> void:
	var best: Node = null
	var best_d := INF
	for it in get_tree().get_nodes_in_group("interactables"):
		if it.is_near():
			var d := absf(it.global_position.x - global_position.x)
			if d < best_d:
				best_d = d
				best = it
	if best:
		best.interact()


# ---------- โดนตี ----------

func take_damage(amount: float, from_x: float) -> void:
	if dead or _invuln > 0.0 or Game.in_dialogue:
		return
	Game.set_hp(Game.hp - amount)
	Game.spawn_number(global_position + Vector2(0, -80), str(int(amount)), Color(1, 0.35, 0.35))
	_invuln = 0.9
	_knock_t = 0.22
	_regen_wait = 5.0
	_dash_t = 0.0
	velocity = Vector2(signf(global_position.x - from_x) * 260.0, -280.0)
	if Game.hp <= 0.0:
		dead = true
		Game.player_died()


func revive() -> void:
	dead = false
	_invuln = 1.5
	_queued.clear()
	velocity = Vector2.ZERO
	Game.set_hp(Game.max_hp)
