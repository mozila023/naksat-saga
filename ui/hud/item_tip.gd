class_name ItemTip extends PanelContainer
## กล่องรายละเอียดไอเทม: โผล่ข้าง ๆ เมื่อชี้เมาส์ (PC) หรือแตะ (มือถือ) ที่ไอเทม/อุปกรณ์
## ใช้: Hud.show_tip(id, control) / Hud.hide_tip()

const SLOT_NAME := {"weapon": "อาวุธ", "head": "หมวก", "body": "ชุด", "feet": "รองเท้า", "charm": "เครื่องราง"}
const BROWN := "4d2e14"
const SOFT := "7a6550"

var _text: RichTextLabel
var _anchor: Control
var _shown_at := 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 100
	visible = false
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1.0, 0.97, 0.88, 0.97)
	sb.border_color = Color(0.55, 0.36, 0.18)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(12)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	sb.shadow_color = Color(0, 0, 0, 0.25)
	sb.shadow_size = 6
	add_theme_stylebox_override("panel", sb)
	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.fit_content = true
	_text.scroll_active = false
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.custom_minimum_size = Vector2(300, 0)
	_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_text.add_theme_font_size_override("normal_font_size", 17)
	_text.add_theme_font_size_override("bold_font_size", 21)
	_text.add_theme_color_override("default_color", Color(0.3, 0.18, 0.08))
	add_child(_text)


## แสดงรายละเอียดของไอเทม id ข้าง ๆ ตัวควบคุม anchor (extra = บรรทัดเพิ่มท้าย เช่น "คุณภาพสุ่มตอนตี")
func show_item(id: String, anchor: Control, extra := "") -> void:
	if not Game.ITEMS.has(id) or anchor == null or not anchor.is_visible_in_tree():
		return
	_anchor = anchor
	_text.text = describe(id) + ("\n[color=#%s]%s[/color]" % [SOFT, extra] if extra != "" else "")
	visible = true
	_shown_at = Time.get_ticks_msec() / 1000.0
	size = Vector2.ZERO
	_place.call_deferred()


func hide_tip(from: Control = null) -> void:
	if from == null or from == _anchor:
		visible = false
		_anchor = null


func _process(_delta: float) -> void:
	# ตัวที่ชี้อยู่หายไป (หน้าต่างปิด/รายการถูกสร้างใหม่) = ซ่อนกล่อง
	if visible and (_anchor == null or not is_instance_valid(_anchor) or not _anchor.is_visible_in_tree()):
		hide_tip()
	# มือถือ: แตะดูแล้วกล่องหายเองใน 4 วินาที
	elif visible and DisplayServer.is_touchscreen_available() and Time.get_ticks_msec() / 1000.0 - _shown_at > 4.0:
		hide_tip()


## วางกล่องข้าง ๆ จุดที่ชี้/แตะ ถ้าล้นจอให้ไปอีกฝั่ง
func _place() -> void:
	if _anchor == null or not is_instance_valid(_anchor):
		return
	reset_size()
	var screen := get_viewport_rect().size
	var m := get_global_mouse_position()
	var r := _anchor.get_global_rect()
	if not r.grow(4.0).has_point(m):
		m = r.get_center()
	var pos := m + Vector2(22.0, 18.0)
	if pos.x + size.x > screen.x - 8.0:
		pos.x = m.x - size.x - 22.0
	if pos.y + size.y > screen.y - 8.0:
		pos.y = m.y - size.y - 18.0
	pos.x = clampf(pos.x, 8.0, maxf(8.0, screen.x - size.x - 8.0))
	pos.y = clampf(pos.y, 8.0, maxf(8.0, screen.y - size.y - 8.0))
	global_position = pos


## ข้อความรายละเอียดทั้งหมดของไอเทม (BBCode)
static func describe(id: String) -> String:
	var info: Dictionary = Game.ITEMS[id]
	var q := int(info.get("quality", 0))
	var col: Color = Crafting.quality(q)["ui"] if q >= 2 else Color(0.3, 0.18, 0.08)
	var lines: Array = []
	lines.append("[b][color=#%s]%s[/color][/b]" % [col.to_html(false), info["name"]])
	# ชนิด + คุณภาพ
	var kind := ""
	if info.has("slot"):
		kind = "อุปกรณ์ · %s" % SLOT_NAME.get(info["slot"], "")
	elif info.has("heal"):
		kind = "ยา"
	elif id.begins_with("zpart_"):
		kind = "ชิ้นส่วนนักษัตร"
	else:
		kind = "วัตถุดิบ"
	if q >= 2:
		kind += " · [color=#%s]%s[/color]" % [col.to_html(false), Crafting.quality(q)["name"]]
	lines.append("[color=#%s]%s[/color]" % [SOFT, kind])
	# ค่าพลัง
	var stats: Array = []
	if info.has("atk"):
		stats.append("พลังโจมตี +%d" % int(info["atk"]))
	if info.has("hp"):
		stats.append("เลือดสูงสุด +%d" % int(info["hp"]))
	if info.has("speed"):
		stats.append("ความเร็ว +%d%%" % int(round(float(info["speed"]) * 100.0)))
	if info.has("heal"):
		stats.append("ฟื้นเลือด %d" % int(info["heal"]))
	if not stats.is_empty():
		lines.append("[color=#2f7a2a]%s[/color]" % "\n".join(stats))
	# โบนัสเซ็ทนักษัตร
	var z: String = info.get("set", "")
	if z != "" and Crafting.SETS.has(z):
		var s: Dictionary = Crafting.SETS[z]
		var have := int(Game.set_counts().get(z, 0))
		lines.append("[color=#%s]%s (ใส่อยู่ %d/5)[/color]" % [Crafting.ZODIAC_QUALITY["ui"].to_html(false), s["name"], have])
		for n in [3, 5]:
			var on: bool = have >= n
			lines.append("[color=#%s]%d ชิ้น: %s[/color]" % ["2f7a2a" if on else "9a8a78", n, s["bonus%d" % n]["text"]])
	# คำอธิบาย
	var desc: String = info.get("desc", "")
	if desc == "":
		desc = _auto_desc(id, info)
	if desc != "":
		lines.append(desc)
	var from := _drop_sources(id)
	if from != "":
		lines.append("[color=#%s]ได้จาก: %s[/color]" % [SOFT, from])
	# ราคา
	var price := Game.sell_price(id)
	if price > 0:
		lines.append("[color=#a0701a]ขายได้ %d บาท[/color]" % price)
	elif id.begins_with("zpart_"):
		lines.append("[color=#%s]ขายไม่ได้[/color]" % SOFT)
	return "\n".join(lines)


static func _auto_desc(id: String, info: Dictionary) -> String:
	if id.begins_with("zpart_"):
		var bits := id.trim_prefix("zpart_").split("_")
		for p in Crafting.PARTS:
			if p[0] == bits[bits.size() - 1] and Crafting.SETS.has(bits[0]):
				return "ให้ลุงเหล็กตีเป็น %s" % Crafting.SETS[bits[0]]["gear"][p[1]]["name"]
	if info.has("set"):
		return "ของเทพ ตีจากชิ้นส่วนนักษัตร"
	if int(info.get("quality", 0)) >= 1 and id.contains("__q"):
		return "ลุงเหล็กตีให้"
	# วัตถุดิบ: ใช้ตีอะไรได้บ้าง
	var uses: Array = []
	for r in Crafting.RECIPES:
		if r["mats"].has(id):
			uses.append(r["name"])
	if not uses.is_empty():
		return "ใช้ตี %s" % ", ".join(uses.slice(0, 3))
	return ""


## มอนสเตอร์/บอสที่ดรอปไอเทมนี้
static func _drop_sources(id: String) -> String:
	var names: Array = []
	for kind in Game.REWARDS:
		for d in Game.REWARDS[kind]["drops"]:
			if d[0] == id:
				var n := ""
				if Enemy.KINDS.has(kind):
					n = Enemy.KINDS[kind]["name"]
				elif ZodiacBoss.DEMONS.has(kind):
					n = ZodiacBoss.DEMONS[kind]["name"]
				elif not Zodiac.get_data(kind).is_empty():
					n = Zodiac.get_data(kind)["year"]
				if n != "" and not (n in names):
					names.append(n)
	return ", ".join(names.slice(0, 3))
