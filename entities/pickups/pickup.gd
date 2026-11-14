class_name Pickup extends Node2D
## ของที่ตกบนพื้น (เหรียญ / ไอเทม): เด้งออกจากศัตรู ตกลงพื้น แล้วลอยเข้าหาผู้เล่นเมื่อเดินมาใกล้

var kind := "coin"  # "coin" หรือรหัสไอเทมใน Game.ITEMS
var value := 1
var _vel := Vector2.ZERO
var _floor_y := 0.0
var _landed := false
var _t := 0.0
var _sprite: Sprite2D


static func spawn(parent: Node, pos: Vector2, item_kind: String, amount := 1) -> void:
	var p := Pickup.new()
	p.kind = item_kind
	p.value = amount
	parent.add_child(p)
	p.global_position = pos + Vector2(0, -24)
	p._floor_y = pos.y - 2.0
	p._vel = Vector2(randf_range(-150, 150), randf_range(-430, -260))


func _ready() -> void:
	add_to_group("pickups")
	z_index = 8
	var icon: String = "coin" if kind == "coin" else Game.ITEMS[kind]["icon"]
	_sprite = Sprite2D.new()
	_sprite.texture = load("res://assets/art/items/item_%s.png" % icon)
	_sprite.scale = Vector2(0.5, 0.5)
	_sprite.position = Vector2(0, -16)
	add_child(_sprite)


func _physics_process(delta: float) -> void:
	_t += delta
	if not _landed:
		_vel.y += 1500.0 * delta
		position += _vel * delta
		if global_position.y >= _floor_y and _vel.y > 0.0:
			global_position.y = _floor_y
			if _vel.y > 160.0:
				_vel = Vector2(_vel.x * 0.5, -_vel.y * 0.4)
			else:
				_landed = true
				queue_redraw()  # เงาใต้ของ (วาดครั้งเดียวตอนตกถึงพื้น)
	else:
		_sprite.position.y = -16.0 + sin(_t * 4.0) * 3.0

	var p := Game.player
	if _t > 0.4 and p and not p.dead:
		var d := p.global_position + Vector2(0, -40) - global_position
		if d.length() < 150.0:
			# ดูดเข้าหาผู้เล่น
			_landed = true
			global_position += d.normalized() * minf(560.0 * delta, d.length())
			if d.length() < 34.0:
				_collect()
				return
	if _t > 40.0:
		queue_free()
	elif _t > 34.0:
		modulate.a = 0.4 if int(_t * 8.0) % 2 == 0 else 1.0


func _collect() -> void:
	Sound.play("coin" if kind == "coin" else "item", 0.06)
	if kind == "coin":
		Game.add_money(value)
		Game.spawn_number(global_position + Vector2(0, -30), "+%d บาท" % value, Color(1.0, 0.88, 0.3), 22)
	else:
		Game.add_item(kind, value)
		Game.spawn_number(global_position + Vector2(0, -30), "+ %s" % Game.ITEMS[kind]["name"], Color(0.7, 1.0, 0.75), 22)
	Fx.spawn(get_parent(), global_position + Vector2(0, -16), "spark", Vector2(20, 20), Color(1.0, 0.95, 0.5), 1, 0.2)
	queue_free()


func _draw() -> void:
	if _landed:
		Art.shadow(self, Vector2(0, 2), 13.0)
