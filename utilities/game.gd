extends Node
## ตัวกลางของเกม (autoload ชื่อ Game): เก็บ HP, ร่างที่ปลดล็อก, เควส, เซฟ และฟังก์ชันต่อสู้กลาง

signal hp_changed
signal form_changed
signal quest_changed
signal stats_changed  # เลเวล / EXP / เงิน / ไอเทม เปลี่ยน
signal banner(text: String)
signal dialogue_started(lines: Array)
signal dialogue_finished
signal crafting_opened  # คุยกับช่างตีเหล็ก: HUD เปิดหน้าคราฟของ
signal shop_opened  # คุยกับป้าศรี: HUD เปิดหน้าร้าน

const SAVE_PATH := "user://save.cfg"
const FROGS_NEEDED := 5

# ---------- ไอเทม ----------
# tab = แท็บในกระเป๋า (equip อุปกรณ์สวมใส่ / item ไอเทม / etc ทั่วไป)
# buy = ราคาซื้อจากป้าศรี (0 = ไม่มีขาย), sell = ราคาที่ลุงหมูรับซื้อ (0 = ไม่รับซื้อ)
# (ของที่คราฟได้และชิ้นส่วนนักษัตร ถูกเพิ่มเข้ามาตอนเริ่มเกม จาก Crafting.generated_items())
var ITEMS := {
	"potion": {"name": "ยาแดง", "desc": "ฟื้นเลือด 50 (กด F เพื่อดื่ม)", "icon": "potion", "tab": "item", "heal": 50.0, "buy": 20, "sell": 0},
	"big_potion": {"name": "ยาแดงขวดใหญ่", "desc": "", "icon": "big_potion", "tab": "item", "heal": 150.0, "buy": 55, "sell": 0},
	"frog_leg": {"name": "ขากบ", "desc": "ได้จากกบนา ขายให้ลุงหมูได้", "icon": "frog_leg", "tab": "etc", "buy": 0, "sell": 6},
	"mushroom_cap": {"name": "หมวกเห็ดพิษ", "desc": "ได้จากเห็ดพิษ ขายให้ลุงหมูได้", "icon": "mushroom_cap", "tab": "etc", "buy": 0, "sell": 12},
	# อุปกรณ์สวมใส่: slot = ช่องที่ใส่, atk = พลังโจมตีเพิ่ม, hp = เลือดสูงสุดเพิ่ม, speed = ความเร็วเพิ่ม (0.08 = 8%)
	"wood_sword": {"name": "ดาบไม้", "desc": "", "icon": "wood_sword", "tab": "equip", "slot": "weapon", "atk": 3.0, "buy": 40, "sell": 15},
	"straw_hat": {"name": "งอบ", "desc": "", "icon": "straw_hat", "tab": "equip", "slot": "head", "hp": 20.0, "buy": 35, "sell": 12},
	"pha_khao_ma": {"name": "ผ้าขาวม้า", "desc": "", "icon": "pha_khao_ma", "tab": "equip", "slot": "body", "hp": 30.0, "buy": 45, "sell": 15},
	"sandals": {"name": "รองเท้าหนัง", "desc": "", "icon": "sandals", "tab": "equip", "slot": "feet", "speed": 0.08, "buy": 40, "sell": 12},
	"amulet": {"name": "เหรียญนำโชค", "desc": "", "icon": "amulet", "tab": "equip", "slot": "charm", "atk": 2.0, "hp": 15.0, "buy": 150, "sell": 40},
	"tiger_fang": {"name": "เขี้ยวพญาเสือ", "desc": "ของหายากจากพญาเสือโคร่ง", "icon": "tiger_fang", "tab": "etc", "buy": 0, "sell": 0},
	"mist_horn": {"name": "เขาปิศาจหมอก", "desc": "", "icon": "mist_horn", "tab": "etc", "buy": 0, "sell": 0, "auntie": 60},
}
const POTION_HEAL := 50.0
# ของในร้านป้าศรี (เรียงตามที่แสดง)
const SHOP := ["potion", "big_potion", "wood_sword", "straw_hat", "pha_khao_ma", "sandals", "amulet"]
# ช่องอุปกรณ์สวมใส่ในหน้าตัวละคร: [รหัสช่อง, ชื่อที่แสดง]
const EQUIP_SLOTS := [["weapon", "อาวุธ"], ["head", "หมวก"], ["body", "ชุด"], ["feet", "รองเท้า"], ["charm", "เครื่องราง"]]
const MAX_LEVEL := 150  # เลเวลสูงสุด

# ---------- รางวัลจากมอนสเตอร์ ----------
# coins = [จำนวนเหรียญต่ำสุด, สูงสุด], coin_value = [มูลค่าต่อเหรียญต่ำสุด, สูงสุด], drops = [[ไอเทม, โอกาส 0..1], ...]
const REWARDS := {
	"frog": {"exp": 8, "coins": [1, 2], "coin_value": [2, 4], "drops": [["frog_leg", 0.4], ["potion", 0.012], ["straw_hat", 0.02], ["sandals", 0.02]]},
	"mushroom": {"exp": 18, "coins": [1, 3], "coin_value": [3, 6], "drops": [["mushroom_cap", 0.4], ["potion", 0.025], ["wood_sword", 0.03], ["pha_khao_ma", 0.03]]},
	"rat": {"exp": 300, "coins": [6, 6], "coin_value": [6, 10], "drops": [["potion", 1.0], ["sandals", 1.0]]},
	"mist_giant": {"exp": 700, "coins": [6, 9], "coin_value": [12, 18], "drops": [["mist_horn", 1.0], ["potion", 0.6]]},
	"tiger": {"exp": 900, "coins": [8, 8], "coin_value": [10, 14], "drops": [["tiger_fang", 1.0], ["potion", 1.0], ["amulet", 1.0]]},
}

var main: Node
var player: Player
var boss: Node  # บอสที่กำลังสู้อยู่ (ถ้ามี) ให้ HUD แสดงหลอดเลือด

var max_hp := 100.0
var hp := 100.0
var unlocked: Array = ["normal"]
var form_id := "normal"
var gender := "boy"      # "boy" หรือ "girl"
var player_name := ""    # ชื่อตัวละคร ("" = ยังไม่ได้สร้างตัวละคร)
var _girl_forms := {}

# เควสหลัก (ดู Quests.LIST): เควสลำดับที่เท่าไร / รับแล้วหรือยัง / ความคืบหน้า (นับตัวที่กำจัด หรือของที่คราฟ)
var quest_index := 0
var quest_accepted := false
var quest_progress := 0
var active_trial := ""  # นักษัตรที่กำลังประลองอยู่ ("" = ไม่มี)

# หมู่บ้าน: หมู่บ้านที่ N มีเลเวลตัน N x 20 (ไปหมู่บ้านถัดไปได้เมื่อได้ใบเบิกทางจากเควส)
var village := 1
var travel_permit := 1  # หมู่บ้านไกลสุดที่มีใบเบิกทางแล้ว
var zodiac_gifts: Array = []  # นักษัตรที่มอบชิ้นส่วนให้แล้ว (ตัวละ 1 ชุด)
var craft_fails := {}  # ของเซ็ทนักษัตร -> จำนวนครั้งที่ตีพัง (ยิ่งพังบ่อย ครั้งต่อไปยิ่งง่าย)
const VILLAGE_CAP := 20

# เลเวล: ทุกเลเวล เลือดสูงสุด +15 และพลังโจมตี +10%
var level := 1
var exp := 0
var money := 0
var items := {"potion": 2, "wood_sword": 1}  # รหัสไอเทม -> จำนวน
var equipped := {}  # รหัสช่อง -> รหัสไอเทมที่สวมอยู่
const HOTBAR_SIZE := 7
var hotbar: Array = ["", "", "", "", "", "", ""]  # ช่องไอเทม 1-7 (รหัสไอเทม หรือ "" = ว่าง)

var pending_crit := false  # ดาเมจที่เพิ่งคิดเป็นคริติคอลไหม (Player ตั้ง, hit_enemies ใช้แล้วล้าง)
var hit_is_crit := false   # ระหว่างตีโดนแต่ละตัว: เป็นคริติคอลไหม (ให้ตัวเลขดาเมจใหญ่ขึ้น)
const BASE_CRIT := 0.08  # โอกาสคริติคอลพื้นฐาน 8%
var in_dialogue := false
var in_title := false  # กำลังแสดงหน้าปกเกม (ล็อกการควบคุม)
var _dialogue_done := Callable()
var _stopping := false
var _dialogue_end_frame := -100


func _ready() -> void:
	_setup_input()
	ITEMS.merge(Crafting.generated_items())
	load_game()


func _setup_input() -> void:
	# ปุ่ม: ลูกศรเดิน, Space กระโดด, Shift วิ่งไว, C โจมตี, A S D สกิล, ↑ คุย/เข้าประตู, Q E สลับร่าง, F ดื่มยา, I กระเป๋า
	_add_action("move_left", [KEY_LEFT])
	_add_action("move_right", [KEY_RIGHT])
	_add_action("move_down", [KEY_DOWN])
	_add_action("jump", [KEY_SPACE])
	_add_action("run", [KEY_SHIFT])
	_add_action("attack", [KEY_C])
	_add_action("skill_1", [KEY_A])
	_add_action("skill_2", [KEY_S])
	_add_action("skill_3", [KEY_D])
	_add_action("interact", [KEY_UP])
	_add_action("form_prev", [KEY_Q])
	_add_action("form_next", [KEY_E])
	_add_action("use_potion", [KEY_F])
	_add_action("bag", [KEY_I, KEY_B])
	_add_action("mute", [KEY_M])
	for i in HOTBAR_SIZE:
		_add_action("slot_%d" % (i + 1), [KEY_1 + i])


func _add_action(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)


# ---------- ร่าง ----------

## ข้อมูลร่างปัจจุบัน — ถ้าเป็นตัวเอกหญิง จะเปลี่ยนภาพเป็นชุด heroine_ ให้อัตโนมัติ
func current_form() -> Dictionary:
	return form_for(form_id)


func form_for(id: String) -> Dictionary:
	var f := Forms.get_form(id)
	if gender != "girl":
		return f
	if not _girl_forms.has(id):
		var g: Dictionary = f.duplicate(true)
		for key in ["sprite", "frames"]:
			var path: String = g["outfit"].get(key, "")
			if path != "":
				g["outfit"][key] = path.replace("/hero_", "/heroine_")
		_girl_forms[id] = g
	return _girl_forms[id]


# ---------- ตัวละครของผู้เล่น (เพศ + ชื่อ) ----------

func has_profile() -> bool:
	return player_name != ""


func set_profile(new_gender: String, new_name: String) -> void:
	gender = "girl" if new_gender == "girl" else "boy"
	player_name = new_name.strip_edges().left(12)
	save_game()
	form_changed.emit()
	stats_changed.emit()


func set_form(id: String) -> void:
	if id in unlocked and id != form_id:
		form_id = id
		form_changed.emit()


func unlock_form(id: String) -> bool:
	if id in unlocked:
		return false
	unlocked.append(id)
	form_changed.emit()
	save_game()
	return true


# ---------- HP ----------

func set_hp(value: float) -> void:
	hp = clampf(value, 0.0, max_hp)
	hp_changed.emit()


# ---------- ต่อสู้ ----------

## ตีศัตรูทุกตัวที่อยู่ในกรอบ rect คืนค่าจำนวนตัวที่โดน
## (ถ้าดาเมจนี้เป็นคริติคอล — pending_crit ที่ Player ตั้งไว้ตอนคิดดาเมจ — จะมีเอฟเฟกต์พิเศษ)
func hit_enemies(rect: Rect2, dmg: float, from_x: float, stun := 0.0, skip: Array = []) -> int:
	var count := 0
	var crit := pending_crit
	pending_crit = false
	hit_is_crit = crit
	for e in get_tree().get_nodes_in_group("enemies"):
		if e in skip or not e.is_alive():
			continue
		if rect.intersects(e.get_hurt_rect()):
			var hr: Rect2 = e.get_hurt_rect()
			e.take_hit(dmg, signf(e.global_position.x - from_x), stun)
			skip.append(e)
			count += 1
			if crit:
				_crit_fx(Vector2(hr.get_center().x, hr.position.y + hr.size.y * 0.35))
	hit_is_crit = false
	if crit and count > 0:
		Sound.play("heavy_hit", 0.05)
		shake(9.0, 0.22)
		hit_stop(0.09)
	return count


## เอฟเฟกต์ตีคริติคอล: แสงระเบิดสีทอง วงคลื่น ดาวกระจาย และคำว่า CRITICAL!
func _crit_fx(pos: Vector2) -> void:
	if main == null or main.stage == null:
		return
	var parent: Node = main.stage
	Fx.spawn(parent, pos, "ring", Vector2(170, 170), Color(1.0, 0.75, 0.2), 1, 0.4)
	Fx.spawn(parent, pos, "burst", Vector2(90, 18), Color(1.0, 0.92, 0.55), 1, 0.35)
	Fx.spawn(parent, pos, "spark", Vector2(110, 110), Color(1.0, 0.55, 0.15), 1, 0.3)
	Fx.spawn(parent, pos + Vector2(0, 10), "star", Vector2(70, 150), Color(1.0, 0.85, 0.3), 1, 0.7)
	spawn_text(pos + Vector2(-95, -70), "CRITICAL!", Color(1.0, 0.62, 0.15), 40)


## สั่นจอ (amount = ความแรงเป็นพิกเซล)
func shake(amount: float, time := 0.2) -> void:
	if player and is_instance_valid(player):
		player.shake(amount, time)


## หยุดภาพชั่วพริบตาตอนตีโดน ให้รู้สึกหนักมือ
func hit_stop(time := 0.05) -> void:
	if _stopping:
		return
	_stopping = true
	Engine.time_scale = 0.05
	await get_tree().create_timer(time, true, false, true).timeout
	Engine.time_scale = 1.0
	_stopping = false


## ข้อความเด้งกลางฉาก เช่น "โฮก!"
func spawn_text(pos: Vector2, text: String, color: Color, font_size := 44) -> void:
	spawn_number(pos, text, color, font_size)


func spawn_number(pos: Vector2, text: String, color: Color, font_size := 26) -> void:
	if main == null:
		return
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.05))
	label.add_theme_constant_override("outline_size", 6)
	label.z_index = 50
	label.position = pos + Vector2(randf_range(-20, 10), -30)
	main.world.add_child(label)
	# เด้งโตขึ้นแล้วหดกลับ ก่อนลอยขึ้นและจางหาย
	label.pivot_offset = Vector2(font_size * 0.4, font_size * 0.6)
	label.scale = Vector2(0.4, 0.4)
	label.create_tween().tween_property(label, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var tw := label.create_tween().set_parallel(true)
	tw.tween_property(label, "position:y", label.position.y - 60.0, 0.7)
	tw.tween_property(label, "modulate:a", 0.0, 0.7).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(label.queue_free)


# ---------- เควส ----------

func quest_text() -> String:
	if active_trial != "":
		return "เควส: ประลองกับ %s" % Zodiac.display_name(Zodiac.get_data(active_trial))
	var q := current_quest()
	if q.is_empty():
		return "เควส: หมู่บ้านถัดไป เร็ว ๆ นี้"
	if not quest_accepted:
		return "เควส: ไปพบผู้ใหญ่บ้านที่บ้านผู้ใหญ่บ้าน"
	if q["type"] == "travel":
		return "เควส: เดินทางไปหมู่บ้านถัดไป (ประตูซ้ายสุดของหมู่บ้าน)"
	if Quests.is_done(q):
		return "เควส: กลับไปส่งเควสกับผู้ใหญ่บ้าน"
	if q["type"] == "zodiac":
		var z := Zodiac.get_data(q["target"])
		if level < int(z["level"]):
			return "เควส: ฝึกให้ถึง Lv.%d เพื่อพบ %s" % [int(z["level"]), Zodiac.display_name(z)]
		return "เควส: ไปประลองกับ %s ที่บ้านผู้ใหญ่บ้าน" % Zodiac.display_name(z)
	var prog := Quests.progress_text(q)
	return "เควส: %s%s" % [q["title"], " " + prog if prog != "" else ""]


func current_quest() -> Dictionary:
	return Quests.get_quest(quest_index)


## รับเควสปัจจุบัน
func accept_quest() -> void:
	var q := current_quest()
	if q.is_empty() or quest_accepted:
		return
	quest_accepted = true
	quest_progress = 0
	if q["type"] == "travel":
		travel_permit = maxi(travel_permit, int(q["target"]))
	Sound.play("quest")
	banner.emit("รับเควส: %s" % q["title"])
	quest_changed.emit()
	save_game()


## ส่งเควสที่ทำครบแล้ว: ให้รางวัล แล้วขยับไปเควสถัดไป คืนค่า true ถ้าส่งได้
func turn_in_quest() -> bool:
	var q := current_quest()
	if q.is_empty() or not quest_accepted or not Quests.is_done(q) or q["type"] == "travel":
		return false
	if q["type"] == "collect":
		add_item(q["target"], -int(q["n"]))
	var r: Dictionary = q.get("reward", {})
	var parts: Array = []
	if r.has("money"):
		add_money(int(r["money"]))
		parts.append("%d บาท" % int(r["money"]))
	for id in r.get("items", {}):
		add_item(id, int(r["items"][id]))
		parts.append("%s x%d" % [ITEMS[id]["name"], int(r["items"][id])])
	if r.has("exp"):
		parts.append("%d EXP" % int(r["exp"]))
	quest_index += 1
	quest_accepted = false
	quest_progress = 0
	Sound.play("quest")
	banner.emit("ส่งเควสสำเร็จ!%s" % ("\n" + "  ".join(parts) if not parts.is_empty() else ""))
	if r.has("exp"):
		add_exp(int(r["exp"]))
	quest_changed.emit()
	save_game()
	return true


## นับความคืบหน้าเควส (ชนิด kill / craft) และบอกเมื่อครบ
func _quest_count(kind: String, target := "") -> void:
	var q := current_quest()
	if q.is_empty() or not quest_accepted or q["type"] != kind or (target != "" and q.get("target", "") != target):
		return
	if Quests.is_done(q):
		return
	quest_progress += 1
	if Quests.is_done(q):
		banner.emit("%s ครบแล้ว! กลับไปหาผู้ใหญ่บ้าน" % q["title"])
	quest_changed.emit()
	save_game()


## เลเวลตันของหมู่บ้านที่อยู่ตอนนี้
func level_cap() -> int:
	return mini(village * VILLAGE_CAP, MAX_LEVEL)


## เริ่มประลองกับนักษัตร: พาไปลานประลองของตัวนั้น
func start_trial(id: String) -> void:
	var z := Zodiac.get_data(id)
	if z.is_empty() or main == null:
		return
	active_trial = id
	quest_changed.emit()
	main.change_stage(z["arena"], "entrance")


# ---------- เลเวล ----------

func exp_needed() -> int:
	return 40 + (level - 1) * 35


func atk_mult() -> float:
	return 1.0 + (level - 1) * 0.1


func _apply_level() -> void:
	max_hp = 100.0 + (level - 1) * 15.0 + equip_bonus("hp")


# ---------- อุปกรณ์สวมใส่ ----------

## ผลรวมค่าพลังจากอุปกรณ์ที่สวมอยู่ (stat = "atk" / "hp" / "speed") รวมโบนัสเซ็ทนักษัตร
func equip_bonus(stat: String) -> float:
	var total := 0.0
	for slot in equipped:
		total += float(ITEMS[equipped[slot]].get(stat, 0.0))
	return total + set_effect(stat)


## จำนวนชิ้นของเซ็ทนักษัตรแต่ละตัวที่สวมอยู่ {"rat": 3, ...}
func set_counts() -> Dictionary:
	var counts := {}
	for slot in equipped:
		var z: String = ITEMS[equipped[slot]].get("set", "")
		if z != "":
			counts[z] = int(counts.get(z, 0)) + 1
	return counts


## ค่าความสามารถพิเศษจากเซ็ท (speed, hp, atk_mult, dodge, cd_mult, dmg_taken, no_knock, crit)
## cd_mult / dmg_taken เป็นตัวคูณ (ไม่มีเซ็ท = 1) ตัวอื่นเป็นค่าบวกเพิ่ม (ไม่มี = 0)
func set_effect(stat: String) -> float:
	var mult_stat := stat in ["cd_mult", "dmg_taken"]
	var value := 1.0 if mult_stat else 0.0
	var counts := set_counts()
	for z in counts:
		var s: Dictionary = Crafting.SETS.get(z, {})
		for need in [3, 5]:
			if int(counts[z]) >= need and s.get("bonus%d" % need, {}).has(stat):
				var v := float(s["bonus%d" % need][stat])
				value = value * v if mult_stat else value + v
	return value


## สวมอุปกรณ์จากกระเป๋า (ของเดิมในช่องนั้นกลับเข้ากระเป๋า) คืนค่า true ถ้าสวมได้
func equip(id: String) -> bool:
	if not ITEMS.has(id) or not ITEMS[id].has("slot") or item_count(id) <= 0:
		return false
	var slot: String = ITEMS[id]["slot"]
	var old: String = equipped.get(slot, "")
	items[id] = item_count(id) - 1
	if items[id] <= 0:
		items.erase(id)
	if old != "":
		items[old] = item_count(old) + 1
	equipped[slot] = id
	_after_equip_change()
	return true


## ถอดอุปกรณ์ออกจากช่อง กลับเข้ากระเป๋า
func unequip(slot: String) -> void:
	var old: String = equipped.get(slot, "")
	if old == "":
		return
	equipped.erase(slot)
	items[old] = item_count(old) + 1
	_after_equip_change()


func _after_equip_change() -> void:
	_apply_level()
	set_hp(minf(hp, max_hp))
	stats_changed.emit()
	save_game()


func add_exp(amount: int) -> void:
	var cap := level_cap()
	if level >= cap:
		# เลเวลตันของหมู่บ้านนี้: EXP เต็มหลอดค้างไว้ จนกว่าจะไปหมู่บ้านถัดไป
		exp = 0 if level >= MAX_LEVEL else exp_needed()
		stats_changed.emit()
		return
	exp += amount
	var leveled := false
	while level < cap and exp >= exp_needed():
		exp -= exp_needed()
		level += 1
		leveled = true
	if level >= MAX_LEVEL:
		exp = 0
	elif level >= cap:
		exp = exp_needed()
	if leveled:
		quest_changed.emit()  # เลเวลถึงแล้วเควสนักษัตรอาจเปลี่ยน
		_apply_level()
		set_hp(max_hp)
		if level >= cap and level < MAX_LEVEL:
			banner.emit("เลเวลตันแล้ว! Lv.%d\nทำเควสให้ครบ แล้วเดินทางไปหมู่บ้านถัดไป" % level)
		else:
			banner.emit("เลเวลอัป! Lv.%d\nเลือดสูงสุด %d  พลังโจมตี +%d%%" % [level, int(max_hp), int(round((atk_mult() - 1.0) * 100.0))])
		if player and is_instance_valid(player):
			player.on_level_up()
	stats_changed.emit()
	save_game()


# ---------- เงินและไอเทม ----------

func add_money(amount: int) -> void:
	money = maxi(money + amount, 0)
	stats_changed.emit()
	save_game()


func item_count(id: String) -> int:
	return int(items.get(id, 0))


func add_item(id: String, amount := 1) -> void:
	items[id] = maxi(item_count(id) + amount, 0)
	if items[id] == 0:
		items.erase(id)
	var q := current_quest()
	if quest_accepted and q.get("type", "") == "collect" and q["target"] == id:
		quest_changed.emit()  # เควสหาของ: อัปเดตตัวนับ
	stats_changed.emit()
	save_game()


# ---------- คราฟของ (ช่างตีเหล็ก) ----------

func open_crafting() -> void:
	crafting_opened.emit()


## ของพอคราฟสูตรนี้ไหม (recipe = รายการจาก Crafting.recipe_list())
func can_craft(recipe: Dictionary) -> bool:
	if money < int(recipe["cost"]):
		return false
	for id in recipe["mats"]:
		if item_count(id) < int(recipe["mats"][id]):
			return false
	return true


## คราฟของ คืนค่ารหัสไอเทมที่ได้ ("" = ของไม่พอ, "FAIL" = ตีของเซ็ทพัง)
## ของทั่วไปสุ่มคุณภาพ ของเซ็ทนักษัตรมีโอกาสพัง (เสียของกับเงิน แต่ชิ้นส่วนนักษัตรยังอยู่)
func craft(recipe: Dictionary, force_success := false) -> String:
	if not can_craft(recipe):
		return ""
	money -= int(recipe["cost"])
	var zodiac: String = recipe["zodiac"]
	var success := zodiac == "" or force_success or randf() < Crafting.set_chance(int(craft_fails.get(recipe["key"], 0)))
	for id in recipe["mats"]:
		if not success and str(id).begins_with("zpart_"):
			continue  # ตีพัง: ชิ้นส่วนนักษัตรไม่หาย
		items[id] = item_count(id) - int(recipe["mats"][id])
		if items[id] <= 0:
			items.erase(id)
	if not success:
		craft_fails[recipe["key"]] = int(craft_fails.get(recipe["key"], 0)) + 1
		stats_changed.emit()
		save_game()
		return "FAIL"
	craft_fails.erase(recipe["key"])
	var out: String = recipe["key"] if recipe["zodiac"] != "" else "%s__q%d" % [recipe["key"], Crafting.roll_quality()]
	items[out] = item_count(out) + 1
	_quest_count("craft")
	stats_changed.emit()
	save_game()
	return out


## ใส่ไอเทมลงช่อง 1-7 (id = "" คือเอาออก) ไอเทมเดียวกันอยู่ได้ช่องเดียว
func set_hotbar(index: int, id: String) -> void:
	if index < 0 or index >= HOTBAR_SIZE:
		return
	if id != "":
		for i in HOTBAR_SIZE:
			if hotbar[i] == id:
				hotbar[i] = hotbar[index]  # สลับที่กับของเดิมในช่องปลายทาง
	hotbar[index] = id
	stats_changed.emit()
	save_game()


## กดใช้ไอเทมในช่อง 1-7
func use_hotbar(index: int) -> void:
	var id: String = hotbar[index]
	if id == "" or player == null or player.dead:
		return
	if item_count(id) <= 0:
		banner.emit("%s หมดแล้ว" % ITEMS[id]["name"])
		return
	player.use_item(id)


## ดื่มยา (ยาแดง / ยาแดงขวดใหญ่) คืนค่า true ถ้าดื่มได้
func use_potion(id := "potion") -> bool:
	if item_count(id) <= 0 or hp >= max_hp or hp <= 0.0:
		return false
	add_item(id, -1)
	set_hp(hp + float(ITEMS[id].get("heal", POTION_HEAL)))
	return true


func open_shop() -> void:
	shop_opened.emit()


## ซื้อไอเทม 1 ชิ้น คืนค่า true ถ้าเงินพอ
func buy_item(id: String) -> bool:
	var price := int(ITEMS[id]["buy"])
	if price <= 0 or money < price:
		return false
	money -= price
	add_item(id, 1)
	return true


## ราคาที่ป้าศรีรับซื้อ (0 = ขายไม่ได้): ขายได้ทุกอย่าง ยกเว้นชิ้นส่วนนักษัตร (ของทำเซ็ท)
## ของที่มีราคาขายใช้ราคานั้น ของจากร้านคืนครึ่งราคา ของอื่น ๆ (เช่น ของเซ็ท) ให้ราคาตามความหายาก
func sell_price(id: String) -> int:
	if id.begins_with("zpart_") or not ITEMS.has(id):
		return 0
	var info: Dictionary = ITEMS[id]
	if int(info.get("auntie", 0)) > 0:
		return int(info["auntie"])  # ของที่ลุงหมูไม่รับ แต่ป้าศรีรับ
	if int(info.get("sell", 0)) > 0:
		return int(info["sell"])
	if int(info.get("buy", 0)) > 0:
		return maxi(int(info["buy"]) / 2, 1)
	if int(info.get("quality", 0)) == 5:
		return 300
	return 20


## ขายไอเทมให้ป้าศรี amount ชิ้น (-1 = ขายหมด) คืนค่าเงินที่ได้
func sell_item(id: String, amount := 1) -> int:
	var price := sell_price(id)
	var n := item_count(id) if amount < 0 else mini(amount, item_count(id))
	if price <= 0 or n <= 0:
		return 0
	items[id] = item_count(id) - n
	if items[id] <= 0:
		items.erase(id)
		for i in HOTBAR_SIZE:
			if hotbar[i] == id:
				hotbar[i] = ""
	add_money(price * n)  # (add_money เซฟให้แล้ว)
	return price * n


## ขายของดรอปทั้งหมดที่ขายได้ (เฉพาะแท็บทั่วไป ไม่ขายอุปกรณ์) คืนค่าเงินที่ได้
func sell_materials() -> int:
	var total := 0
	for id in items.keys():
		var price := int(ITEMS[id]["sell"])
		if price > 0 and ITEMS[id].get("tab", "") == "etc":
			total += price * item_count(id)
			items.erase(id)
	if total > 0:
		add_money(total)
	return total


## ให้ EXP และโปรยของดรอปตรงจุดที่ศัตรูตาย
func give_rewards(kind: String, pos: Vector2, exp_mult := 1.0) -> void:
	if not REWARDS.has(kind):
		return
	var r: Dictionary = REWARDS[kind]
	var gained := int(round(float(r["exp"]) * exp_mult))  # มอนสเตอร์เลเวลสูงให้ EXP มากขึ้น
	add_exp(gained)
	if main == null or main.stage == null:
		return
	spawn_number(pos + Vector2(-10, -70), "+%d EXP" % gained, Color(0.7, 0.9, 1.0), 20)
	for i in randi_range(int(r["coins"][0]), int(r["coins"][1])):
		Pickup.spawn(main.stage, pos, "coin", randi_range(int(r["coin_value"][0]), int(r["coin_value"][1])))
	for d in r["drops"]:
		if randf() < float(d[1]):
			Pickup.spawn(main.stage, pos, d[0], 1)


func on_enemy_killed(kind: String, pos := Vector2.INF, exp_mult := 1.0) -> void:
	if pos != Vector2.INF:
		give_rewards(kind, pos, exp_mult)
	_quest_count("kill", kind)


func on_boss_defeated(id: String, pos := Vector2.INF) -> void:
	boss = null
	if pos != Vector2.INF:
		give_rewards(id, pos)
	var z := Zodiac.get_data(id)
	active_trial = ""
	if z.is_empty():
		# บอสปิศาจ: ไม่ได้ร่างใหม่ แต่ได้ EXP และของเยอะ กลับมาตีซ้ำได้
		var demon: Dictionary = ZodiacBoss.DEMONS.get(id, {})
		banner.emit("ปราบ %s ได้แล้ว!" % demon.get("name", id))
		_quest_count("kill", id)
		save_game()
		return
	_give_zodiac_parts(id)
	var form := Forms.get_form(id)
	if unlock_form(id):
		banner.emit("ผ่านการประลอง!\nได้ %s — กด Q / E เพื่อสลับร่าง" % form["name"])
	else:
		banner.emit("ผ่านการประลอง!")
	start_dialogue([{"who": z["year"], "text": z["win"]}])
	quest_changed.emit()
	save_game()


## นักษัตรมอบชิ้นส่วนให้ 1 ชุด (เขี้ยว หัว หนัง เท้า หาง) เอาไปให้ช่างตีเป็นชุดเซ็ทนักษัตร
func _give_zodiac_parts(id: String) -> void:
	if id in zodiac_gifts or not Crafting.SETS.has(id):
		return
	zodiac_gifts.append(id)
	for p in Crafting.PARTS:
		var pid := Crafting.part_id(id, p[0])
		items[pid] = item_count(pid) + 1


func player_died() -> void:
	if main:
		main.on_player_died()


# ---------- บทสนทนา ----------

## lines = [{"who": "ชื่อคนพูด", "text": "ข้อความ"}, ...]
func start_dialogue(lines: Array, on_done := Callable()) -> void:
	if in_dialogue or lines.is_empty():
		return
	in_dialogue = true
	_dialogue_done = on_done
	Sound.play("talk", 0.04)
	dialogue_started.emit(lines)


## เพิ่งปิดบทสนทนาไปหมาด ๆ (กันปุ่มที่กดปิดไปสั่งคุยซ้ำหรือโจมตีทันที)
func dialogue_just_ended() -> bool:
	return Engine.get_physics_frames() - _dialogue_end_frame < 14


func end_dialogue() -> void:
	in_dialogue = false
	_dialogue_end_frame = Engine.get_physics_frames()
	var cb := _dialogue_done
	_dialogue_done = Callable()
	dialogue_finished.emit()
	if cb.is_valid():
		cb.call()


# ---------- เซฟ ----------

func save_game() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("game", "unlocked", unlocked)
	cfg.set_value("game", "gender", gender)
	cfg.set_value("game", "player_name", player_name)
	cfg.set_value("game", "quest_index", quest_index)
	cfg.set_value("game", "quest_accepted", quest_accepted)
	cfg.set_value("game", "quest_progress", quest_progress)
	cfg.set_value("game", "village", village)
	cfg.set_value("game", "travel_permit", travel_permit)
	cfg.set_value("game", "zodiac_gifts", zodiac_gifts)
	cfg.set_value("game", "craft_fails", craft_fails)
	cfg.set_value("game", "level", level)
	cfg.set_value("game", "exp", exp)
	cfg.set_value("game", "money", money)
	cfg.set_value("game", "items", items)
	cfg.set_value("game", "hotbar", hotbar)
	cfg.set_value("audio", "muted", Sound.muted)
	cfg.set_value("game", "equipped", equipped)
	cfg.set_value("game", "starter_gear", true)
	cfg.save(SAVE_PATH)


func load_game() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	gender = "girl" if cfg.get_value("game", "gender", "boy") == "girl" else "boy"
	player_name = str(cfg.get_value("game", "player_name", ""))
	var saved: Array = cfg.get_value("game", "unlocked", ["normal"])
	unlocked = ["normal"]
	for id in saved:
		if id != "normal" and Forms.get_form(id)["id"] == id:
			unlocked.append(id)
	if cfg.has_section_key("game", "quest_index"):
		quest_index = int(cfg.get_value("game", "quest_index", 0))
		quest_accepted = bool(cfg.get_value("game", "quest_accepted", false))
		quest_progress = int(cfg.get_value("game", "quest_progress", 0))
	else:
		# เซฟระบบเควสเก่า: 0 ยังไม่คุย / 1 ตีกบ / 2 รายงาน / 3+ ช่วงนักษัตร
		var old := int(cfg.get_value("game", "quest_stage", 0))
		quest_index = 0 if old < 3 else 1
		quest_accepted = old in [1, 2]
		quest_progress = int(cfg.get_value("game", "frog_kills", 0)) if old == 1 else (5 if old == 2 else 0)
	village = maxi(int(cfg.get_value("game", "village", 1)), 1)
	travel_permit = maxi(int(cfg.get_value("game", "travel_permit", 1)), village)
	zodiac_gifts = cfg.get_value("game", "zodiac_gifts", [])
	craft_fails = cfg.get_value("game", "craft_fails", {})
	level = clampi(int(cfg.get_value("game", "level", 1)), 1, MAX_LEVEL)
	exp = int(cfg.get_value("game", "exp", 0))
	money = int(cfg.get_value("game", "money", 0))
	items = {}
	var saved_items: Dictionary = cfg.get_value("game", "items", {"potion": 2})
	for id in saved_items:
		if ITEMS.has(id):
			items[id] = int(saved_items[id])
	Sound.set_muted(bool(cfg.get_value("audio", "muted", false)))
	equipped = {}
	var saved_equip: Dictionary = cfg.get_value("game", "equipped", {})
	for slot in saved_equip:
		if ITEMS.has(saved_equip[slot]) and ITEMS[saved_equip[slot]].get("slot", "") == slot:
			equipped[slot] = saved_equip[slot]
	if not cfg.get_value("game", "starter_gear", false):
		items["wood_sword"] = item_count("wood_sword") + 1  # เซฟเก่า: แจกดาบไม้เริ่มต้น 1 เล่ม
	var saved_bar: Array = cfg.get_value("game", "hotbar", [])
	for i in mini(saved_bar.size(), HOTBAR_SIZE):
		hotbar[i] = saved_bar[i] if ITEMS.has(saved_bar[i]) else ""
	# เซฟเก่าที่ชนะนักษัตรไปก่อนมีระบบคราฟ: ให้ชิ้นส่วนย้อนหลัง
	for id in unlocked:
		_give_zodiac_parts(id)
	_apply_level()
	hp = max_hp


func reset_save() -> void:
	gender = "boy"
	player_name = ""
	unlocked = ["normal"]
	form_id = "normal"
	quest_index = 0
	quest_accepted = false
	quest_progress = 0
	village = 1
	travel_permit = 1
	zodiac_gifts = []
	craft_fails = {}
	active_trial = ""
	level = 1
	exp = 0
	money = 0
	items = {"potion": 2, "wood_sword": 1}
	equipped = {}
	hotbar = ["", "", "", "", "", "", ""]
	_apply_level()
	hp = max_hp
	save_game()
	hp_changed.emit()
	stats_changed.emit()
	form_changed.emit()
	quest_changed.emit()
