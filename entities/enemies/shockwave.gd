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
	Art.glow(self, Vector2(0, -20), 46.0, Color(1.0, 0.7, 0.2, 0.8 * a))
	# เปลวคลื่น 3 ชั้น
	Art.leaf(self, Vector2(-22, 0), Vector2(-20, -40), Vector2(6, -58 + wob), 13.0, Color(1.0, 0.55, 0.15, 0.9 * a), Color(1, 0.8, 0.4, a))
	Art.leaf(self, Vector2(-4, 0), Vector2(0, -30), Vector2(22, -46 - wob), 12.0, Color(1.0, 0.72, 0.2, 0.95 * a), Color(1, 0.9, 0.6, a))
	Art.leaf(self, Vector2(8, 0), Vector2(12, -18), Vector2(28, -28 + wob), 9.0, Color(1.0, 0.92, 0.6, a), Color(1, 1, 1, a))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
