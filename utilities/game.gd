extends Node
## ตัวกลางของเกม (autoload ชื่อ Game): เก็บ HP, ร่างที่ปลดล็อก, เควส, เซฟ และฟังก์ชันต่อสู้กลาง

signal hp_changed
signal form_changed
signal quest_changed
signal banner(text: String)
signal dialogue_started(lines: Array)
signal dialogue_finished

const SAVE_PATH := "user://save.cfg"
const FROGS_NEEDED := 5

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

var in_dialogue := false
var _dialogue_done := Callable()


func _ready() -> void:
	_setup_input()
	load_game()


func _setup_input() -> void:
	# ปุ่ม: ลูกศรเดิน, Space กระโดด, Shift วิ่งไว, C โจมตี, A S D สกิล, ↑ คุย/เข้าประตู, Q E สลับร่าง
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


func spawn_number(pos: Vector2, text: String, color: Color) -> void:
	if main == null:
		return
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 26)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.05))
	label.add_theme_constant_override("outline_size", 6)
	label.z_index = 50
	label.position = pos + Vector2(randf_range(-20, 10), -30)
	main.world.add_child(label)
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
	quest_changed.emit()
	save_game()


func on_enemy_killed(kind: String) -> void:
	if quest_stage == 1 and kind == "frog":
		frog_kills += 1
		if frog_kills >= FROGS_NEEDED:
			banner.emit("กำจัดกบนาครบแล้ว! กลับไปหาผู้ใหญ่บ้าน")
			set_quest_stage(2)
		else:
			quest_changed.emit()
			save_game()


func on_boss_defeated(id: String) -> void:
	boss = null
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
	dialogue_started.emit(lines)


func end_dialogue() -> void:
	in_dialogue = false
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


func reset_save() -> void:
	unlocked = ["normal"]
	form_id = "normal"
	quest_stage = 0
	frog_kills = 0
	save_game()
	form_changed.emit()
	quest_changed.emit()
