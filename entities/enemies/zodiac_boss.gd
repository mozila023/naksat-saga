class_name ZodiacBoss extends CharacterBody2D
## บอส: นักษัตรตอนประลอง (ค่าจาก Zodiac.LIST[...]["boss"]) และปิศาจ (ค่าจาก DEMONS)
## ท่า: ตะปบ / กระโจนทับ / คำรามปล่อยคลื่น (เมื่อเลือดต่ำกว่าครึ่ง) — มีวงเวทเตือนบนพื้นก่อนทุกท่า

const GRAVITY := 1800.0

var zodiac_id := "tiger"
var boss_name := ""
var max_hp := 650.0
var SIZE := Vector2(170, 118)
var cfg := {}
var hp := 650.0
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
var _angry := false
var _pulse := 0.0
var _tex := {}       # ชื่อท่า -> ภาพ (ภาพวาดทีละท่า)
var _hold := ""      # ท่าที่ค้างไว้ชั่วครู่หลังโจมตี (ตะปบ / คำราม)
var _hold_t := 0.0
var _walk_t := 0.0


## บอสที่ไม่ใช่นักษัตร (ปิศาจ) ใช้ท่าชุดเดียวกัน ตีซ้ำได้ทุกครั้งที่เข้าแผนที่
const DEMONS := {
	"mist_giant": {"name": "ยักษ์หมอกทมิฬ", "hp": 1400.0, "size": Vector2(150, 170), "frames": "mist_giant",
		"walk": [120.0, 170.0], "tel": 1.1, "claw": 22.0, "pounce": 28.0, "contact": 14.0, "wave": 18.0,
		"reach": 260.0, "shout": "ฮ่าฮ่าฮ่า!!", "aura": Color(0.65, 0.4, 1.0)},
	"pong_khang": {"name": "ผีโป่งค่าง", "hp": 2800.0, "size": Vector2(150, 175), "frames": "pong_khang",
		"walk": [150.0, 210.0], "tel": 0.95, "claw": 32.0, "pounce": 40.0, "contact": 20.0, "wave": 30.0,
		"reach": 260.0, "shout": "แฮ่!!", "aura": Color(0.5, 0.35, 0.9)},
}


## สร้างบอสตามรหัส: นักษัตร (เช่น "rat", "tiger") หรือปิศาจใน DEMONS (เช่น "mist_giant")
static func create(id: String) -> ZodiacBoss:
	var b := ZodiacBoss.new()
	var z := Zodiac.get_data(id)
	b.zodiac_id = id
	b.cfg = z["boss"] if not z.is_empty() else DEMONS[id]
	b.boss_name = b.cfg["name"]
	b.max_hp = float(b.cfg["hp"])
	b.hp = b.max_hp
	b.SIZE = b.cfg["size"]
	return b


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
	var prefix: String = cfg.get("frames", "tiger_boss")
	var still := "res://assets/art/%s.png" % prefix
	if not ResourceLoader.exists(still):
		still = "res://assets/art/frames/%s_walk_3.png" % prefix
	var tex: Texture2D = load(still)
	_sprite = Sprite2D.new()
	_sprite.texture = tex
	_sprite.centered = false
	_sprite.offset = Vector2(-tex.get_width() * 0.5, -tex.get_height())
	_sprite.position = Vector2(0, 4)
	add_child(_sprite)
	var poses := ["walk_0", "walk_1", "walk_2", "walk_3", "crouch_0", "leap_0", "swipe_0", "roar_0"]
	for pose in poses:
		var path := "res://assets/art/frames/%s_%s.png" % [prefix, pose]
		if ResourceLoader.exists(path):
			_tex[pose] = load(path)
	if _tex.size() != poses.size():
		_tex.clear()
	Game.boss = self


func is_alive() -> bool:
	return not _dead


func get_hurt_rect() -> Rect2:
	return Rect2(global_position + Vector2(-SIZE.x * 0.5, -SIZE.y), SIZE)


func _phase2() -> bool:
	return hp < max_hp * 0.5


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
			velocity.x = facing * float(cfg["walk"][1] if _phase2() else cfg["walk"][0])
			if dist < float(cfg["reach"]) - 40.0:
				_start_claw()
			elif _state_t <= 0.0:
				_set_state("idle", 0.2)
		"claw_tel":
			velocity.x = 0.0
			if _state_t <= 0.0:
				var rect := _claw_rect()
				Fx.spawn(get_parent(), global_position + Vector2(facing * 60, -70), "claw", Vector2(220, 150), Color(1, 0.3, 0.2), facing, 0.3)
				Sound.play("claw", 0.05, 2.0)
				if rect.intersects(p.get_hurt_rect()):
					p.take_damage(float(cfg["claw"]), global_position.x)
				_hold = "swipe_0"
				_hold_t = 0.4
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
				Fx.spawn(get_parent(), global_position + Vector2(0, -20), "ring", Vector2(180, 180), Color(1, 0.6, 0.2), 1, 0.4)
				Fx.spawn(get_parent(), global_position + Vector2(0, -6), "burst", Vector2(120, 14), Color(0.9, 0.85, 0.8, 0.8), 1, 0.45)
				Game.shake(11.0, 0.3)
				Sound.play("heavy_hit", 0.04, 3.0)
				if rect.intersects(p.get_hurt_rect()):
					p.take_damage(float(cfg["pounce"]), global_position.x)
				_set_state("recover", 0.6 if _phase2() else 0.9)
		"roar_tel":
			velocity.x = 0.0
			if _state_t <= 0.0:
				for i in 3:
					Fx.spawn(get_parent(), global_position + Vector2(facing * 70, -90), "ring", Vector2(140 + i * 70, 200), Color(1, 0.75, 0.25), 1, 0.4 + i * 0.15)
				Game.spawn_text(global_position + Vector2(-60, -SIZE.y - 110.0), cfg["shout"], Color(1.0, 0.75, 0.3), 56)
				Game.shake(10.0, 0.5)
				Sound.play("roar", 0.03, 2.0)
				_pulse = 1.0
				for d in [-1, 1]:
					var wave := Shockwave.new()
					wave.dir = d
					wave.dmg = float(cfg["wave"])
					get_parent().add_child(wave)
					wave.global_position = global_position + Vector2(d * 70, 0)
				_hold = "roar_0"
				_hold_t = 0.7
				_set_state("recover", 0.9)
		"recover":
			velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
			if _state_t <= 0.0:
				_set_state("idle", 0.35 if _phase2() else 0.7)

	move_and_slide()
	global_position.x = clampf(global_position.x, arena_left, arena_right)

	if _contact_cd <= 0.0 and get_hurt_rect().grow(-10.0).intersects(p.get_hurt_rect()):
		p.take_damage(float(cfg["contact"]), global_position.x)
		_contact_cd = 0.5


func _choose_action(dist: float) -> void:
	if _phase2() and randf() < 0.3:
		_set_state("roar_tel", 0.8 * float(cfg["tel"]))
		return
	if dist < float(cfg["reach"]) - 20.0:
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
	var w := float(cfg["reach"])
	var x0 := global_position.x if facing > 0 else global_position.x - w
	var h := maxf(SIZE.y + 30.0, 110.0)
	return Rect2(Vector2(x0, global_position.y - h), Vector2(w, h))


func _start_claw() -> void:
	var t := (0.38 if _phase2() else 0.5) * float(cfg["tel"])
	_set_state("claw_tel", t)
	Fx.spawn(get_parent(), _claw_rect().position, "warn", _claw_rect().size, Color(1, 0.2, 0.2), 1, t)


func _start_pounce() -> void:
	var t := (0.5 if _phase2() else 0.65) * float(cfg["tel"])
	_target_x = clampf(Game.player.global_position.x, arena_left, arena_right)
	_set_state("pounce_tel", t)
	Fx.spawn(get_parent(), Vector2(_target_x - 170.0, global_position.y - 110.0), "warn", Vector2(340, 110), Color(1, 0.5, 0.1), 1, t + 0.7)


func take_hit(dmg: float, _dir: float, _stun: float) -> void:
	if _dead:
		return
	hp -= dmg
	_flash = 0.12
	var hit_at := global_position + Vector2(randf_range(-50, 50), randf_range(-100, -30))
	Fx.spawn(get_parent(), hit_at, "spark", Vector2(44, 44), Color(1.0, 0.85, 0.35), 1, 0.22)
	if not _angry and hp > 0.0 and _phase2():
		# เข้าสู่ช่วงโกรธ
		_angry = true
		_pulse = 1.0
		Fx.spawn(get_parent(), global_position + Vector2(0, -60), "ring", Vector2(260, 260), Color(1.0, 0.3, 0.2), 1, 0.6)
		Fx.spawn(get_parent(), global_position, "pillar", Vector2(90, 320), Color(1.0, 0.3, 0.2), 1, 0.6)
		Game.spawn_text(global_position + Vector2(-70, -SIZE.y - 80.0), "เอาจริงแล้วนะ!", Color(1.0, 0.4, 0.3), 46)
		Game.shake(10.0, 0.5)
		Sound.play("roar", 0.02, 2.0)
	if Game.hit_is_crit:
		Game.spawn_number(global_position + Vector2(0, -SIZE.y - 30.0), str(int(dmg)), Color(1.0, 0.5, 0.15), 44)
	else:
		Game.spawn_number(global_position + Vector2(0, -SIZE.y - 20.0), str(int(dmg)), Color(1, 0.95, 0.5))
	if hp <= 0.0:
		hp = 0.0
		_dead = true
		remove_from_group("enemies")
		Fx.spawn(get_parent(), global_position + Vector2(0, -50), "ring", Vector2(260, 260), Color(1, 0.9, 0.5), 1, 0.7)
		for i in 5:
			var at := global_position + Vector2(randf_range(-90, 90), randf_range(-130, -20))
			Fx.spawn(get_parent(), at, "burst", Vector2(70, 16), Color(1, 1, 1, 0.9), 1, 0.4 + i * 0.12)
		Fx.spawn(get_parent(), global_position + Vector2(0, -60), "star", Vector2(120, 220), Color(1.0, 0.9, 0.4), 1, 1.2)
		Fx.spawn(get_parent(), global_position, "pillar", Vector2(100, 400), Color(1.0, 0.9, 0.5), 1, 0.9)
		Game.shake(14.0, 0.6)
		Game.hit_stop(0.25)
		Sound.play("boss_die")
		Game.on_boss_defeated(zodiac_id, global_position)


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
	# เดิน: ตัวโยกขึ้นลงตามจังหวะก้าว / คำราม-โกรธ: ตัวพองขึ้นชั่วครู่
	var step := absf(sin(_t * 11.0)) * 7.0 if state == "walk" else 0.0
	var tilt := sin(_t * 11.0) * 0.035 if state == "walk" else 0.0
	_pulse = move_toward(_pulse, 0.0, get_process_delta_time() * 3.0)
	var big := 1.0 + _pulse * 0.18
	if state == "roar_tel":
		big += 0.06 + sin(_t * 40.0) * 0.02
	if _tex.is_empty():
		_sprite.scale = Vector2(0.5 * big, 0.5 * crouch * big)
		_sprite.position = Vector2(facing * lunge, 4 - step)
		_sprite.rotation = -0.12 * facing if state == "pounce" else tilt
	else:
		# เลือกภาพตามท่า: เดิน 4 ภาพ / ย่อตัว / กระโจน / ตะปบ / คำราม
		var dt := get_process_delta_time()
		_hold_t = maxf(_hold_t - dt, 0.0)
		var pose := "walk_3"
		match state:
			"walk":
				_walk_t += dt * 8.0
				pose = "walk_%d" % (int(_walk_t) % 4)
			"pounce_tel":
				pose = "crouch_0"
			"pounce":
				pose = "leap_0"
			"claw_tel":
				pose = "crouch_0"
			"roar_tel":
				pose = "roar_0"
			_:
				if _hold_t > 0.0:
					pose = _hold
		var tex: Texture2D = _tex[pose]
		_sprite.texture = tex
		_sprite.offset = Vector2(-tex.get_width() * 0.5, -tex.get_height())
		_sprite.scale = Vector2(0.5 * big, 0.5 * big * (1.0 + sin(_t * 4.0) * 0.012))
		_sprite.position = Vector2(facing * lunge, 5)
		_sprite.rotation = 0.0
	Art.shadow(self, Vector2(0, 3), SIZE.x * 0.6)
