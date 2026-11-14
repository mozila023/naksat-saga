class_name TitleScreen extends CanvasLayer
## หน้าปกเกม: ชื่อเกม + "คลิกเพื่อเริ่มเกม" แสดงทับฉากหมู่บ้านตอนเปิดเกม
## ถ้ามีไฟล์ assets/art/title.png จะใช้เป็นภาพปกเต็มจอ ถ้าไม่มีจะจัดภาพปกจากภาพในเกม (ตัวเอก + พญาเสือ)

signal started

const COVER := "res://assets/art/title.png"

var _root: Control
var _prompt: Label
var _logo: Control
var _t := 0.0
var _done := false


func _ready() -> void:
	layer = 60
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	if ResourceLoader.exists(COVER):
		# ภาพปกแสดงเต็มภาพเสมอ (ไม่ถูกตัด) ส่วนที่เหลือของจอเติมด้วยภาพเดียวกันแบบขยายและมืดลง
		var back := TextureRect.new()
		back.texture = load(COVER)
		back.set_anchors_preset(Control.PRESET_FULL_RECT)
		back.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		back.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		back.modulate = Color(0.35, 0.3, 0.4)
		back.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_root.add_child(back)
		var cover := TextureRect.new()
		cover.texture = load(COVER)
		cover.set_anchors_preset(Control.PRESET_FULL_RECT)
		cover.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		cover.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_root.add_child(cover)
	else:
		_add_character("res://assets/art/frames/tiger_boss_roar_0.png", Vector2(300, 40), 1.5, false, Color(1, 1, 1, 0.95))
		_add_character("res://assets/art/frames/hero_tiger_attack_0.png", Vector2(-380, 90), 1.5, false, Color(1, 1, 1, 1))
		_add_character("res://assets/art/frames/hero_normal_attack_0.png", Vector2(-120, 70), 1.9, false, Color(1, 1, 1, 1))

	# ไล่เงามืดบน-ล่าง ให้ตัวหนังสืออ่านง่าย
	# (ด้านบนเป็นวงนักษัตร จึงมืดแค่เล็กน้อย ส่วนแถบกลางที่มีโลโก้มืดลงให้อ่านง่าย)
	_root.add_child(_shade(Color(0.05, 0.03, 0.12, 0.25), Color(0.05, 0.03, 0.12, 0.0), 0.0, 0.3))
	_root.add_child(_shade(Color(0.05, 0.03, 0.12, 0.5), Color(0.05, 0.03, 0.12, 0.0), 0.0, 0.22))
	_root.add_child(_shade(Color(0.05, 0.03, 0.12, 0.0), Color(0.05, 0.03, 0.12, 0.85), 0.62, 1.0))

	# โลโก้ชื่อเกม
	_logo = Control.new()
	_logo.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_logo)
	# โลโก้มุมซ้ายบน (กลางภาพเป็นวงนักษัตร มีพญานาคอยู่กลาง และตัวเอก 2 คนอยู่ล่าง ห้ามบัง)
	for t in [_text("NAKSAT SAGA", 62, Color(0.25, 0.08, 0.02), Vector2(4, 6), 0, Color.BLACK),
			_text("NAKSAT SAGA", 62, Color(1.0, 0.82, 0.25), Vector2(0, 0), 14, Color(0.35, 0.12, 0.04)),
			_text("ตำนาน 12 นักษัตร", 30, Color(1.0, 0.97, 0.85), Vector2(6, 82), 9, Color(0.35, 0.12, 0.04))]:
		t.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		_logo.add_child(t)

	_prompt = _text("คลิกเพื่อเริ่มเกม", 32, Color.WHITE, Vector2(-640, -150), 10, Color(0.2, 0.1, 0.05))
	_prompt.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt.position = Vector2(-640, -54)
	_root.add_child(_prompt)


func _text(text: String, font_size: int, color: Color, pos: Vector2, outline: int, outline_color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.size = Vector2(1280, font_size * 1.5)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", outline_color)
	l.add_theme_constant_override("outline_size", outline)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## แถบมืดจาง ๆ กลางจอ (ขอบบนล่างค่อย ๆ จาง) ให้โลโก้อ่านง่าย
func _band(from: float, to: float) -> TextureRect:
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	grad.colors = PackedColorArray([Color(0.05, 0.03, 0.12, 0.0), Color(0.05, 0.03, 0.12, 0.45), Color(0.05, 0.03, 0.12, 0.0)])
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill_from = Vector2(0, 0)
	tex.fill_to = Vector2(0, 1)
	tex.width = 8
	tex.height = 64
	var r := TextureRect.new()
	r.texture = tex
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.anchor_top = from
	r.anchor_bottom = to
	r.offset_top = 0
	r.offset_bottom = 0
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


func _shade(top: Color, bottom: Color, from: float, to: float) -> TextureRect:
	var grad := Gradient.new()
	grad.set_color(0, top)
	grad.set_color(1, bottom)
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill_from = Vector2(0, 0)
	tex.fill_to = Vector2(0, 1)
	tex.width = 8
	tex.height = 64
	var r := TextureRect.new()
	r.texture = tex
	r.anchor_left = 0.0
	r.anchor_right = 1.0
	r.anchor_top = from
	r.anchor_bottom = to
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


func _add_character(path: String, offset: Vector2, zoom: float, flip: bool, tint: Color) -> void:
	if not ResourceLoader.exists(path):
		return
	var tex: Texture2D = load(path)
	var t := TextureRect.new()
	t.texture = tex
	t.flip_h = flip
	t.modulate = tint
	t.set_anchors_preset(Control.PRESET_CENTER)
	t.size = tex.get_size() * zoom
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.position = offset - t.size * 0.5
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(t)


func _process(delta: float) -> void:
	_t += delta
	_prompt.modulate.a = 0.55 + 0.45 * sin(_t * 4.0)
	# ภาพปกขยายเต็มจอแบบครอบ (จอแต่ละแบบสัดส่วนต่างกัน) ให้โลโก้ขยาย/เลื่อนตามภาพ จะได้อยู่ใต้วงนักษัตรเสมอ
	var vs := _root.get_viewport_rect().size
	var sc := minf(vs.x / 1280.0, vs.y / 715.0)
	var top := (vs.y - 715.0 * sc) * 0.5
	var left := (vs.x - 1280.0 * sc) * 0.5
	var bob := sin(_t * 1.6) * 4.0
	if top > 160.0:
		# จอแนวตั้ง: ภาพปกเป็นแถบกลางจอ วางโลโก้ไว้เหนือภาพ ตรงกลาง
		var big := minf(1.3, (vs.x - 40.0) / 480.0)
		_logo.scale = Vector2(big, big)
		_logo.position = Vector2((vs.x - 470.0 * big) * 0.5, top - 140.0 * big + bob)
	else:
		# มุมซ้ายบนของภาพปก
		_logo.scale = Vector2(sc, sc)
		_logo.position = Vector2(left + 26.0 * sc, top + 12.0 * sc + bob * sc)


func _input(event: InputEvent) -> void:
	if _done or _t < 0.4:
		return
	var click: bool = event is InputEventMouseButton and event.pressed
	var touch: bool = event is InputEventScreenTouch and event.pressed
	var key: bool = event is InputEventKey and event.pressed and not event.echo
	if click or touch or key:
		get_viewport().set_input_as_handled()
		begin()


## ปิดหน้าปกแล้วเริ่มเกม
func begin() -> void:
	if _done:
		return
	_done = true
	started.emit()
	var tw := create_tween()
	tw.tween_property(_root, "modulate:a", 0.0, 0.45)
	tw.tween_callback(queue_free)
