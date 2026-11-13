class_name Hud extends CanvasLayer
## หน้าจอ HUD: หลอดเลือด, ร่างปัจจุบัน, เควส, ช่องสกิล, หลอดเลือดบอส, กล่องบทสนทนา, ปุ่มสัมผัส (มือถือ)

const OUTLINE := Color(0.12, 0.08, 0.05)
const SLOT_KEYS := ["J", "U", "I", "O"]

var _root: Control
var _form_swatch: Panel
var _form_label: Label
var _hp_bar: ProgressBar
var _hp_label: Label
var _quest_label: Label
var _forms_label: Label
var _banner: Label
var _banner_tween: Tween
var _boss_box: Control
var _boss_bar: ProgressBar
var _boss_label: Label
var _slots: Array = []  # [{name: Label, overlay: ColorRect, cd: Label}]
var _dialogue: Panel
var _dlg_who: Label
var _dlg_text: Label
var _lines: Array = []
var _line_index := 0
var _dlg_delay := 0.0


func _ready() -> void:
	layer = 10
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	_build_status()
	_build_skill_bar()
	_build_boss_bar()
	_build_banner()
	_build_dialogue()
	_build_help()
	if DisplayServer.is_touchscreen_available():
		_build_touch()

	Game.hp_changed.connect(_refresh_hp)
	Game.form_changed.connect(_refresh_form)
	Game.quest_changed.connect(_refresh_quest)
	Game.banner.connect(show_banner)
	Game.dialogue_started.connect(_on_dialogue_started)
	_refresh_hp()
	_refresh_form()
	_refresh_quest()


# ---------- ตัวช่วยสร้าง UI ----------

func _box(color: Color, radius := 12) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(radius)
	sb.set_border_width_all(3)
	sb.border_color = OUTLINE
	return sb


func _label(text: String, font_size: int, color := Color.WHITE, outline := 6) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", OUTLINE)
	l.add_theme_constant_override("outline_size", outline)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _bar(fill: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.add_theme_stylebox_override("background", _box(Color(0.15, 0.1, 0.1, 0.85), 8))
	var f := _box(fill, 8)
	bar.add_theme_stylebox_override("fill", f)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return bar


# ---------- มุมซ้ายบน: ร่าง + เลือด + เควส ----------

func _build_status() -> void:
	var panel := Panel.new()
	panel.add_theme_stylebox_override("panel", _box(Color(1.0, 0.96, 0.85, 0.92)))
	panel.position = Vector2(16, 16)
	panel.size = Vector2(350, 92)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(panel)

	_form_swatch = Panel.new()
	_form_swatch.position = Vector2(12, 12)
	_form_swatch.size = Vector2(68, 68)
	_form_swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(_form_swatch)

	_form_label = _label("", 22, Color(0.3, 0.18, 0.08), 0)
	_form_label.position = Vector2(92, 6)
	panel.add_child(_form_label)

	_hp_bar = _bar(Color(0.92, 0.3, 0.3))
	_hp_bar.position = Vector2(92, 46)
	_hp_bar.size = Vector2(244, 30)
	panel.add_child(_hp_bar)

	_hp_label = _label("", 18)
	_hp_label.position = Vector2(92, 46)
	_hp_label.size = Vector2(244, 30)
	_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(_hp_label)

	_quest_label = _label("", 24, Color(1.0, 0.92, 0.55), 8)
	_quest_label.position = Vector2(20, 116)
	_root.add_child(_quest_label)


func _refresh_hp() -> void:
	_hp_bar.max_value = Game.max_hp
	_hp_bar.value = Game.hp
	_hp_label.text = "%d / %d" % [ceili(Game.hp), int(Game.max_hp)]


func _refresh_form() -> void:
	var form := Game.current_form()
	_form_swatch.add_theme_stylebox_override("panel", _box(form["outfit"]["shirt"], 34))
	_form_label.text = form["name"]
	for i in 3:
		_slots[i + 1]["name"].text = form["skills"][i]["name"]
	var names: Array = []
	for f in Forms.LIST:
		if f["id"] in Game.unlocked:
			names.append(("[%s]" if f["id"] == Game.form_id else "%s") % f["short"])
	_forms_label.text = "Q ◀  %s  ▶ E      ร่างที่ปลดล็อก %d/14" % ["  ".join(names), Game.unlocked.size()]


func _refresh_quest() -> void:
	_quest_label.text = Game.quest_text()


# ---------- ล่างกลาง: ช่องสกิล ----------

func _build_skill_bar() -> void:
	var holder := Control.new()
	holder.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(holder)
	var names := ["ตี", "", "", ""]
	var total_w := 4 * 96.0 - 10.0
	for i in 4:
		var slot := Panel.new()
		slot.add_theme_stylebox_override("panel", _box(Color(1.0, 0.96, 0.85, 0.92) if i > 0 else Color(0.95, 0.85, 0.7, 0.92)))
		slot.position = Vector2(-total_w * 0.5 + i * 96.0, -112)
		slot.size = Vector2(86, 86)
		slot.clip_contents = true
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(slot)

		var overlay := ColorRect.new()
		overlay.color = Color(0.1, 0.08, 0.1, 0.72)
		overlay.position = Vector2(3, 3)
		overlay.size = Vector2(80, 0)
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(overlay)

		var name_label := _label(names[i], 18, Color(0.3, 0.18, 0.08), 0)
		name_label.position = Vector2(0, 40)
		name_label.size = Vector2(86, 40)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		slot.add_child(name_label)

		var key_label := _label(SLOT_KEYS[i], 24, Color(1.0, 0.9, 0.4), 7)
		key_label.position = Vector2(0, 0)
		key_label.size = Vector2(86, 40)
		key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot.add_child(key_label)

		var cd_label := _label("", 28, Color.WHITE, 8)
		cd_label.position = Vector2(0, 0)
		cd_label.size = Vector2(86, 86)
		cd_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cd_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		slot.add_child(cd_label)

		_slots.append({"name": name_label, "overlay": overlay, "cd": cd_label, "key": key_label})

	_forms_label = _label("", 18, Color.WHITE, 6)
	_forms_label.position = Vector2(-300, -26)
	_forms_label.size = Vector2(600, 24)
	_forms_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	holder.add_child(_forms_label)


# ---------- บนกลาง: หลอดเลือดบอส ----------

func _build_boss_bar() -> void:
	_boss_box = Control.new()
	_boss_box.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_boss_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boss_box.visible = false
	_root.add_child(_boss_box)
	_boss_label = _label("", 24, Color(1.0, 0.85, 0.4), 8)
	_boss_label.position = Vector2(-260, 14)
	_boss_label.size = Vector2(520, 30)
	_boss_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_box.add_child(_boss_label)
	_boss_bar = _bar(Color(0.95, 0.55, 0.15))
	_boss_bar.position = Vector2(-260, 52)
	_boss_bar.size = Vector2(520, 26)
	_boss_box.add_child(_boss_bar)


# ---------- ข้อความประกาศกลางจอ ----------

func _build_banner() -> void:
	_banner = _label("", 34, Color(1.0, 0.95, 0.7), 10)
	_banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_banner.position = Vector2(-500, 170)
	_banner.size = Vector2(1000, 100)
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.modulate.a = 0.0
	_root.add_child(_banner)


func show_banner(text: String) -> void:
	_banner.text = text
	if _banner_tween:
		_banner_tween.kill()
	_banner.modulate.a = 1.0
	_banner_tween = create_tween()
	_banner_tween.tween_interval(2.4)
	_banner_tween.tween_property(_banner, "modulate:a", 0.0, 0.6)


# ---------- กล่องบทสนทนา ----------

func _build_dialogue() -> void:
	_dialogue = Panel.new()
	_dialogue.add_theme_stylebox_override("panel", _box(Color(1.0, 0.97, 0.88, 0.97), 16))
	_dialogue.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_dialogue.position = Vector2(-470, -330)
	_dialogue.size = Vector2(940, 190)
	_dialogue.visible = false
	_root.add_child(_dialogue)

	_dlg_who = _label("", 26, Color(0.85, 0.4, 0.15), 0)
	_dlg_who.position = Vector2(26, 12)
	_dialogue.add_child(_dlg_who)

	_dlg_text = _label("", 24, Color(0.25, 0.15, 0.08), 0)
	_dlg_text.position = Vector2(26, 54)
	_dlg_text.size = Vector2(888, 96)
	_dlg_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dialogue.add_child(_dlg_text)

	var hint := _label("กด W / J / แตะจอ เพื่อไปต่อ ▶", 16, Color(0.5, 0.4, 0.3), 0)
	hint.position = Vector2(26, 156)
	hint.size = Vector2(888, 24)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_dialogue.add_child(hint)


func _on_dialogue_started(lines: Array) -> void:
	_lines = lines
	_line_index = 0
	_dlg_delay = 0.2
	_dialogue.visible = true
	_show_line()


func _show_line() -> void:
	var line: Dictionary = _lines[_line_index]
	_dlg_who.text = line.get("who", "")
	_dlg_text.text = line.get("text", "")


func _advance_dialogue() -> void:
	if _dlg_delay > 0.0:
		return
	_dlg_delay = 0.15
	_line_index += 1
	if _line_index >= _lines.size():
		_dialogue.visible = false
		Game.end_dialogue()
	else:
		_show_line()


func _unhandled_input(event: InputEvent) -> void:
	if Game.in_dialogue and event is InputEventScreenTouch and event.pressed:
		_advance_dialogue()
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F9:
		Game.main.restart_game()


# ---------- คำแนะนำปุ่ม ----------

func _build_help() -> void:
	if DisplayServer.is_touchscreen_available():
		return
	var help := _label("A/D เดิน   Space กระโดด   S+Space ลงแท่น\nJ ตี   U I O สกิล   Q/E สลับร่าง\nW คุย/เข้าประตู   F9 เริ่มเกมใหม่", 15, Color(1, 1, 1, 0.92), 5)
	help.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	help.position = Vector2(16, -84)
	help.add_theme_constant_override("line_spacing", -4)
	_root.add_child(help)


# ---------- อัปเดตทุกเฟรม ----------

func _process(delta: float) -> void:
	_dlg_delay = maxf(_dlg_delay - delta, 0.0)
	if Game.in_dialogue and (Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("attack") or Input.is_action_just_pressed("jump")):
		_advance_dialogue()

	var p := Game.player
	if p:
		var form := Game.current_form()
		for i in 3:
			var cd := p.get_cd(i)
			var slot: Dictionary = _slots[i + 1]
			var frac := clampf(cd / float(form["skills"][i]["cd"]), 0.0, 1.0)
			slot["overlay"].size.y = 80.0 * frac
			slot["cd"].text = "%.0f" % ceilf(cd) if cd > 0.0 else ""
			slot["key"].visible = cd <= 0.0

	var boss := Game.boss
	if boss and is_instance_valid(boss) and boss.is_alive():
		_boss_box.visible = true
		_boss_label.text = boss.BOSS_NAME
		_boss_bar.max_value = boss.MAX_HP
		_boss_bar.value = boss.hp
	else:
		_boss_box.visible = false


# ---------- ปุ่มสัมผัสสำหรับมือถือ ----------

func _build_touch() -> void:
	var left := Control.new()
	left.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_root.add_child(left)
	_touch_button(left, Vector2(30, -170), 60, "◀", "move_left")
	_touch_button(left, Vector2(170, -170), 60, "▶", "move_right")
	_touch_button(left, Vector2(100, -290), 46, "▼", "move_down")

	var right := Control.new()
	right.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_root.add_child(right)
	_touch_button(right, Vector2(-150, -170), 64, "ตี", "attack")
	_touch_button(right, Vector2(-290, -150), 54, "โดด", "jump")
	_touch_button(right, Vector2(-380, -260), 44, "1", "skill_1")
	_touch_button(right, Vector2(-270, -290), 44, "2", "skill_2")
	_touch_button(right, Vector2(-160, -320), 44, "3", "skill_3")
	_touch_button(right, Vector2(-110, -440), 40, "ร่าง", "form_next")
	_touch_button(right, Vector2(-230, -420), 40, "คุย", "interact")


func _touch_button(parent: Control, pos: Vector2, radius: int, text: String, action: String) -> void:
	var img := Image.create(radius * 2, radius * 2, false, Image.FORMAT_RGBA8)
	var c := Vector2(radius, radius)
	for y in radius * 2:
		for x in radius * 2:
			var d := Vector2(x + 0.5, y + 0.5).distance_to(c)
			if d <= radius - 4:
				img.set_pixel(x, y, Color(1, 1, 1, 0.35))
			elif d <= radius:
				img.set_pixel(x, y, Color(0.1, 0.08, 0.05, 0.6))
	var btn := TouchScreenButton.new()
	btn.texture_normal = ImageTexture.create_from_image(img)
	btn.action = action
	btn.position = pos
	parent.add_child(btn)
	var l := _label(text, int(radius * 0.6), Color.WHITE, 6)
	l.position = pos
	l.size = Vector2(radius * 2, radius * 2)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	parent.add_child(l)
