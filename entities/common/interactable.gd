class_name Interactable extends Node2D
## ของที่ผู้เล่นเดินไปกด W / ↑ ใส่ได้ (ชาวบ้าน, ประตูวาร์ป)

var prompt := "กด W"
var title := ""
var reach := 80.0
var label_height := 120.0
var _prompt_label: Label
var _title_label: Label


func _ready() -> void:
	add_to_group("interactables")
	_title_label = _make_label(title, 20, Color(1, 1, 1))
	_title_label.position = Vector2(-150, 6)
	_prompt_label = _make_label(prompt, 20, Color(1, 0.95, 0.5))
	_prompt_label.position = Vector2(-150, -label_height - 34)
	_prompt_label.visible = false


func _make_label(text: String, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.custom_minimum_size = Vector2(300, 0)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0.12, 0.08, 0.05))
	l.add_theme_constant_override("outline_size", 7)
	l.z_index = 30
	add_child(l)
	return l


func is_near() -> bool:
	var p := Game.player
	if p == null or p.dead:
		return false
	return absf(p.global_position.x - global_position.x) < reach and absf(p.global_position.y - global_position.y) < 130.0


func _process(_delta: float) -> void:
	_prompt_label.visible = is_near() and not Game.in_dialogue


func interact() -> void:
	pass
