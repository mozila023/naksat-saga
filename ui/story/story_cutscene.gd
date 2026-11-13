class_name StoryCutscene extends CanvasLayer
## ฉากเล่าเรื่องก่อนเริ่มเกม แบบอนิเมะ: ภาพเต็มจอค่อย ๆ ซูม/เลื่อน + แถบดำบนล่าง + ข้อความพิมพ์ทีละตัว
## คลิก / แตะ / Space / Enter = ไปต่อ (ถ้าข้อความยังพิมพ์ไม่จบ จะแสดงทั้งหมดก่อน), ปุ่ม "ข้าม" = ข้ามทั้งหมด

signal finished

const CHARS_PER_SEC := 28.0

var gender := "boy"
var player_name := "ผู้กล้า"

var _panels: Array = []
var _index := -1
var _root: Control
var _pics: Array = []  # ภาพสองชั้นสลับกันเพื่อทำภาพจางต่อกัน
var _front := 0
var _text: Label
var _hint: Label
var _typing: Tween
var _move: Tween
var _done := false
var _t := 0.0


func _ready() -> void:
	layer = 62
	var hero := "story_4_girl" if gender == "girl" else "story_4_boy"
	_panels = [
		{"img": "story_1", "text": "นานมาแล้ว... หมู่บ้านเล็ก ๆ กลางทุ่งนาแห่งนี้ มีผู้พิทักษ์คอยปกปักรักษาอยู่เสมอ นั่นคือ วิญญาณแห่ง 12 นักษัตร", "from": Vector2(0.0, 0.0), "to": Vector2(-60.0, 10.0)},
		{"img": "story_2", "text": "แต่แล้วในคืนหนึ่ง หมอกทมิฬ ได้แผ่ปกคลุมไปทั่วทุ่งนา สัตว์ประหลาดพากันออกอาละวาด และพลังของนักษัตรทั้ง 12 ก็อ่อนแรงลง จนหลับใหลไป", "from": Vector2(-40.0, 0.0), "to": Vector2(20.0, -20.0)},
		{"img": "story_3", "text": "ผู้ใหญ่บ้าน ผู้เฝ้าหอบูชานักษัตร ได้แต่ภาวนาทุกค่ำคืน ขอให้มีใครสักคน ที่จะปลุกพลังของนักษัตรกลับคืนมา", "from": Vector2(30.0, 0.0), "to": Vector2(-30.0, -10.0)},
		{"img": hero, "text": "และแล้ว... เสียงเรียกของนักษัตรก็ดังขึ้น ในหัวใจของ %s เด็กธรรมดาแห่งหมู่บ้าน" % player_name, "from": Vector2(0.0, -10.0), "to": Vector2(-40.0, 10.0)},
		{"img": hero, "text": "การเดินทาง เพื่อพิสูจน์ตัวเองต่อนักษัตรทั้ง 12 ได้เริ่มต้นขึ้นแล้ว!", "from": Vector2(-40.0, 10.0), "to": Vector2(-80.0, 30.0), "zoom": 1.2},
	]

	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.gui_input.connect(_on_gui_input)
	add_child(_root)

	var black := ColorRect.new()
	black.color = Color.BLACK
	black.set_anchors_preset(Control.PRESET_FULL_RECT)
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(black)

	for i in 2:
		var pic := TextureRect.new()
		pic.set_anchors_preset(Control.PRESET_FULL_RECT)
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pic.modulate.a = 0.0
		_root.add_child(pic)
		_pics.append(pic)

	# แถบดำบนล่างแบบภาพยนตร์ + ไล่เงาใต้ข้อความ
	for top in [true, false]:
		var bar := ColorRect.new()
		bar.color = Color(0, 0, 0, 0.92)
		bar.anchor_left = 0.0
		bar.anchor_right = 1.0
		bar.anchor_top = 0.0 if top else 1.0
		bar.anchor_bottom = 0.0 if top else 1.0
		bar.offset_top = 0.0 if top else -150.0
		bar.offset_bottom = 54.0 if top else 0.0
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_root.add_child(bar)

	_text = Label.new()
	_text.anchor_left = 0.0
	_text.anchor_right = 1.0
	_text.anchor_top = 1.0
	_text.anchor_bottom = 1.0
	_text.offset_left = 120.0
	_text.offset_right = -120.0
	_text.offset_top = -136.0
	_text.offset_bottom = -26.0
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_text.add_theme_font_size_override("font_size", 30)
	_text.add_theme_color_override("font_color", Color(1.0, 0.97, 0.88))
	_text.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.02))
	_text.add_theme_constant_override("outline_size", 8)
	_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_text)

	_hint = Label.new()
	_hint.text = "▼"
	_hint.anchor_left = 1.0
	_hint.anchor_right = 1.0
	_hint.anchor_top = 1.0
	_hint.anchor_bottom = 1.0
	_hint.offset_left = -90.0
	_hint.offset_right = -50.0
	_hint.offset_top = -60.0
	_hint.offset_bottom = -20.0
	_hint.add_theme_font_size_override("font_size", 26)
	_hint.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_hint)

	var skip := Button.new()
	skip.text = "ข้าม  ▶▶"
	skip.focus_mode = Control.FOCUS_NONE
	skip.anchor_left = 1.0
	skip.anchor_right = 1.0
	skip.offset_left = -170.0
	skip.offset_right = -20.0
	skip.offset_top = 8.0
	skip.offset_bottom = 46.0
	skip.flat = true
	skip.add_theme_font_size_override("font_size", 22)
	for st in ["font_color", "font_hover_color", "font_pressed_color"]:
		skip.add_theme_color_override(st, Color(1, 1, 1, 0.85))
	skip.pressed.connect(skip_all)
	_root.add_child(skip)

	_next()


func _show_panel(p: Dictionary) -> void:
	var tex: Texture2D = load("res://assets/art/story/%s.png" % p["img"])
	var back: TextureRect = _pics[_front]
	var same: bool = back.texture == tex
	if not same:
		_front = 1 - _front
	var pic: TextureRect = _pics[_front]
	pic.texture = tex
	# ภาพจางเข้า (ภาพเดิมจางออก)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(pic, "modulate:a", 1.0, 0.8)
	if not same:
		tw.tween_property(_pics[1 - _front], "modulate:a", 0.0, 0.8)
	# ซูมและเลื่อนช้า ๆ (Ken Burns)
	var zoom: float = p.get("zoom", 1.1)
	pic.pivot_offset = get_viewport().get_visible_rect().size * 0.5
	if not same:
		pic.scale = Vector2.ONE * 1.02
		pic.position = p["from"]
	if _move:
		_move.kill()
	_move = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_move.tween_property(pic, "scale", Vector2.ONE * zoom, 9.0)
	_move.tween_property(pic, "position", p["to"], 9.0)


func _next() -> void:
	if _done:
		return
	_index += 1
	if _index >= _panels.size():
		_finish()
		return
	var p: Dictionary = _panels[_index]
	_show_panel(p)
	_text.text = p["text"]
	_text.visible_ratio = 0.0
	if _typing:
		_typing.kill()
	_typing = create_tween()
	_typing.tween_interval(0.5)
	_typing.tween_property(_text, "visible_ratio", 1.0, maxf(1.0, _text.text.length() / CHARS_PER_SEC))


func _advance() -> void:
	if _done:
		return
	if _text.visible_ratio < 1.0:
		# กดตอนกำลังพิมพ์ = แสดงข้อความทั้งหมดทันที
		if _typing:
			_typing.kill()
		_text.visible_ratio = 1.0
		return
	Sound.play("ui")
	_next()


func skip_all() -> void:
	_finish()


func _finish() -> void:
	if _done:
		return
	_done = true
	finished.emit()
	var tw := create_tween()
	tw.tween_property(_root, "modulate:a", 0.0, 0.6)
	tw.tween_callback(queue_free)


func _process(delta: float) -> void:
	_t += delta
	_hint.visible = _text.visible_ratio >= 1.0 and not _done
	_hint.offset_top = -60.0 + sin(_t * 5.0) * 4.0


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_advance()
	elif event is InputEventScreenTouch and event.pressed:
		_advance()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER, KEY_C, KEY_UP]:
			_advance()
		elif event.physical_keycode == KEY_ESCAPE:
			skip_all()
