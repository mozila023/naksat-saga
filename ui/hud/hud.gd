class_name Hud extends CanvasLayer
## หน้าจอ HUD: หลอดเลือด, ร่างปัจจุบัน, เควส, ช่องสกิล, หลอดเลือดบอส, กล่องบทสนทนา, ปุ่มสัมผัส (มือถือ)

const OUTLINE := Color(0.12, 0.08, 0.05)
const SLOT_KEYS := ["C", "A", "S", "D"]

var _root: Control
var _form_swatch: Panel
var _form_icon: TextureRect
var _form_label: Label
var _hp_bar: ProgressBar
var _hp_label: Label
var _level_label: Label
var _exp_bar: ProgressBar
var _money_label: Label
var _potion_label: Label
var _bag: Panel
var _bag_list: VBoxContainer
var _bag_stats: Label
var _hot_slots: Array = []
var _bag_tab := "item"
var _char: Panel
var _char_pic: TextureRect
var _char_name: Label
var _char_stats: Label
var _equip_slots: Array = []
var _tab_buttons := {}
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
var _mute_btn: Button
var _craft: Panel
var _craft_list: VBoxContainer
var _craft_money: Label


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
	if DisplayServer.is_touchscreen_available():
		_build_touch()

	_build_char()
	_build_bag()
	_build_hotbar()
	_build_craft()
	Game.crafting_opened.connect(open_craft)
	Game.stats_changed.connect(_refresh_stats)
	_refresh_stats()
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
	panel.size = Vector2(350, 104)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(panel)

	_form_swatch = Panel.new()
	_form_swatch.position = Vector2(12, 12)
	_form_swatch.size = Vector2(68, 68)
	_form_swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(_form_swatch)
	_form_icon = TextureRect.new()
	_form_icon.position = Vector2(6, 4)
	_form_icon.size = Vector2(56, 60)
	_form_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_form_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_form_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_form_swatch.add_child(_form_icon)

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

	# เลเวล + หลอด EXP
	_level_label = _label("Lv.1", 22, Color(0.85, 0.4, 0.15), 0)
	_level_label.position = Vector2(236, 6)
	_level_label.size = Vector2(100, 30)
	_level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	panel.add_child(_level_label)
	_exp_bar = _bar(Color(1.0, 0.8, 0.25))
	_exp_bar.position = Vector2(92, 80)
	_exp_bar.size = Vector2(244, 14)
	panel.add_child(_exp_bar)

	# เงิน + ยาแดง
	var row := HBoxContainer.new()
	row.position = Vector2(20, 126)
	row.add_theme_constant_override("separation", 6)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(row)
	row.add_child(_icon("coin", 30))
	_money_label = _label("0", 22, Color(1.0, 0.9, 0.4), 7)
	row.add_child(_money_label)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(14, 0)
	row.add_child(gap)
	row.add_child(_icon("potion", 30))
	_potion_label = _label("x0", 22, Color(1.0, 0.75, 0.75), 7)
	row.add_child(_potion_label)

	_quest_label = _label("", 24, Color(1.0, 0.92, 0.55), 8)
	_quest_label.position = Vector2(20, 162)
	_root.add_child(_quest_label)
	_mute_btn = Button.new()
	_mute_btn.position = Vector2(376, 16)
	_mute_btn.size = Vector2(46, 46)
	_mute_btn.focus_mode = Control.FOCUS_NONE
	_mute_btn.add_theme_font_size_override("font_size", 22)
	var mb_style := _box(Color(1.0, 0.96, 0.85, 0.92), 10)
	for st in ["normal", "hover", "pressed"]:
		_mute_btn.add_theme_stylebox_override(st, mb_style)
	_mute_btn.pressed.connect(_toggle_mute)
	_root.add_child(_mute_btn)
	_refresh_mute()


func _icon(item: String, px: int) -> TextureRect:
	var t := TextureRect.new()
	t.texture = load("res://assets/art/items/item_%s.png" % item)
	t.custom_minimum_size = Vector2(px, px)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


## สีชื่อไอเทมตามคุณภาพ (บนหน้าต่างสีครีม)
func item_color(id: String) -> Color:
	return Crafting.quality(int(Game.ITEMS[id].get("quality", 1)))["ui"]


## ชื่อไอเทม พร้อมป้ายคุณภาพ เช่น "เสื้อหนังกบ [หายาก]"
func item_title(id: String) -> String:
	var q := int(Game.ITEMS[id].get("quality", 0))
	var name: String = Game.ITEMS[id]["name"]
	return name if q <= 1 else "%s [%s]" % [name, Crafting.quality(q)["name"]]


func _refresh_stats() -> void:
	_level_label.text = "Lv.%d" % Game.level
	_exp_bar.max_value = Game.exp_needed()
	_exp_bar.value = Game.exp_needed() if Game.level >= Game.MAX_LEVEL else Game.exp
	_money_label.text = "%d บาท" % Game.money
	_potion_label.text = "x%d  [F]" % Game.item_count("potion")
	if _bag.visible:
		_fill_bag()
	for slot in _hot_slots:
		slot.refresh()


# ---------- ช่องไอเทม 1-7 ----------
# ลากไอเทมจากกระเป๋ามาใส่ / กดเลข 1-7 หรือคลิกเพื่อใช้ / คลิกขวาเพื่อเอาออก / ลากสลับช่องกันได้

func _build_hotbar() -> void:
	var holder := Control.new()
	var touch := DisplayServer.is_touchscreen_available()
	holder.set_anchors_preset(Control.PRESET_TOP_RIGHT if touch else Control.PRESET_BOTTOM_RIGHT)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(holder)
	for i in Game.HOTBAR_SIZE:
		var slot := HotSlot.new()
		slot.index = i
		slot.hud = self
		slot.position = Vector2(-16 - (Game.HOTBAR_SIZE - i) * 62.0, 16 if touch else -78)
		slot.size = Vector2(56, 56)
		holder.add_child(slot)
		slot.build()
		_hot_slots.append(slot)


class HotSlot extends Panel:
	var index := 0
	var hud: Hud
	var _icon: TextureRect
	var _count: Label

	func build() -> void:
		add_theme_stylebox_override("panel", hud._box(Color(1.0, 0.96, 0.85, 0.85), 10))
		mouse_filter = Control.MOUSE_FILTER_STOP
		_icon = hud._icon("coin", 40)
		_icon.position = Vector2(8, 10)
		_icon.size = Vector2(40, 40)
		add_child(_icon)
		var key := hud._label(str(index + 1), 15, Color(1.0, 0.9, 0.4), 5)
		key.position = Vector2(6, 0)
		add_child(key)
		_count = hud._label("", 15, Color.WHITE, 5)
		_count.position = Vector2(0, 34)
		_count.size = Vector2(52, 20)
		_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		add_child(_count)
		refresh()

	func refresh() -> void:
		var id: String = Game.hotbar[index]
		if id == "":
			_icon.visible = false
			_count.text = ""
			tooltip_text = ""
		else:
			var n := Game.item_count(id)
			_icon.visible = true
			_icon.texture = load("res://assets/art/items/item_%s.png" % Game.ITEMS[id]["icon"])
			_icon.modulate = Color.WHITE if n > 0 else Color(1, 1, 1, 0.35)
			_count.text = "x%d" % n
			tooltip_text = Game.ITEMS[id]["name"]

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			if event.button_index == MOUSE_BUTTON_RIGHT:
				Game.set_hotbar(index, "")
			elif event.button_index == MOUSE_BUTTON_LEFT and event.double_click:
				Game.use_hotbar(index)

	func _get_drag_data(_at: Vector2) -> Variant:
		var id: String = Game.hotbar[index]
		if id == "":
			return null
		set_drag_preview(hud._icon(Game.ITEMS[id]["icon"], 44))
		return {"item": id, "from_slot": index}

	func _can_drop_data(_at: Vector2, data: Variant) -> bool:
		return data is Dictionary and data.has("item")

	func _drop_data(_at: Vector2, data: Variant) -> void:
		Game.set_hotbar(index, data["item"])


## ช่องอุปกรณ์สวมใส่ในหน้าตัวละคร
class EquipSlot extends Panel:
	var slot := ""
	var title := ""
	var hud: Hud
	var _icon: TextureRect
	var _name: Label

	func build() -> void:
		add_theme_stylebox_override("panel", hud._box(Color(0.93, 0.88, 0.76), 10))
		mouse_filter = Control.MOUSE_FILTER_STOP
		_icon = hud._icon("coin", 30)
		_icon.position = Vector2(6, 5)
		_icon.size = Vector2(30, 30)
		add_child(_icon)
		_name = hud._label("", 15, Color(0.3, 0.18, 0.08), 0)
		_name.position = Vector2(40, 0)
		_name.size = Vector2(84, 40)
		_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_name.clip_text = true
		add_child(_name)
		refresh()

	func refresh() -> void:
		var id: String = Game.equipped.get(slot, "")
		_icon.visible = id != ""
		if id == "":
			_name.text = title
			_name.position.x = 0
			_name.size.x = 126
			_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			_name.add_theme_color_override("font_color", Color(0.6, 0.5, 0.4))
		else:
			_icon.texture = load("res://assets/art/items/item_%s.png" % Game.ITEMS[id]["icon"])
			_name.text = Game.ITEMS[id]["name"]
			_name.position.x = 40
			_name.size.x = 84
			_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			_name.add_theme_color_override("font_color", hud.item_color(id))

	func _can_drop_data(_at: Vector2, data: Variant) -> bool:
		return data is Dictionary and data.has("item") and Game.ITEMS[data["item"]].get("slot", "") == slot

	func _drop_data(_at: Vector2, data: Variant) -> void:
		Game.equip(data["item"])

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			if event.button_index == MOUSE_BUTTON_RIGHT or (event.button_index == MOUSE_BUTTON_LEFT and event.double_click):
				Game.unequip(slot)


## แถวไอเทมในกระเป๋า (ลากไปใส่ช่อง 1-7 หรือช่องอุปกรณ์ได้ / ดับเบิลคลิกเพื่อสวมหรือใช้)
class BagRow extends HBoxContainer:
	var item := ""
	var hud: Hud

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and event.double_click:
			if Game.player and not Game.player.dead:
				Game.player.use_item(item)

	func _get_drag_data(_at: Vector2) -> Variant:
		set_drag_preview(hud._icon(Game.ITEMS[item]["icon"], 44))
		return {"item": item}


# ---------- กระเป๋า (กด B) ----------

func _build_bag() -> void:
	_bag = Panel.new()
	_bag.add_theme_stylebox_override("panel", _box(Color(1.0, 0.97, 0.88, 0.98), 18))
	_bag.set_anchors_preset(Control.PRESET_CENTER)
	_bag.position = Vector2(-150, -260)
	_bag.size = Vector2(600, 500)
	_bag.visible = false
	_root.add_child(_bag)
	var title := _label("กระเป๋า", 30, Color(0.85, 0.4, 0.15), 0)
	title.position = Vector2(28, 14)
	_bag.add_child(title)
	_bag_stats = _label("", 18, Color(0.3, 0.18, 0.08), 0)
	_bag_stats.position = Vector2(180, 22)
	_bag_stats.size = Vector2(392, 26)
	_bag_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_bag.add_child(_bag_stats)
	# แท็บ: อุปกรณ์สวมใส่ / ไอเทม / ทั่วไป
	var tabs := [["equip", "อุปกรณ์สวมใส่"], ["item", "ไอเทม"], ["etc", "ทั่วไป"]]
	for i in tabs.size():
		var b := Button.new()
		b.text = tabs[i][1]
		b.focus_mode = Control.FOCUS_NONE  # กัน Space/Enter ไปกดปุ่มแท็บตอนเล่น
		b.position = Vector2(28 + i * 184, 70)
		b.size = Vector2(176, 44)
		b.add_theme_font_size_override("font_size", 20)
		b.pressed.connect(_set_bag_tab.bind(tabs[i][0]))
		_bag.add_child(b)
		_tab_buttons[tabs[i][0]] = b
	_bag_list = VBoxContainer.new()
	_bag_list.position = Vector2(28, 132)
	_bag_list.size = Vector2(544, 350)
	_bag_list.add_theme_constant_override("separation", 10)
	_bag.add_child(_bag_list)


func _set_bag_tab(tab: String) -> void:
	_bag_tab = tab
	_fill_bag()


# ---------- หน้าต่างตัวละคร (เปิดพร้อมกระเป๋า) ----------

func _build_char() -> void:
	_char = Panel.new()
	_char.add_theme_stylebox_override("panel", _box(Color(1.0, 0.97, 0.88, 0.98), 18))
	_char.set_anchors_preset(Control.PRESET_CENTER)
	_char.position = Vector2(-470, -260)
	_char.size = Vector2(308, 560)
	_char.visible = false
	_root.add_child(_char)
	var title := _label("ตัวละคร", 30, Color(0.85, 0.4, 0.15), 0)
	title.position = Vector2(24, 14)
	_char.add_child(title)
	# รูปตัวละครร่างปัจจุบัน
	var frame := Panel.new()
	frame.add_theme_stylebox_override("panel", _box(Color(0.78, 0.9, 1.0), 14))
	frame.position = Vector2(24, 66)
	frame.size = Vector2(124, 150)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_char.add_child(frame)
	_char_pic = TextureRect.new()
	_char_pic.position = Vector2(4, 6)
	_char_pic.size = Vector2(116, 140)
	_char_pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_char_pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_char_pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(_char_pic)
	# ช่องอุปกรณ์สวมใส่: ลากอุปกรณ์จากกระเป๋ามาใส่ หรือดับเบิลคลิกที่อุปกรณ์ในกระเป๋า / คลิกขวาที่ช่องเพื่อถอด
	for i in Game.EQUIP_SLOTS.size():
		var slot := EquipSlot.new()
		slot.slot = Game.EQUIP_SLOTS[i][0]
		slot.title = Game.EQUIP_SLOTS[i][1]
		slot.hud = self
		slot.position = Vector2(160, 66 + i * 46)
		slot.size = Vector2(126, 40)
		_char.add_child(slot)
		slot.build()
		_equip_slots.append(slot)
	_char_name = _label("", 22, Color(0.3, 0.18, 0.08), 0)
	_char_name.position = Vector2(24, 300)
	_char.add_child(_char_name)
	_char_stats = _label("", 17, Color(0.3, 0.18, 0.08), 0)
	_char_stats.position = Vector2(24, 334)
	_char_stats.size = Vector2(270, 210)
	_char_stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_char_stats.add_theme_constant_override("line_spacing", -2)
	_char.add_child(_char_stats)


func _fill_char() -> void:
	var form := Game.current_form()
	var path: String = form["outfit"].get("sprite", "")
	_char_pic.texture = load(path) if path != "" and ResourceLoader.exists(path) else null
	_char_name.text = "%s  ·  %s" % [Game.player_name, form["short"]] if Game.player_name != "" else form["name"]
	var total_atk := Game.atk_mult() * float(form["atk"])
	total_atk *= 1.0 + Game.set_effect("atk_mult")
	_char_stats.text = "เลเวล  %d / %d\nEXP  %d / %d\nเลือด  %d / %d\nพลังโจมตี  %d\nความเร็ว  %d%%\nร่างที่มี  %d / 14" % [
		Game.level, Game.level_cap(), Game.exp, Game.exp_needed(), ceili(Game.hp), int(Game.max_hp),
		int(round((Player.BASE_ATK + Game.equip_bonus("atk")) * total_atk)),
		int(round(float(form["speed"]) * (1.0 + Game.equip_bonus("speed")) * 100.0)), Game.unlocked.size()]
	# เซ็ทนักษัตรที่สวมอยู่: จำนวนชิ้น + ความสามารถที่เปิดแล้ว
	var counts := Game.set_counts()
	for z in counts:
		var s: Dictionary = Crafting.SETS[z]
		_char_stats.text += "\n%s  %d/5" % [s["name"], int(counts[z])]
		for need in [3, 5]:
			if int(counts[z]) >= need:
				_char_stats.text += "\n  " + str(s["bonus%d" % need]["text"])
	for slot in _equip_slots:
		slot.refresh()


# ---------- ช่างตีเหล็ก (คราฟของ) ----------

func _build_craft() -> void:
	_craft = Panel.new()
	_craft.add_theme_stylebox_override("panel", _box(Color(1.0, 0.97, 0.88, 0.98), 18))
	_craft.set_anchors_preset(Control.PRESET_CENTER)
	_craft.position = Vector2(-340, -280)
	_craft.size = Vector2(680, 540)
	_craft.visible = false
	_root.add_child(_craft)
	var title := _label("ช่างตีเหล็ก", 30, Color(0.85, 0.4, 0.15), 0)
	title.position = Vector2(28, 14)
	_craft.add_child(title)
	_craft_money = _label("", 18, Color(0.3, 0.18, 0.08), 0)
	_craft_money.position = Vector2(300, 22)
	_craft_money.size = Vector2(290, 26)
	_craft_money.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_craft.add_child(_craft_money)
	var close := Button.new()
	close.text = "✕"
	close.focus_mode = Control.FOCUS_NONE
	close.position = Vector2(620, 14)
	close.size = Vector2(44, 40)
	close.add_theme_font_size_override("font_size", 20)
	close.pressed.connect(close_craft)
	_craft.add_child(close)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(20, 66)
	scroll.size = Vector2(640, 456)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_craft.add_child(scroll)
	_craft_list = VBoxContainer.new()
	_craft_list.custom_minimum_size = Vector2(620, 0)
	_craft_list.add_theme_constant_override("separation", 8)
	scroll.add_child(_craft_list)


func open_craft() -> void:
	Sound.play("ui")
	_bag.visible = false
	_char.visible = false
	_craft.visible = true
	_fill_craft()


func close_craft() -> void:
	_craft.visible = false


func _fill_craft() -> void:
	_craft_money.text = "%d บาท" % Game.money
	for child in _craft_list.get_children():
		_craft_list.remove_child(child)
		child.queue_free()
	for r in Crafting.recipe_list(Game.items):
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		row.custom_minimum_size = Vector2(620, 56)
		row.add_child(_icon(r["icon"], 44))
		var info := VBoxContainer.new()
		info.custom_minimum_size = Vector2(470, 0)
		info.add_theme_constant_override("separation", 0)
		var col := Crafting.ZODIAC_QUALITY["ui"] if r["zodiac"] != "" else Color(0.3, 0.18, 0.08)
		info.add_child(_label(r["name"], 20, col, 0))
		var need: Array = []
		for id in r["mats"]:
			need.append("%s %d/%d" % [Game.ITEMS[id]["name"], mini(Game.item_count(id), int(r["mats"][id])), int(r["mats"][id])])
		need.append("%d บาท" % int(r["cost"]))
		if r["zodiac"] != "":
			need.append("สำเร็จ %d%%" % int(round(Crafting.set_chance(int(Game.craft_fails.get(r["key"], 0))) * 100.0)))
		var mats := _label("  ".join(need), 15, Color(0.45, 0.35, 0.25), 0)
		mats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		mats.custom_minimum_size = Vector2(470, 0)
		info.add_child(mats)
		row.add_child(info)
		var b := Button.new()
		b.text = "ตี"
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(80, 46)
		b.add_theme_font_size_override("font_size", 20)
		b.disabled = not Game.can_craft(r)
		b.add_theme_stylebox_override("normal", _box(Color(1.0, 0.82, 0.45), 10))
		b.add_theme_stylebox_override("hover", _box(Color(1.0, 0.9, 0.6), 10))
		b.add_theme_stylebox_override("pressed", _box(Color(0.95, 0.7, 0.35), 10))
		b.add_theme_stylebox_override("disabled", _box(Color(0.88, 0.85, 0.78), 10))
		for st in ["font_color", "font_hover_color", "font_pressed_color"]:
			b.add_theme_color_override(st, Color(0.35, 0.2, 0.08))
		b.add_theme_color_override("font_disabled_color", Color(0.65, 0.6, 0.55))
		b.pressed.connect(_do_craft.bind(r))
		row.add_child(b)
		_craft_list.add_child(row)


func _do_craft(r: Dictionary) -> void:
	var out := Game.craft(r)
	if out == "":
		return
	if out == "FAIL":
		Sound.play("hurt")
		show_banner("ตีพัง!\nชิ้นส่วนนักษัตรยังอยู่ ลองใหม่อีกครั้ง")
		_banner.add_theme_color_override("font_color", Color(1.0, 0.5, 0.45))
		Game.shake(5.0, 0.2)
		_fill_craft()
		return
	var q := Crafting.quality(int(Game.ITEMS[out].get("quality", 1)))
	Sound.play("quest" if int(q["id"]) >= 3 else "ui")
	show_banner("ได้ %s\n[%s]" % [Game.ITEMS[out]["name"], q["name"]])
	_banner.add_theme_color_override("font_color", q["color"])
	if Game.player:
		Fx.spawn(Game.player.get_parent(), Game.player.global_position + Vector2(0, -60), "star", Vector2(40, 100), q["color"], 1, 0.7)
	_fill_craft()


func toggle_bag() -> void:
	Sound.play("ui")
	_bag.visible = not _bag.visible
	_char.visible = _bag.visible
	if _bag.visible:
		_fill_bag()


func _toggle_mute() -> void:
	Sound.toggle_mute()
	_refresh_mute()
	Game.save_game()
	if not Sound.muted:
		Sound.play("ui")


func _refresh_mute() -> void:
	if _mute_btn == null:
		return
	_mute_btn.text = "✕" if Sound.muted else "♪"
	var col := Color(0.75, 0.3, 0.3) if Sound.muted else Color(0.3, 0.18, 0.08)
	for st in ["font_color", "font_hover_color", "font_pressed_color"]:
		_mute_btn.add_theme_color_override(st, col)



func _fill_bag() -> void:
	_bag_stats.text = "%d บาท" % Game.money
	_fill_char()
	for tab in _tab_buttons:
		var on: bool = tab == _bag_tab
		var btn: Button = _tab_buttons[tab]
		var style := _box(Color(1.0, 0.85, 0.5) if on else Color(0.93, 0.88, 0.76), 10)
		for state in ["normal", "hover", "pressed"]:
			btn.add_theme_stylebox_override(state, style)
		for state in ["font_color", "font_hover_color", "font_pressed_color"]:
			btn.add_theme_color_override(state, Color(0.3, 0.18, 0.08) if on else Color(0.55, 0.45, 0.35))
	for child in _bag_list.get_children():
		_bag_list.remove_child(child)
		child.queue_free()
	var any := false
	for id in Game.ITEMS:
		var count := Game.item_count(id)
		var info: Dictionary = Game.ITEMS[id]
		if count <= 0 or info["tab"] != _bag_tab:
			continue
		any = true
		var row := BagRow.new()
		row.item = id
		row.hud = self
		row.mouse_filter = Control.MOUSE_FILTER_STOP
		row.mouse_default_cursor_shape = Control.CURSOR_DRAG
		row.add_theme_constant_override("separation", 12)
		row.add_child(_icon(info["icon"], 44))
		var text := "%s  x%d" % [item_title(id), count]
		var bonus: Array = []
		if info.has("atk"):
			bonus.append("โจมตี +%d" % int(info["atk"]))
		if info.has("hp"):
			bonus.append("เลือด +%d" % int(info["hp"]))
		if info.has("speed"):
			bonus.append("เร็ว +%d%%" % int(round(float(info["speed"]) * 100.0)))
		if not bonus.is_empty():
			text += "    " + "  ".join(bonus)
		row.add_child(_label(text, 20, item_color(id), 0))
		_bag_list.add_child(row)
	if not any:
		_bag_list.add_child(_label("ว่าง", 19, Color(0.6, 0.5, 0.4), 0))


func _refresh_hp() -> void:
	if _char and _char.visible:
		_fill_char()
	_hp_bar.max_value = Game.max_hp
	_hp_bar.value = Game.hp
	_hp_label.text = "%d / %d" % [ceili(Game.hp), int(Game.max_hp)]


func _refresh_form() -> void:
	var form := Game.current_form()
	var sprite_path: String = form["outfit"].get("sprite", "")
	if sprite_path != "" and ResourceLoader.exists(sprite_path):
		# ใช้ครึ่งบนของภาพตัวละครเป็นไอคอนร่าง
		var tex: Texture2D = load(sprite_path)
		var icon := AtlasTexture.new()
		icon.atlas = tex
		icon.region = Rect2(0, 0, tex.get_width(), tex.get_height() * 0.56)
		_form_icon.texture = icon
		_form_swatch.add_theme_stylebox_override("panel", _box(Color(0.75, 0.9, 1.0), 16))
	else:
		_form_icon.texture = null
		_form_swatch.add_theme_stylebox_override("panel", _box(form["outfit"]["shirt"], 34))
	_form_label.text = form["name"]
	if _char and _char.visible:
		_fill_char()
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
	_banner.position = Vector2(-500, 230)
	_banner.size = Vector2(1000, 100)
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.modulate.a = 0.0
	_root.add_child(_banner)


func show_banner(text: String) -> void:
	_banner.text = text
	_banner.add_theme_color_override("font_color", Color(1.0, 0.95, 0.7))
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

	var hint := _label("กด ↑ / C / แตะจอ เพื่อไปต่อ ▶", 16, Color(0.5, 0.4, 0.3), 0)
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
		Sound.play("talk", 0.04)
		_show_line()


func _unhandled_input(event: InputEvent) -> void:
	if Game.in_dialogue and event is InputEventScreenTouch and event.pressed:
		_advance_dialogue()
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F9:
		Game.main.restart_game()


# ---------- อัปเดตทุกเฟรม ----------

func _process(delta: float) -> void:
	_dlg_delay = maxf(_dlg_delay - delta, 0.0)
	if Input.is_action_just_pressed("mute"):
		_toggle_mute()
	if Input.is_action_just_pressed("bag") and not Game.in_dialogue:
		if _craft.visible:
			close_craft()
		else:
			toggle_bag()
	# เดินออกห่างจากช่าง = ปิดหน้าคราฟ
	if _craft.visible and Game.player and (Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right")):
		close_craft()
	if not Game.in_dialogue:
		for i in Game.HOTBAR_SIZE:
			if Input.is_action_just_pressed("slot_%d" % (i + 1)):
				Game.use_hotbar(i)
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
		_boss_label.text = boss.boss_name
		_boss_bar.max_value = boss.max_hp
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
	_touch_button(left, Vector2(40, -290), 46, "▼", "move_down")
	_touch_button(left, Vector2(180, -290), 46, "วิ่ง", "run")

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
	_touch_button(right, Vector2(-350, -390), 40, "ยา", "use_potion")
	_touch_button(right, Vector2(-110, -560), 40, "ของ", "bag")


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
