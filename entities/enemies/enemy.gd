class_name Enemy extends CharacterBody2D
## มอนสเตอร์ธรรมดา: เดินวนในเขตของตัวเอง เห็นผู้เล่นใกล้ ๆ จะวิ่งเข้าหา ชนแล้วเจ็บ

const GRAVITY := 1800.0
const KINDS := {
	"frog": {"name": "กบนา", "hp": 32.0, "dmg": 8.0, "speed": 75.0, "size": Vector2(58, 48), "sprite": "res://assets/art/frog.png"},
	"mushroom": {"name": "เห็ดพิษ", "hp": 75.0, "dmg": 13.0, "speed": 55.0, "size": Vector2(56, 72), "sprite": "res://assets/art/mushroom.png"},
}

var kind := "frog"
var home_x := 0.0
var roam := 200.0
var hp := 30.0
var max_hp := 30.0
var facing := -1

var _stats := {}
var _dir := -1
var _stun := 0.0
var _flash := 0.0
var _dying := false
var _hop_t := 0.0
var _t := 0.0
var _sprite: Sprite2D


func _init() -> void:
	collision_layer = 4
	collision_mask = 1 | 8
	z_index = 5


func _ready() -> void:
	add_to_group("enemies")
	_stats = KINDS[kind]
	max_hp = _stats["hp"]
	hp = max_hp
	home_x = global_position.x
	_dir = -1 if randf() < 0.5 else 1
	_t = randf() * 10.0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = _stats["size"]
	shape.shape = rect
	shape.position = Vector2(0, -rect.size.y * 0.5)
	add_child(shape)
	var tex: Texture2D = load(_stats["sprite"])
	_sprite = Sprite2D.new()
	_sprite.texture = tex
	_sprite.centered = false
	_sprite.offset = Vector2(-tex.get_width() * 0.5, -tex.get_height())
	_sprite.position = Vector2(0, 3)
	add_child(_sprite)


func is_alive() -> bool:
	return not _dying


func get_hurt_rect() -> Rect2:
	var s: Vector2 = _stats["size"]
	return Rect2(global_position + Vector2(-s.x * 0.5, -s.y), s)


func _physics_process(delta: float) -> void:
	_t += delta
	_flash = maxf(_flash - delta, 0.0)
	queue_redraw()
	if not is_on_floor():
		velocity.y = minf(velocity.y + GRAVITY * delta, 1400.0)

	if _dying:
		velocity.x = move_toward(velocity.x, 0.0, 500.0 * delta)
		modulate.a -= delta * 2.5
		if modulate.a <= 0.0:
			queue_free()
		move_and_slide()
		return

	if _stun > 0.0:
		_stun -= delta
		velocity.x = move_toward(velocity.x, 0.0, 700.0 * delta)
		move_and_slide()
		return

	var p := Game.player
	var speed: float = _stats["speed"]
	var chasing := false
	if p and not p.dead:
		var dx := p.global_position.x - global_position.x
		var dy := p.global_position.y - global_position.y
		if absf(dx) < 330.0 and absf(dy) < 110.0:
			chasing = true
			_dir = 1 if dx > 0.0 else -1
			speed *= 1.6
		if get_hurt_rect().intersects(p.get_hurt_rect()):
			p.take_damage(_stats["dmg"], global_position.x)

	# ไม่เดินออกนอกเขตของตัวเอง (จะได้ไม่ตกแท่น)
	var next_x := global_position.x + _dir * speed * delta
	if next_x < home_x - roam or next_x > home_x + roam:
		if chasing:
			speed = 0.0
		else:
			_dir = -_dir
	if is_on_wall() and not chasing:
		_dir = -_dir
	facing = _dir
	velocity.x = _dir * speed

	if kind == "frog":
		_hop_t -= delta
		if is_on_floor() and _hop_t <= 0.0 and speed > 0.0:
			velocity.y = -330.0
			_hop_t = randf_range(0.7, 1.2)
	move_and_slide()


func take_hit(dmg: float, dir: float, stun: float) -> void:
	if _dying:
		return
	hp -= dmg
	_flash = 0.15
	_stun = maxf(_stun, maxf(0.28, stun))
	velocity = Vector2(dir * 230.0, -170.0)
	Game.spawn_number(global_position + Vector2(0, -_stats["size"].y), str(int(dmg)), Color(1, 0.95, 0.5))
	if hp <= 0.0:
		_dying = true
		remove_from_group("enemies")
		Game.on_enemy_killed(kind)


func _draw() -> void:
	modulate = Color(2.2, 2.2, 2.2, modulate.a) if _flash > 0.0 else Color(1, 1, 1, modulate.a)
	# ยืดหดตามจังหวะกระโดด ให้ดูนุ่ม (ภาพต้นฉบับหันซ้าย)
	var stretch := clampf(-velocity.y / 900.0, -0.18, 0.22)
	var breathe := sin(_t * 5.0) * 0.03
	_sprite.flip_h = facing > 0
	_sprite.scale = Vector2(0.5 * (1.0 - stretch * 0.6), 0.5 * (1.0 + stretch + breathe))
	_sprite.rotation = sin(_t * 9.0) * 0.05 if kind == "mushroom" and absf(velocity.x) > 5.0 else 0.0
	Art.shadow(self, Vector2(0, 2), 28.0)

	# หลอดเลือด (แสดงเมื่อโดนตีแล้ว)
	if hp < max_hp and not _dying:
		var top_y: float = -_stats["size"].y - 30.0
		Art.rrect(self, Rect2(-26, top_y, 52, 9), Color(0.2, 0.12, 0.1, 0.85), 4.5)
		Art.rrect(self, Rect2(-24, top_y + 2, 48.0 * clampf(hp / max_hp, 0.0, 1.0), 5), Color(0.98, 0.4, 0.4), 2.5)
	if _stun > 0.5:
		for i in 3:
			var a := _t * 6.0 + i * TAU / 3.0
			Art.circle(self, Vector2(cos(a) * 18.0, -_stats["size"].y - 14.0 + sin(a) * 5.0), 4.0, Color(1, 0.92, 0.3))
