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
	# กดค้างอย่างน้อย 3 เฟรมฟิสิกส์ และ 2 เฟรมภาพ (ตอนภาพช้า ฟิสิกส์อาจวิ่งหลายรอบใน 1 เฟรมภาพ)
	Input.action_press(action)
	await frames(3)
	await get_tree().process_frame
	await get_tree().process_frame
	Input.action_release(action)
	await frames(3)


func talk_through() -> void:
	await frames(20)  # เผื่อเพิ่งปิดบทสนทนาก่อนหน้า (กันกดคุยซ้ำทันที)
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
	main.title.begin()
	await frames(20)
	check(main.creator != null and is_instance_valid(main.creator), "new player goes to character creation")
	await shot("00b_gender")
	main.creator._select("girl")
	main.creator._to_name_page()
	main.creator._name_edit.text = "น้ำฝน"
	main.creator._refresh_ok()
	await frames(20)
	await shot("00c_name")
	main.creator._confirm()
	await frames(30)
	check(Game.gender == "girl" and Game.player_name == "น้ำฝน", "gender and name are saved")
	check(main.story != null and Game.in_title, "story plays before the game")
	await frames(90)
	await shot("00d_story")
	for i in 4:
		main.story._advance()
		main.story._advance()
		await frames(70)
	await shot("00e_story_hero")
	main.story._advance()
	main.story._advance()
	await frames(60)
	check(not Game.in_title and main.hud.visible, "game starts after the story")
	check(Game.current_form()["outfit"]["frames"].contains("heroine_"), "girl uses heroine art")
	check(p.name_label.text == "น้ำฝน", "name shows above the hero")
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
	await frames(20)
	check(Game.quest_index == 0 and Game.quest_accepted, "first quest accepted")
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
	check(Quests.is_done(Game.current_quest()), "frog quest complete (%s)" % Game.quest_text())
	check(Game.level > 1, "kills give EXP and level up (Lv.%d)" % Game.level)
	check(Game.max_hp > 100.0, "level raises max HP")
	var keep_level := Game.level
	var keep_exp := Game.exp
	Game.add_exp(100000000)
	check(Game.level == 20, "village 1 caps the level at 20 (Lv.%d)" % Game.level)
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
	var hats := Game.item_count("straw_hat")  # กบอาจดรอปหมวกมาก่อนแล้ว
	var hp_cap := Game.max_hp
	Game.equip("straw_hat")
	check(Game.max_hp > hp_cap, "hat raises max HP")
	Game.unequip("head")
	check(Game.max_hp == hp_cap and Game.item_count("straw_hat") == hats, "unequip returns the item")
	Game.add_item("straw_hat", -1)
	main.hud._set_bag_tab("equip")
	await shot("04d_equipment")
	main.hud._set_bag_tab("item")
	await shot("04c_hotbar")
	await tap("ui_cancel")
	check(not main.hud._bag.visible and not main.hud._char.visible, "ESC closes the bag")
	Game.add_item("potion", 1)
	Game.set_hp(10.0)
	await tap("slot_6")
	check(Game.hp > 10.0, "number key uses the slot item (hp %d, bar %s, dead %s, dlg %s)" % [Game.hp, str(Game.hotbar), str(p.dead), str(Game.in_dialogue)])
	Game.add_item("frog_leg", 3)
	Game.money = 100
	await frames(400)
	check(get_tree().get_nodes_in_group("enemies").size() >= 10, "monsters respawn")

	# ---- ส่งเควสกบ -> ได้เควสหาขากบ -> ส่ง -> ได้เควสเห็ด ----
	main.change_stage("chief_house", "entrance")
	await frames(60)
	p.global_position.x = 700.0
	await frames(20)
	var money_q := Game.money
	await talk_through()
	check(Game.quest_index == 1 and Game.quest_accepted, "frog quest turned in, next quest given (%d)" % Game.quest_index)
	check(Game.money > money_q, "quest reward money")
	Game.add_item("frog_leg", 5)
	var legs_before := Game.item_count("frog_leg")
	await talk_through()
	check(Game.quest_index == 2 and Game.quest_accepted, "collect quest turned in (%d)" % Game.quest_index)
	check(Game.item_count("frog_leg") == legs_before - 5, "collect quest takes the items (%d left)" % Game.item_count("frog_leg"))
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
	await frames(10)
	check(main.hud._shop.visible, "auntie opens her shop")
	main.hud._fill_shop()
	await shot("04e_shop")
	Game.money = maxi(Game.money, 200)
	main.hud._do_buy("potion")
	main.hud._do_buy("big_potion")
	main.hud._do_buy("straw_hat")
	check(Game.item_count("potion") == potions_before + 1 and Game.item_count("big_potion") == 1 and Game.item_count("straw_hat") >= 1, "shop sells potions and gear")
	Game.set_hp(10.0)
	p.use_item("big_potion")
	check(Game.hp >= 160.0 or Game.hp == Game.max_hp, "big potion heals a lot (%d)" % Game.hp)
	main.hud._shop_tab = "sell"
	main.hud._fill_shop()
	await frames(5)
	await shot("04f_shop_sell")
	Game.add_item("frog_leg", 3)
	Game.add_item(Crafting.part_id("rat", "fang"), 1)
	var m0 := Game.money
	main.hud._do_sell("frog_leg", -1)
	check(Game.money > m0 and Game.item_count("frog_leg") == 0, "auntie buys items")
	check(Game.sell_price(Crafting.part_id("rat", "fang")) == 0, "zodiac parts cannot be sold")
	Game.add_item(Crafting.part_id("rat", "fang"), -1)
	await tap("ui_cancel")
	check(not main.hud._shop.visible, "ESC closes the shop")
	# กระเป๋าของเยอะ: รายการต้องเลื่อนได้ ไม่ล้นกรอบ
	for id in ["frog_dagger__q1", "mush_hat__q2", "frog_vest__q3", "frog_boots__q4", "mist_charm__q1", "sandals", "straw_hat", "pha_khao_ma", "amulet"]:
		Game.add_item(id, 1)
	main.hud.toggle_bag()
	main.hud._set_bag_tab("equip")
	await frames(5)
	check(main.hud._bag_list.get_parent() is ScrollContainer, "bag list scrolls")
	await shot("04g_bag_full")
	main.hud.toggle_bag()
	p.global_position.x = 70.0
	await frames(20)
	await tap("interact")
	await frames(30)
	check(Game.in_dialogue and main.stage_id == "village", "next village needs the travel permit")
	Game.end_dialogue()
	main.hud._dialogue.visible = false

	# ---- เห็ดพิษ + ถ้ำยักษ์ยังเข้าไม่ได้ ----
	main.change_stage("rice_field", "from_cave")
	await frames(60)
	p.global_position.x = 9400.0
	await frames(20)
	await shot("05_cave_mouth")
	await tap("interact")
	await frames(40)
	check(Game.in_dialogue and main.stage_id == "rice_field", "demon lair sealed below Lv.15")
	Game.end_dialogue()
	main.hud._dialogue.visible = false
	p.global_position.x = 6000.0
	await frames(60)
	Game.pending_crit = true
	Game.hit_enemies(Rect2(5000, -2000, 2000, 4000), 1.0, 6000.0)
	check(not Game.pending_crit and not Game.hit_is_crit, "critical flags reset after a hit")
	await frames(6)
	await shot("05f_critical")
	await kill_all(2)
	check(Quests.is_done(Game.current_quest()), "mushroom quest done (%s)" % Game.quest_text())
	main.change_stage("chief_house", "entrance")
	await frames(60)
	p.global_position.x = 700.0
	await frames(20)
	await talk_through()
	check(Game.quest_index == 3, "rat quest given (%d)" % Game.quest_index)

	# ---- นักษัตรตัวแรก: ชวด (หนู) Lv.10 ----
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
	check(Game.item_count(Crafting.part_id("rat", "fang")) == 1 and Game.item_count(Crafting.part_id("rat", "tail")) == 1, "rat gives its set parts")
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
	Game._apply_level()
	Game.set_hp(Game.max_hp)

	# ---- ส่งเควสชวด -> เควสคราฟ -> ช่างตีเหล็ก ----
	main.change_stage("chief_house", "entrance")
	await frames(60)
	p.global_position.x = 700.0
	await frames(20)
	await talk_through()
	check(Game.quest_index == 4 and Game.current_quest()["type"] == "craft", "craft quest given (%d)" % Game.quest_index)
	main.change_stage("village", "from_house")
	await frames(60)
	p.global_position.x = 1760.0
	await frames(20)
	await talk_through()
	await frames(10)
	check(main.hud._craft.visible, "blacksmith opens the crafting window")
	Game.money = 2000
	Game.add_item("frog_leg", 30)
	Game.add_item("mushroom_cap", 30)
	main.hud._fill_craft()
	await shot("05c_craft")
	var general: Dictionary = Crafting.recipe_list(Game.items)[2]
	var vests := {}
	for q in 4:
		vests[q + 1] = Game.item_count("frog_vest__q%d" % (q + 1))
	var made := Game.craft(general)
	check(made.begins_with("frog_vest__q") and Game.item_count(made) == vests[int(made.right(1))] + 1, "crafting makes a quality item (%s)" % made)
	var rolls := {}
	for i in 400:
		rolls[Crafting.roll_quality()] = int(rolls.get(Crafting.roll_quality(), 0)) + 1
	check(rolls.has(1) and rolls.has(2) and rolls.has(3), "quality rolls vary (%s)" % str(rolls))
	Game.money = 99999
	for id in ["frog_leg", "mushroom_cap", "mist_horn"]:
		Game.add_item(id, 200)
	var set_recipe: Dictionary = Crafting.recipe_list(Game.items).filter(func(r: Dictionary) -> bool: return r["zodiac"] == "rat")[0]
	var tries := 0
	while Game.item_count(set_recipe["key"]) == 0 and tries < 10:
		var res := Game.craft(set_recipe)
		check(res != "FAIL" or Game.item_count(Crafting.part_id("rat", "fang")) == 1, "failed set craft keeps the zodiac part")
		tries += 1
	check(Game.item_count(set_recipe["key"]) == 1, "set piece eventually forged (%d tries)" % tries)
	for r in Crafting.recipe_list(Game.items):
		if r["zodiac"] == "rat":
			Game.craft(r, true)
	for slot in ["weapon", "head", "body", "feet", "charm"]:
		Game.equip(Crafting.set_item_id("rat", slot))
	check(int(Game.set_counts().get("rat", 0)) == 5, "full rat set equipped")
	check(Game.set_effect("dodge") > 0.0 and Game.set_effect("cd_mult") < 1.0, "rat set gives its abilities")
	main.hud._fill_craft()
	await frames(10)
	await shot("05d_craft_done")
	await tap("ui_cancel")
	check(not main.hud._craft.visible, "ESC closes the crafting window")
	main.hud.toggle_bag()
	main.hud._set_bag_tab("equip")
	await shot("05e_rat_set")
	main.hud.toggle_bag()

	# ---- ส่งเควสคราฟ -> ยักษ์หมอกทมิฬ (Lv.15) ----
	main.change_stage("chief_house", "entrance")
	await frames(60)
	p.global_position.x = 700.0
	await frames(20)
	await talk_through()
	check(Game.quest_index == 5, "demon quest given (%d)" % Game.quest_index)
	while Game.level < 15:
		Game.add_exp(Game.exp_needed())
	main.change_stage("rice_field", "from_cave")
	await frames(60)
	p.global_position.x = 9400.0
	await frames(20)
	await tap("interact")
	await frames(60)
	check(main.stage_id == "demon_lair", "demon lair opens at Lv.15+")
	check(Game.boss != null and Game.boss.zodiac_id == "mist_giant", "mist giant boss present")
	Game.max_hp = 100000.0
	Game.set_hp(100000.0)
	p.global_position.x = 1000.0
	await frames(200)
	await shot("10b_demon_fight")
	await kill_all(1)
	await frames(30)
	check(Quests.is_done(Game.current_quest()), "demon quest done (%s)" % Game.quest_text())
	await shot("10c_demon_defeated")
	Game._apply_level()
	Game.set_hp(Game.max_hp)

	# ---- เควสหมวกเห็ด -> ฉลู (Lv.20) ----
	main.change_stage("chief_house", "entrance")
	await frames(60)
	p.global_position.x = 700.0
	await frames(20)
	await talk_through()
	check(Game.quest_index == 6, "mushroom cap quest given (%d)" % Game.quest_index)
	Game.add_item("mushroom_cap", 6)
	await talk_through()
	check(Game.quest_index == 7 and Game.current_quest()["target"] == "ox", "ox quest given (%d)" % Game.quest_index)
	while Game.level < 20:
		Game.add_exp(Game.exp_needed())
	Game.add_exp(5000)
	check(Game.level == 20, "level stays at the village cap")
	main.change_stage("chief_house", "entrance")
	await frames(60)
	spirits = get_tree().get_nodes_in_group("interactables").filter(func(n: Node) -> bool: return n is ZodiacSpirit)
	check(spirits.size() == 1 and spirits[0].zodiac["id"] == "ox", "ox spirit appears at Lv.20")
	p.global_position.x = 1500.0
	await frames(30)
	await talk_through()
	await frames(60)
	check(main.stage_id == "trial_hall" and Game.boss != null and Game.boss.zodiac_id == "ox", "ox trial in the trial hall")
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
	check("ox" in Game.unlocked, "ox form unlocked")
	await frames(30)
	await shot("09_boss_defeated")
	Game.end_dialogue()
	main.hud._dialogue.visible = false
	await frames(30)
	Game.set_form("ox")
	for i in 3:
		p.use_skill(i)
		await frames(40)
	await shot("10_ox_form")
	check(Zodiac.available(Game.level, Game.unlocked).is_empty(), "no more zodiacs in village 1")

	# ---- ส่งเควสฉลู -> ใบเบิกทาง ----
	main.change_stage("chief_house", "entrance")
	await frames(60)
	p.global_position.x = 700.0
	await frames(20)
	await talk_through()
	check(Game.current_quest()["type"] == "travel" and Game.travel_permit == 2, "travel permit to village 2")

	Game.max_hp = 100.0
	Game.set_hp(1.0)
	p._invuln = 0.0
	Game.equipped.erase("feet")
	Game.equipped.erase("body")
	p.take_damage(50.0, 0.0)
	if not p.dead:
		p._invuln = 0.0
		p.take_damage(50.0, 0.0)
	check(p.dead, "player can die")
	await frames(240)
	check(not p.dead and main.stage_id == "village", "respawn in village")
	check(Game.quest_text().contains("บ้านผาจันทร์"), "quest points to the next village (%s)" % Game.quest_text())
	await shot("11_end")
	Game._apply_level()
	Game.set_hp(Game.max_hp)

	# ---- หมู่บ้าน 2: บ้านผาจันทร์ ----
	p.global_position.x = 70.0
	await frames(20)
	await tap("interact")
	await frames(70)
	check(main.stage_id == "village2", "permit opens the road to village 2 (%s)" % main.stage_id)
	check(Game.village == 2 and Game.level_cap() == 40, "arrived in village 2, cap 40")
	check(Game.current_quest().get("village", 0) == 2 and not Game.quest_accepted, "first village 2 quest waiting (%d)" % Game.quest_index)
	check(Game.quest_text().contains("ยายจันทร์"), "quest text points to Grandma Chan (%s)" % Game.quest_text())
	await shot("12_village2")
	main.change_stage("village", "start")
	await frames(60)
	main.change_stage("chief_house", "entrance")
	await frames(60)
	p.global_position.x = 700.0
	await frames(20)
	await talk_through()
	check(not Game.quest_accepted, "village 1 chief sends you to village 2")
	main.change_stage("elder_house", "entrance")
	await frames(60)
	await shot("13_elder_house")
	p.global_position.x = 700.0
	await frames(20)
	await talk_through()
	check(Game.quest_accepted and Game.current_quest()["target"] == "beetle", "beetle quest from Grandma Chan")
	main.change_stage("bamboo_forest", "from_village")
	await frames(60)
	check(get_tree().get_nodes_in_group("enemies").size() >= 10, "bamboo forest has monsters")
	await shot("14_bamboo_forest")
	p.global_position.x = 3300.0
	await frames(60)
	await shot("14b_bamboo_ghosts")
	for i in 8:
		Game.on_enemy_killed("beetle")
	check(Quests.is_done(Game.current_quest()), "beetle quest done")
	main.change_stage("elder_house", "entrance")
	await frames(60)
	p.global_position.x = 700.0
	await frames(20)
	await talk_through()
	check(Game.current_quest()["target"] == "beetle_horn", "beetle horn quest (%d)" % Game.quest_index)
	Game.add_item("beetle_horn", 10)
	Game.add_item("bamboo_core", 10)
	await talk_through()
	check(Game.current_quest()["target"] == "tiger", "tiger quest (%d)" % Game.quest_index)
	while Game.level < 30:
		Game.add_exp(Game.exp_needed())
	main.change_stage("elder_house", "entrance")
	await frames(60)
	spirits = get_tree().get_nodes_in_group("interactables").filter(func(n: Node) -> bool: return n is ZodiacSpirit)
	check(spirits.size() == 1 and spirits[0].zodiac["id"] == "tiger", "tiger spirit at Grandma Chan's shrine")
	p.global_position.x = 1500.0
	await frames(30)
	await talk_through()
	await frames(60)
	check(main.stage_id == "trial_hall" and Game.boss != null and Game.boss.zodiac_id == "tiger", "tiger trial")
	await kill_all(1)
	check("tiger" in Game.unlocked, "tiger form unlocked")
	Game.end_dialogue()
	main.hud._dialogue.visible = false
	await frames(30)
	main.change_stage("elder_house", "from_trial")
	await frames(60)
	p.global_position.x = 700.0
	await frames(20)
	await talk_through()
	check(Game.current_quest()["target"] == "bamboo_ghost", "bamboo ghost quest (%d)" % Game.quest_index)
	for i in 8:
		Game.on_enemy_killed("bamboo_ghost")
	await talk_through()
	check(Game.current_quest()["type"] == "craft", "craft quest in village 2")
	Game.money += 1000
	Game.add_item("beetle_horn", 10)
	var recipes2: Array = Crafting.recipe_list(Game.items)
	var keys: Array = recipes2.map(func(r: Dictionary) -> String: return r["key"])
	check("horn_spear" in keys and "zset_tiger_weapon" in keys, "village 2 recipes and tiger set at the smith")
	var spear: Dictionary = recipes2[keys.find("horn_spear")]
	check(Game.craft(spear) != "", "craft a horn spear")
	await talk_through()
	check(Game.current_quest()["target"] == "pong_khang", "demon quest (%d)" % Game.quest_index)
	while Game.level < 35:
		Game.add_exp(Game.exp_needed())
	main.change_stage("bamboo_forest", "from_lair")
	await frames(60)
	p.global_position.x = 200.0
	await frames(20)
	await tap("interact")
	await frames(70)
	check(main.stage_id == "ghost_lair" and Game.boss != null and Game.boss.zodiac_id == "pong_khang", "ghost lair with Phi Pong Khang")
	Game.max_hp = 100000.0
	Game.set_hp(100000.0)
	p.global_position.x = 1200.0
	await frames(200)
	await shot("15_pong_khang")
	await kill_all(1)
	await frames(30)
	check(Quests.is_done(Game.current_quest()) and Game.item_count("ghost_fur") >= 0, "demon quest done")
	Game._apply_level()
	Game.set_hp(Game.max_hp)
	main.change_stage("elder_house", "entrance")
	await frames(60)
	p.global_position.x = 700.0
	await frames(20)
	await talk_through()
	check(Game.current_quest()["target"] == "bamboo_core", "bamboo core quest (%d)" % Game.quest_index)
	Game.add_item("bamboo_core", 6)
	await talk_through()
	check(Game.current_quest()["target"] == "rabbit", "rabbit quest (%d)" % Game.quest_index)
	while Game.level < 40:
		Game.add_exp(Game.exp_needed())
	Game.add_exp(9000)
	check(Game.level == 40, "level stays at the village 2 cap")
	main.change_stage("elder_house", "entrance")
	await frames(60)
	p.global_position.x = 1500.0
	await frames(30)
	await talk_through()
	await frames(60)
	check(main.stage_id == "trial_hall" and Game.boss != null and Game.boss.zodiac_id == "rabbit", "rabbit trial")
	Game.max_hp = 100000.0
	Game.set_hp(100000.0)
	p.global_position.x = 900.0
	await frames(200)
	await shot("16_rabbit_boss")
	await kill_all(1)
	check("rabbit" in Game.unlocked and Game.item_count("zpart_rabbit_fang") == 1, "rabbit form and parts")
	Game.end_dialogue()
	main.hud._dialogue.visible = false
	await frames(30)
	Game.set_form("rabbit")
	for i in 3:
		p.use_skill(i)
		await frames(40)
	await shot("17_rabbit_form")
	main.change_stage("elder_house", "from_trial")
	await frames(60)
	p.global_position.x = 700.0
	await frames(20)
	await talk_through()
	check(Game.current_quest()["type"] == "travel" and Game.travel_permit == 3, "travel permit to village 3")
	Game.save_game()
	Game.load_game()
	check(Game.village == 2 and Game.travel_permit == 3, "village 2 saved")

	Game.reset_save()
	print("RESULT: %s (%d failed)" % ["PASS" if fails == 0 else "FAIL", fails])
	get_tree().quit(1 if fails > 0 else 0)
