class_name Shockwave extends Node2D
## คลื่นกระแทกวิ่งไปตามพื้น (ท่าคำรามของบอส) — ต้องกระโดดข้าม

var dir := 1
var speed := 430.0
var dmg := 14.0
var life := 2.6
var _t := 0.0


func _ready() -> void:
	z_index = 15


func _physics_process(delta: float) -> void:
	_t += delta
	position.x += dir * speed * delta
	queue_redraw()
	var p := Game.player
	if p and Rect2(global_position + Vector2(-24, -46), Vector2(48, 46)).intersects(p.get_hurt_rect()):
		p.take_damage(dmg, global_position.x - dir * 10.0)
	if _t >= life:
		queue_free()


func _draw() -> void:
	var a := clampf((life - _t) * 2.0, 0.0, 1.0)
	var wob := sin(_t * 20.0) * 4.0
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(dir, 1))
	draw_colored_polygon(PackedVector2Array([Vector2(-26, 0), Vector2(-10, -50 + wob), Vector2(8, -24), Vector2(22, -44 - wob), Vector2(26, 0)]), Color(1.0, 0.75, 0.2, 0.85 * a))
	draw_colored_polygon(PackedVector2Array([Vector2(-16, 0), Vector2(-4, -28 + wob), Vector2(14, -22), Vector2(16, 0)]), Color(1.0, 0.95, 0.7, 0.9 * a))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
