extends Node
## ทดสอบอัตโนมัติ: เล่นเควสตั้งแต่ต้นจนได้ร่างเสือ แล้วเก็บภาพหน้าจอ
## รัน: godot --path . res://tests/smoke.tscn  (ใส่ -- shots=โฟลเดอร์ เพื่อเก็บภาพ)

var main: Node
var fails := 0
var shot_dir := ""


func check(cond: bool, what: String) -> void:
	if cond:
		print("ok   - ", what)
	else:
		fails += 1
		print("FAIL - ", what)


func frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func shot(shot_name: String) -> void:
	if shot_dir == "":
		return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(shot_dir.path_join(shot_name + ".png"))


func tap(action: String) -> void:
	Input.action_press(action)
	await frames(3)
	Input.action_release(action)
	await frames(3)


func talk_through() -> void:
	await tap("interact")
	var guard := 0
	while Game.in_dialogue and guard < 30:
		await frames(15)
		await tap("interact")
		guard += 1


func kill_all(times: int) -> void:
	for i in times:
		Game.hit_enemies(Rect2(-1000, -2000, 20000, 4000), 9999.0, 0.0)
		await frames(5)


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("shots="):
			shot_dir = a.trim_prefix("shots=")
	Game.reset_save()
	main = load("res://main.tscn").instantiate()
	add_child(main)
	var p: Player = main.player
	await frames(20)
	check(Game.in_title and not main.hud.visible, "title screen shows first")
	await shot("00_title")
	var title_x := p.global_position.x
	Input.action_press("move_right")
	await frames(10)
	Input.action_release("move_right")
	check(absf(p.global_position.x - title_x) < 1.0, "player is locked on the title screen")
	main.start_game()
	await frames(40)
	check(not Game.in_title and main.hud.visible, "game starts after the title screen")
	check(main.stage_id == "village", "starts in village")
	check(p.is_on_floor(), "player lands on ground")
	await shot("01_village_start")

	var x0 := p.global_position.x
	Input.action_press("move_right")
	await frames(40)
	Input.action_release("move_right")
	check(p.global_position.x > x0 + 100.0, "player walks right")
	await tap("jump")
	await frames(5)
	check(not p.is_on_floor(), "player jumps")
	await frames(60)
	await tap("attack")
	for i in 3:
		p.use_skill(i)
		await frames(30)
	check(p.get_cd(2) > 0.0, "skill goes on cooldown")
	await tap("form_next")
	check(Game.form_id == "normal", "cannot switch form before unlocking")

	# เข้าบ้านผู้ใหญ่บ้านทางซุ้มประตู
	p.global_position.x = 2050.0
	await frames(30)
	await shot("02_village_gate")
	await tap("interact")
	await frames(60)
	check(main.stage_id == "chief_house", "gate leads into the chief's house")
	check(get_tree().get_nodes_in_group("interactables").filter(func(n: Node) -> bool: return n is ZodiacSpirit).is_empty(), "no zodiac spirit before the quest")
	p.global_position.x = 700.0
	await frames(30)
	await tap("interact")
	await frames(20)
	check(Game.in_dialogue, "dialogue opens")
	await shot("03_dialogue")
	Game.end_dialogue()
	main.hud._dialogue.visible = false
	Game.quest_stage = 0
	await frames(20)
	await talk_through()
	check(Game.quest_stage == 1, "quest 1 accepted (got %d)" % Game.quest_stage)
	p.global_position.x = 100.0
	await frames(20)
	await tap("interact")
	await frames(60)
	check(main.stage_id == "village", "house exit leads back to the village")

	p.global_position.x = 6240.0
	await frames(20)
	await tap("interact")
	await frames(60)
	check(main.stage_id == "rice_field", "portal to rice field")
	p.global_position.x = 1200.0
	await frames(90)
	await shot("04_rice_field")
	check(get_tree().get_nodes_in_group("enemies").size() >= 10, "monsters spawned")
	Input.action_press("attack")
	await frames(20)
	Input.action_release("attack")
	p.global_position.x = 9400.0
	await frames(20)
	await tap("interact")
	check(Game.in_dialogue, "boss cave locked before quest")
	Game.end_dialogue()
	main.hud._dialogue.visible = false
	await kill_all(2)
	check(Game.quest_stage == 2, "frog quest complete (stage %d, kills %d)" % [Game.quest_stage, Game.frog_kills])
	check(Game.level > 1, "kills give EXP and level up (Lv.%d)" % Game.level)
	check(Game.max_hp > 100.0, "level raises max HP")
	var keep_level := Game.level
	var keep_exp := Game.exp
	Game.add_exp(100000000)
	check(Game.level == Game.MAX_LEVEL, "level is capped at %d" % Game.MAX_LEVEL)
	Game.level = keep_level
	Game.exp = keep_exp
	Game._apply_level()
	Game.set_hp(Game.max_hp)
	Game.stats_changed.emit()
	var drops := get_tree().get_nodes_in_group("pickups")
	check(drops.size() > 0, "monsters drop pickups")
	var money_before := Game.money
	var guard := 0
	while Game.money == money_before and guard < 12:
		drops = get_tree().get_nodes_in_group("pickups").filter(func(d: Node) -> bool: return d.kind == "coin")
		if drops.is_empty():
			break
		p.global_position = drops[0].global_position
		p.velocity = Vector2.ZERO
		await frames(30)
		guard += 1
	check(Game.money > money_before, "coins can be picked up (%d baht)" % Game.money)
	Game.set_hp(10.0)
	var potions := Game.item_count("potion")
	await tap("use_potion")
	check(Game.hp > 10.0 and Game.item_count("potion") == potions - 1, "potion heals")
	await tap("bag")
	check(main.hud._bag.visible, "bag opens")
	await shot("04b_bag")
	# ช่องไอเทม 1-7: ลากจากกระเป๋ามาใส่ แล้วกดเลขเพื่อใช้
	var slot3 = main.hud._hot_slots[2]
	var row = main.hud._bag_list.get_child(0)
	check(Game.hotbar[2] == "", "hotbar starts empty")
	var drag := {"item": row.item}  # ข้อมูลเดียวกับที่ได้ตอนลากแถวในกระเป๋า
	check(slot3._can_drop_data(Vector2.ZERO, drag), "hotbar slot accepts a dragged item")
	slot3._drop_data(Vector2.ZERO, drag)
	check(Game.hotbar[2] == "potion", "dragged item lands in slot 3")
	main.hud._hot_slots[5]._drop_data(Vector2.ZERO, {"item": "potion", "from_slot": 2})
	check(Game.hotbar[5] == "potion" and Game.hotbar[2] == "", "item moves between slots")
	# อุปกรณ์สวมใส่: ลากดาบไม้จากกระเป๋าไปใส่ช่องอาวุธ
	check(Game.item_count("wood_sword") == 1, "starts with a wooden sword")
	var weapon_slot = main.hud._equip_slots[0]
	var atk_before := Game.equip_bonus("atk")
	check(weapon_slot._can_drop_data(Vector2.ZERO, {"item": "wood_sword"}), "weapon slot accepts a weapon")
	check(not weapon_slot._can_drop_data(Vector2.ZERO, {"item": "potion"}), "weapon slot rejects a potion")
	weapon_slot._drop_data(Vector2.ZERO, {"item": "wood_sword"})
	check(Game.equipped.get("weapon", "") == "wood_sword" and Game.item_count("wood_sword") == 0, "sword is equipped and leaves the bag")
	check(Game.equip_bonus("atk") > atk_before, "equipment raises attack")
	Game.add_item("straw_hat", 1)
	var hp_cap := Game.max_hp
	Game.equip("straw_hat")
	check(Game.max_hp > hp_cap, "hat raises max HP")
	Game.unequip("head")
	check(Game.max_hp == hp_cap and Game.item_count("straw_hat") == 1, "unequip returns the item")
	Game.add_item("straw_hat", -1)
	main.hud._set_bag_tab("equip")
	await shot("04d_equipment")
	main.hud._set_bag_tab("item")
	await shot("04c_hotbar")
	main.hud.toggle_bag()
	check(not main.hud._bag.visible, "bag closes")
	Game.add_item("potion", 1)
	Game.set_hp(10.0)
	await tap("slot_6")
	check(Game.hp > 10.0, "number key uses the slot item")
	Game.add_item("frog_leg", 3)
	Game.money = 100
	await frames(400)
	check(get_tree().get_nodes_in_group("enemies").size() >= 10, "monsters respawn")

	main.change_stage("chief_house", "entrance")
	await frames(60)
	p.global_position.x = 700.0
	await frames(20)
	await talk_through()
	check(Game.quest_stage == 3, "zodiac phase starts (got %d)" % Game.quest_stage)
	main.change_stage("village", "from_house")
	await frames(60)
	p.global_position.x = 4360.0
	await frames(20)
	var before_sale := Game.money
	await talk_through()
	check(Game.money > before_sale and Game.item_count("frog_leg") == 0, "uncle buys materials")
	p.global_position.x = 1150.0
	await frames(20)
	var potions_before := Game.item_count("potion")
	await talk_through()
	check(Game.item_count("potion") == potions_before + 1, "auntie sells a potion")

	# ---- นักษัตรตัวแรก: ชวด (หนู) Lv.10 ----
	main.change_stage("rice_field", "from_cave")
	await frames(60)
	p.global_position.x = 9400.0
	await frames(20)
	await shot("05_cave_mouth")
	await tap("interact")
	await frames(40)
	check(Game.in_dialogue and main.stage_id == "rice_field", "tiger cave sealed until the tiger trial")
	Game.end_dialogue()
	main.hud._dialogue.visible = false
	check(Game.quest_text().contains("Lv.10"), "quest asks to reach Lv.10 (%s)" % Game.quest_text())
	while Game.level < 10:
		Game.add_exp(Game.exp_needed())
	await frames(20)
	check(Game.quest_text().contains("ชวด"), "Lv.10 quest points to the rat (%s)" % Game.quest_text())
	main.change_stage("chief_house", "entrance")
	await frames(60)
	var spirits := get_tree().get_nodes_in_group("interactables").filter(func(n: Node) -> bool: return n is ZodiacSpirit)
	check(spirits.size() == 1 and spirits[0].zodiac["id"] == "rat", "rat spirit appears at the shrine")
	p.global_position.x = 1500.0
	await frames(30)
	await shot("05b_rat_spirit")
	await talk_through()
	await frames(60)
	check(main.stage_id == "trial_hall" and Game.active_trial == "rat", "rat trial starts in the trial hall")
	check(Game.boss != null and Game.boss.zodiac_id == "rat", "rat boss present")
	Game.max_hp = 100000.0
	Game.set_hp(100000.0)
	p.global_position.x = 900.0
	await frames(150)
	await shot("06_rat_fight")
	await frames(150)
	check(Game.hp < Game.max_hp, "rat can hurt the player")
	Game.hit_enemies(Rect2(-1000, -2000, 20000, 4000), 260.0, 0.0)
	await frames(120)
	await shot("06b_rat_phase2")
	await kill_all(1)
	check("rat" in Game.unlocked and Game.active_trial == "", "rat form unlocked")
	await frames(20)
	Game.end_dialogue()
	main.hud._dialogue.visible = false
	await frames(30)
	await tap("form_next")
	check(Game.form_id == "rat", "switch to rat form")
	for i in 3:
		p.use_skill(i)
		await frames(40)
	await shot("06c_rat_form")
	await tap("form_prev")

	# ---- ขาล (เสือ) Lv.30: ข้ามฉลู (ยังไม่พร้อม) ----
	while Game.level < 30:
		Game.add_exp(Game.exp_needed())
	check(Game.quest_text().contains("ขาล"), "Lv.30 quest points to the tiger (%s)" % Game.quest_text())
	main.change_stage("chief_house", "entrance")
	await frames(60)
	spirits = get_tree().get_nodes_in_group("interactables").filter(func(n: Node) -> bool: return n is ZodiacSpirit)
	check(spirits.size() == 1 and spirits[0].zodiac["id"] == "tiger", "tiger spirit appears at Lv.30")
	p.global_position.x = 1500.0
	await frames(30)
	await talk_through()
	await frames(60)
	check(main.stage_id == "tiger_cave", "tiger trial happens in the tiger cave")
	check(Game.boss != null and Game.boss.zodiac_id == "tiger", "tiger boss present")
	Game.max_hp = 100000.0
	Game.set_hp(100000.0)
	p.global_position.x = 900.0
	await frames(150)
	await shot("07_boss_fight")
	await frames(200)
	await shot("07b_boss_fight_2")
	var hp_before: float = Game.boss.hp if Game.boss else 0.0
	Game.hit_enemies(Rect2(-1000, -2000, 20000, 4000), 400.0, 0.0)
	check(Game.boss != null and Game.boss.hp < hp_before, "boss takes damage")
	await frames(300)
	await shot("08_boss_phase2")
	await kill_all(1)
	check("tiger" in Game.unlocked, "tiger form unlocked")
	await frames(30)
	await shot("09_boss_defeated")
	Game.end_dialogue()
	main.hud._dialogue.visible = false
	await frames(30)
	Game.set_form("tiger")
	for i in 3:
		p.use_skill(i)
		await frames(40)
	await shot("10_tiger_form")

	Game.max_hp = 100.0
	Game.set_hp(1.0)
	p._invuln = 0.0
	p.take_damage(50.0, 0.0)
	check(p.dead, "player can die")
	await frames(240)
	check(not p.dead and main.stage_id == "village", "respawn in village")
	check(Game.quest_text().contains("Lv.40") or Game.quest_text().contains("เร็ว ๆ นี้"), "next quest after the tiger (%s)" % Game.quest_text())
	await shot("11_end")

	Game.reset_save()
	print("RESULT: %s (%d failed)" % ["PASS" if fails == 0 else "FAIL", fails])
	get_tree().quit(1 if fails > 0 else 0)
