class_name CharacterCreate extends CanvasLayer
## สร้างตัวละครหลังกดเริ่มเกม: ขั้นที่ 1 เลือกเพศ (ชาย / หญิง) -> ขั้นที่ 2 ตั้งชื่อ
## เสร็จแล้วส่ง finished(gender, name)

signal finished(gender: String, player_name: String)

const INK := Color(0.2, 0.1, 0.05)
const MAX_NAME := 12

var _root: Control
var _gender_page: Control
var _name_page: Control
var _cards := {}
var _gender := "boy"
var _name_edit: LineEdit
var _ok_button: Button
var _preview: TextureRect
var _t := 0.0
var _done := false


func _ready() -> void:
	layer = 61
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)

	# พื้นหลัง: ภาพปกเกมแบบมืดลง
	var bg := TextureRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	if ResourceLoader.exists("res://assets/art/title.png"):
		bg.texture = load("res://assets/art/title.png")
	bg.modulate = Color(0.35, 0.3, 0.45)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(bg)

	_build_gender_page()
	_build_name_page()
	_show_page(_gender_page)
	_select("boy")


# ---------- ตัวช่วย ----------

func _box(color: Color, radius := 18, border := Color(0.25, 0.12, 0.05)) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(radius)
	sb.set_border_width_all(4)
	sb.border_color = border
	return sb


func _label(text: String, font_size: int, color: Color, outline := 0) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	if outline > 0:
		l.add_theme_color_override("font_outline_color", INK)
		l.add_theme_constant_override("outline_size", outline)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _button(text: String, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 28)
	b.add_theme_stylebox_override("normal", _box(Color(1.0, 0.82, 0.35), 16))
	b.add_theme_stylebox_override("hover", _box(Color(1.0, 0.9, 0.5), 16))
	b.add_theme_stylebox_override("pressed", _box(Color(0.95, 0.72, 0.25), 16))
	b.add_theme_stylebox_override("disabled", _box(Color(0.7, 0.66, 0.6), 16))
	for st in ["font_color", "font_hover_color", "font_pressed_color"]:
		b.add_theme_color_override(st, INK)
	b.add_theme_color_override("font_disabled_color", Color(0.45, 0.4, 0.35))
	b.pressed.connect(on_press)
	return b


func _center_page() -> Control:
	var page := Control.new()
	page.set_anchors_preset(Control.PRESET_CENTER)
	page.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(page)
	return page


func _show_page(page: Control) -> void:
	for p in [_gender_page, _name_page]:
		p.visible = p == page
	page.modulate.a = 0.0
	create_tween().tween_property(page, "modulate:a", 1.0, 0.3)


# ---------- ขั้นที่ 1: เลือกเพศ ----------

func _build_gender_page() -> void:
	_gender_page = _center_page()
	var title := _label("เลือกตัวละคร", 52, Color(1.0, 0.85, 0.35), 14)
	title.position = Vector2(-400, -320)
	title.size = Vector2(800, 70)
	_gender_page.add_child(title)
	_add_card("boy", "ชาย", "res://assets/art/hero_normal.png", Vector2(-330, -220))
	_add_card("girl", "หญิง", "res://assets/art/heroine_normal.png", Vector2(30, -220))
	var next := _button("ถัดไป  ▶", _to_name_page)
	next.position = Vector2(-110, 230)
	next.size = Vector2(220, 64)
	_gender_page.add_child(next)


func _add_card(gender: String, text: String, sprite: String, pos: Vector2) -> void:
	var card := Panel.new()
	card.position = pos
	card.size = Vector2(300, 420)
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			_select(gender)
			if ev.double_click:
				_to_name_page())
	_gender_page.add_child(card)
	var pic := TextureRect.new()
	pic.texture = load(sprite)
	pic.position = Vector2(30, 24)
	pic.size = Vector2(240, 300)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(pic)
	var l := _label(text, 40, INK)
	l.position = Vector2(0, 340)
	l.size = Vector2(300, 60)
	card.add_child(l)
	_cards[gender] = {"panel": card, "pic": pic}


func _select(gender: String) -> void:
	_gender = gender
	Sound.play("ui")
	for g in _cards:
		var on: bool = g == gender
		var panel: Panel = _cards[g]["panel"]
		panel.add_theme_stylebox_override("panel", _box(Color(1.0, 0.95, 0.8) if on else Color(0.75, 0.72, 0.8, 0.85), 24, Color(1.0, 0.75, 0.2) if on else Color(0.25, 0.12, 0.05)))
		panel.scale = Vector2.ONE * (1.04 if on else 0.96)
		panel.pivot_offset = panel.size * 0.5
		_cards[g]["pic"].modulate = Color.WHITE if on else Color(0.6, 0.6, 0.65)


# ---------- ขั้นที่ 2: ตั้งชื่อ ----------

func _build_name_page() -> void:
	_name_page = _center_page()
	var title := _label("ตั้งชื่อตัวละคร", 52, Color(1.0, 0.85, 0.35), 14)
	title.position = Vector2(-400, -300)
	title.size = Vector2(800, 70)
	_name_page.add_child(title)

	var frame := Panel.new()
	frame.add_theme_stylebox_override("panel", _box(Color(1.0, 0.95, 0.8), 24, Color(1.0, 0.75, 0.2)))
	frame.position = Vector2(-120, -210)
	frame.size = Vector2(240, 280)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_name_page.add_child(frame)
	_preview = TextureRect.new()
	_preview.position = Vector2(20, 14)
	_preview.size = Vector2(200, 252)
	_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(_preview)

	_name_edit = LineEdit.new()
	_name_edit.position = Vector2(-260, 100)
	_name_edit.size = Vector2(520, 70)
	_name_edit.max_length = MAX_NAME
	_name_edit.placeholder_text = "พิมพ์ชื่อที่นี่"
	_name_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_edit.add_theme_font_size_override("font_size", 34)
	_name_edit.add_theme_stylebox_override("normal", _box(Color(1, 1, 1), 16))
	_name_edit.add_theme_stylebox_override("focus", _box(Color(1, 1, 1), 16, Color(1.0, 0.65, 0.15)))
	_name_edit.add_theme_color_override("font_color", INK)
	_name_edit.add_theme_color_override("font_placeholder_color", Color(0.6, 0.55, 0.5))
	_name_edit.add_theme_color_override("caret_color", INK)
	_name_edit.text_changed.connect(func(_t2: String) -> void: _refresh_ok())
	_name_edit.text_submitted.connect(func(_t2: String) -> void: _confirm())
	_name_page.add_child(_name_edit)

	var back := _button("◀  ย้อนกลับ", func() -> void: _show_page(_gender_page))
	back.position = Vector2(-280, 200)
	back.size = Vector2(240, 64)
	_name_page.add_child(back)
	_ok_button = _button("เริ่มการผจญภัย", _confirm)
	_ok_button.position = Vector2(20, 200)
	_ok_button.size = Vector2(260, 64)
	_name_page.add_child(_ok_button)
	_refresh_ok()


func _to_name_page() -> void:
	_preview.texture = load("res://assets/art/%s.png" % ("heroine_normal" if _gender == "girl" else "hero_normal"))
	_show_page(_name_page)
	_name_edit.grab_focus()
	Sound.play("ui")


func _clean_name() -> String:
	return _name_edit.text.strip_edges()


func _refresh_ok() -> void:
	_ok_button.disabled = _clean_name() == ""


func _confirm() -> void:
	if _done or _clean_name() == "":
		return
	_done = true
	Sound.play("quest")
	finished.emit(_gender, _clean_name())
	var tw := create_tween()
	tw.tween_property(_root, "modulate:a", 0.0, 0.4)
	tw.tween_callback(queue_free)


## ใช้ในการทดสอบอัตโนมัติ
func choose(gender: String, player_name: String) -> void:
	_select(gender)
	_to_name_page()
	_name_edit.text = player_name
	_refresh_ok()
	_confirm()


func _process(delta: float) -> void:
	_t += delta
	# ตัวละครที่เลือกเด้งเบา ๆ
	for g in _cards:
		_cards[g]["pic"].position.y = 24.0 + (sin(_t * 4.0) * 6.0 if g == _gender else 0.0)


func _unhandled_input(event: InputEvent) -> void:
	if _done or not _gender_page.visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_LEFT, KEY_A:
				_select("boy")
			KEY_RIGHT, KEY_D:
				_select("girl")
			KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_C:
				_to_name_page()
