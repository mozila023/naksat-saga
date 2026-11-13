class_name Npc extends Interactable
## ชาวบ้านที่คุยด้วยได้ — on_talk คือฟังก์ชันที่ถูกเรียกเมื่อผู้เล่นกดคุย

var outfit := {}
var on_talk := Callable()
var has_quest_mark := Callable()  # คืน true เมื่อควรแสดงเครื่องหมาย ! เหนือหัว
var _visual: ChibiVisual
var _t := 0.0


func _ready() -> void:
	prompt = "กด W / ↑ เพื่อคุย"
	label_height = 100.0
	super()
	_visual = ChibiVisual.new()
	_visual.outfit = outfit
	add_child(_visual)
	move_child(_visual, 0)


func _process(delta: float) -> void:
	super(delta)
	_t += delta
	var p := Game.player
	if p:
		_visual.scale.x = 1.0 if p.global_position.x >= global_position.x else -1.0
	queue_redraw()


func interact() -> void:
	if on_talk.is_valid():
		on_talk.call()


func _draw() -> void:
	if has_quest_mark.is_valid() and has_quest_mark.call():
		var y := -132.0 + sin(_t * 4.0) * 5.0
		draw_circle(Vector2(0, y), 15.0, Color(0.2, 0.12, 0.05))
		draw_circle(Vector2(0, y), 12.5, Color(1.0, 0.85, 0.2))
		draw_rect(Rect2(-2, y - 8, 4, 10), Color(0.2, 0.12, 0.05))
		draw_rect(Rect2(-2, y + 4, 4, 4), Color(0.2, 0.12, 0.05))
