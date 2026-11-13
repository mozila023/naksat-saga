extends Node
## ตัวกลางของเกม (autoload ชื่อ Game): เก็บ HP, ร่างที่ปลดล็อก, เควส, เซฟ และฟังก์ชันต่อสู้กลาง

signal hp_changed
signal form_changed
signal quest_changed
signal stats_changed  # เลเวล / EXP / เงิน / ไอเทม เปลี่ยน
signal banner(text: String)
signal dialogue_started(lines: Array)
signal dialogue_finished

const SAVE_PATH := "user://save.cfg"
const FROGS_NEEDED := 5

# ---------- ไอเทม ----------
# tab = แท็บในกระเป๋า (equip อุปกรณ์สวมใส่ / item ไอเทม / etc ทั่วไป)
# buy = ราคาซื้อจากป้าศรี (0 = ไม่มีขาย), sell = ราคาที่ลุงหมูรับซื้อ (0 = ไม่รับซื้อ)
const ITEMS := {
	"potion": {"name": "ยาแดง", "desc": "ฟื้นเลือด 50 (กด F เพื่อดื่ม)", "icon": "potion", "tab": "item", "buy": 20, "sell": 0},
	"frog_leg": {"name": "ขากบ", "desc": "ได้จากกบนา ขายให้ลุงหมูได้", "icon": "frog_leg", "tab": "etc", "buy": 0, "sell": 6},
	"mushroom_cap": {"name": "หมวกเห็ดพิษ", "desc": "ได้จากเห็ดพิษ ขายให้ลุงหมูได้", "icon": "mushroom_cap", "tab": "etc", "buy": 0, "sell": 12},
	# อุปกรณ์สวมใส่: slot = ช่องที่ใส่, atk = พลังโจมตีเพิ่ม, hp = เลือดสูงสุดเพิ่ม, speed = ความเร็วเพิ่ม (0.08 = 8%)
	"wood_sword": {"name": "ดาบไม้", "desc": "", "icon": "wood_sword", "tab": "equip", "slot": "weapon", "atk": 3.0, "buy": 0, "sell": 15},
	"straw_hat": {"name": "งอบ", "desc": "", "icon": "straw_hat", "tab": "equip", "slot": "head", "hp": 20.0, "buy": 0, "sell": 12},
	"pha_khao_ma": {"name": "ผ้าขาวม้า", "desc": "", "icon": "pha_khao_ma", "tab": "equip", "slot": "body", "hp": 30.0, "buy": 0, "sell": 15},
	"sandals": {"name": "รองเท้าหนัง", "desc": "", "icon": "sandals", "tab": "equip", "slot": "feet", "speed": 0.08, "buy": 0, "sell": 12},
	"amulet": {"name": "เหรียญนำโชค", "desc": "", "icon": "amulet", "tab": "equip", "slot": "charm", "atk": 2.0, "hp": 15.0, "buy": 0, "sell": 40},
	"tiger_fang": {"name": "เขี้ยวพญาเสือ", "desc": "ของหายากจากพญาเสือโคร่ง", "icon": "tiger_fang", "tab": "etc", "buy": 0, "sell": 0},
}
const POTION_HEAL := 50.0
# ช่องอุปกรณ์สวมใส่ในหน้าตัวละคร: [รหัสช่อง, ชื่อที่แสดง]
const EQUIP_SLOTS := [["weapon", "อาวุธ"], ["head", "หมวก"], ["body", "ชุด"], ["feet", "รองเท้า"], ["charm", "เครื่องราง"]]
const MAX_LEVEL := 150  # เลเวลสูงสุด

# ---------- รางวัลจากมอนสเตอร์ ----------
# coins = [จำนวนเหรียญต่ำสุด, สูงสุด], coin_value = [มูลค่าต่อเหรียญต่ำสุด, สูงสุด], drops = [[ไอเทม, โอกาส 0..1], ...]
const REWARDS := {
	"frog": {"exp": 8, "coins": [1, 2], "coin_value": [2, 4], "drops": [["frog_leg", 0.4], ["potion", 0.012], ["straw_hat", 0.02], ["sandals", 0.02]]},
	"mushroom": {"exp": 18, "coins": [1, 3], "coin_value": [3, 6], "drops": [["mushroom_cap", 0.4], ["potion", 0.025], ["wood_sword", 0.03], ["pha_khao_ma", 0.03]]},
	"tiger": {"exp": 250, "coins": [8, 8], "coin_value": [10, 14], "drops": [["tiger_fang", 1.0], ["potion", 1.0], ["amulet", 1.0]]},
}

var main: Node
var player: Player
var boss: Node  # บอสที่กำลังสู้อยู่ (ถ้ามี) ให้ HUD แสดงหลอดเลือด

var max_hp := 100.0
var hp := 100.0
var unlocked: Array = ["normal"]
var form_id := "normal"

# ขั้นของเควสหลัก
# 0 ยังไม่รับ / 1 ตีกบ / 2 กลับไปรายงาน / 3 ไปปราบพญาเสือ / 4 กลับไปรายงาน / 5 จบ
var quest_stage := 0
var frog_kills := 0

# เลเวล: ทุกเลเวล เลือดสูงสุด +15 และพลังโจมตี +10%
var level := 1
var exp := 0
var money := 0
var items := {"potion": 2, "wood_sword": 1}  # รหัสไอเทม -> จำนวน
var equipped := {}  # รหัสช่อง -> รหัสไอเทมที่สวมอยู่
const HOTBAR_SIZE := 7
var hotbar: Array = ["", "", "", "", "", "", ""]  # ช่องไอเทม 1-7 (รหัสไอเทม หรือ "" = ว่าง)

var in_dialogue := false
var in_title := false  # กำลังแสดงหน้าปกเกม (ล็อกการควบคุม)
var _dialogue_done := Callable()
var _stopping := false
var _dialogue_end_frame := -100


func _ready() -> void:
	_setup_input()
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

func current_form() -> Dictionary:
	return Forms.get_form(form_id)


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
func hit_enemies(rect: Rect2, dmg: float, from_x: float, stun := 0.0, skip: Array = []) -> int:
	var count := 0
	for e in get_tree().get_nodes_in_group("enemies"):
		if e in skip or not e.is_alive():
			continue
		if rect.intersects(e.get_hurt_rect()):
			e.take_hit(dmg, signf(e.global_position.x - from_x), stun)
			skip.append(e)
			count += 1
	return count


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
	match quest_stage:
		0: return "เควส: ไปคุยกับผู้ใหญ่บ้านที่ศาลาประชาคม"
		1: return "เควส: กำจัดกบนาที่ทุ่งนา %d/%d" % [frog_kills, FROGS_NEEDED]
		2: return "เควส: กลับไปรายงานผู้ใหญ่บ้าน"
		3: return "เควส: ปราบพญาเสือโคร่งที่ถ้ำเสือ 0/1"
		4: return "เควส: กลับไปรายงานผู้ใหญ่บ้าน"
	return "เควสสำเร็จ! (บอสนักษัตรตัวต่อไป เร็ว ๆ นี้)"


func set_quest_stage(stage: int) -> void:
	quest_stage = stage
	if stage > 0:
		Sound.play("quest")
	quest_changed.emit()
	save_game()


# ---------- เลเวล ----------

func exp_needed() -> int:
	return 40 + (level - 1) * 35


func atk_mult() -> float:
	return 1.0 + (level - 1) * 0.1


func _apply_level() -> void:
	max_hp = 100.0 + (level - 1) * 15.0 + equip_bonus("hp")


# ---------- อุปกรณ์สวมใส่ ----------

## ผลรวมค่าพลังจากอุปกรณ์ที่สวมอยู่ (stat = "atk" / "hp" / "speed")
func equip_bonus(stat: String) -> float:
	var total := 0.0
	for slot in equipped:
		total += float(ITEMS[equipped[slot]].get(stat, 0.0))
	return total


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
	if level >= MAX_LEVEL:
		exp = 0
		return
	exp += amount
	var leveled := false
	while level < MAX_LEVEL and exp >= exp_needed():
		exp -= exp_needed()
		level += 1
		leveled = true
	if level >= MAX_LEVEL:
		exp = 0
	if leveled:
		_apply_level()
		set_hp(max_hp)
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
	stats_changed.emit()
	save_game()


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


## ดื่มยาแดง คืนค่า true ถ้าดื่มได้
func use_potion() -> bool:
	if item_count("potion") <= 0 or hp >= max_hp or hp <= 0.0:
		return false
	add_item("potion", -1)
	set_hp(hp + POTION_HEAL)
	return true


## ซื้อไอเทม 1 ชิ้น คืนค่า true ถ้าเงินพอ
func buy_item(id: String) -> bool:
	var price := int(ITEMS[id]["buy"])
	if price <= 0 or money < price:
		return false
	money -= price
	add_item(id, 1)
	return true


## ขายของดรอปทั้งหมดที่ขายได้ คืนค่าเงินที่ได้
func sell_materials() -> int:
	var total := 0
	for id in items.keys():
		var price := int(ITEMS[id]["sell"])
		if price > 0:
			total += price * item_count(id)
			items.erase(id)
	if total > 0:
		add_money(total)
	return total


## ให้ EXP และโปรยของดรอปตรงจุดที่ศัตรูตาย
func give_rewards(kind: String, pos: Vector2) -> void:
	if not REWARDS.has(kind):
		return
	var r: Dictionary = REWARDS[kind]
	add_exp(int(r["exp"]))
	if main == null or main.stage == null:
		return
	spawn_number(pos + Vector2(-10, -70), "+%d EXP" % int(r["exp"]), Color(0.7, 0.9, 1.0), 20)
	for i in randi_range(int(r["coins"][0]), int(r["coins"][1])):
		Pickup.spawn(main.stage, pos, "coin", randi_range(int(r["coin_value"][0]), int(r["coin_value"][1])))
	for d in r["drops"]:
		if randf() < float(d[1]):
			Pickup.spawn(main.stage, pos, d[0], 1)


func on_enemy_killed(kind: String, pos := Vector2.INF) -> void:
	if pos != Vector2.INF:
		give_rewards(kind, pos)
	if quest_stage == 1 and kind == "frog":
		frog_kills += 1
		if frog_kills >= FROGS_NEEDED:
			banner.emit("กำจัดกบนาครบแล้ว! กลับไปหาผู้ใหญ่บ้าน")
			set_quest_stage(2)
		else:
			quest_changed.emit()
			save_game()


func on_boss_defeated(id: String, pos := Vector2.INF) -> void:
	boss = null
	if pos != Vector2.INF:
		give_rewards(id, pos)
	if id == "tiger":
		if unlock_form("tiger"):
			banner.emit("ปราบพญาเสือโคร่งสำเร็จ!\nได้ร่างขาล (เสือ) — กด Q / E เพื่อสลับร่าง")
		else:
			banner.emit("ปราบพญาเสือโคร่งสำเร็จ!")
		if quest_stage == 3:
			set_quest_stage(4)


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
	cfg.set_value("game", "quest_stage", quest_stage)
	cfg.set_value("game", "frog_kills", frog_kills)
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
	var saved: Array = cfg.get_value("game", "unlocked", ["normal"])
	unlocked = ["normal"]
	for id in saved:
		if id != "normal" and Forms.get_form(id)["id"] == id:
			unlocked.append(id)
	quest_stage = int(cfg.get_value("game", "quest_stage", 0))
	frog_kills = int(cfg.get_value("game", "frog_kills", 0))
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
	_apply_level()
	hp = max_hp


func reset_save() -> void:
	unlocked = ["normal"]
	form_id = "normal"
	quest_stage = 0
	frog_kills = 0
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
