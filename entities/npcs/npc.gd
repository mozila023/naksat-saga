class_name Npc extends Interactable
## ชาวบ้านที่คุยด้วยได้ — on_talk คือฟังก์ชันที่ถูกเรียกเมื่อผู้เล่นกดคุย

var outfit := {}
var on_talk := Callable()
var has_quest_mark := Callable()  # คืน true เมื่อควรแสดงเครื่องหมาย ! เหนือหัว
var _visual: ChibiVisual
var _t := 0.0


func _ready() -> void:
	prompt = "กด ↑ เพื่อคุย"
	label_height = 112.0
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
		var y := -label_height - 84.0 + sin(_t * 4.0) * 5.0
		Art.blob(self, Vector2(0, y), 13.0, 13.0, Color(1.0, 0.86, 0.25))
		Art.rrect(self, Rect2(-2.5, y - 8, 5, 10), Art.INK, 2.5)
		Art.circle(self, Vector2(0, y + 6), 2.6, Art.INK)
