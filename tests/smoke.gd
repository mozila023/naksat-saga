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
	await frames(40)
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

	p.global_position.x = 2050.0
	await frames(30)
	await shot("02_village_chief")
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
	await frames(400)
	check(get_tree().get_nodes_in_group("enemies").size() >= 10, "monsters respawn")

	main.change_stage("village", "start")
	await frames(60)
	p.global_position.x = 2050.0
	await frames(20)
	await talk_through()
	check(Game.quest_stage == 3, "boss quest accepted (got %d)" % Game.quest_stage)

	main.change_stage("rice_field", "from_cave")
	await frames(60)
	p.global_position.x = 9400.0
	await frames(20)
	await shot("05_cave_mouth")
	await tap("interact")
	await frames(60)
	check(main.stage_id == "tiger_cave", "enter boss cave")
	check(Game.boss != null, "boss present")
	Game.max_hp = 100000.0
	Game.set_hp(100000.0)
	p.global_position.x = 900.0
	await frames(150)
	await shot("06_boss_fight")
	await frames(200)
	await shot("07_boss_fight_2")
	check(Game.hp < Game.max_hp, "boss can hurt the player")
	var hp_before: float = Game.boss.hp if Game.boss else 0.0
	Game.hit_enemies(Rect2(-1000, -2000, 20000, 4000), 400.0, 0.0)
	check(Game.boss != null and Game.boss.hp < hp_before, "boss takes damage")
	await frames(300)
	await shot("08_boss_phase2")
	await kill_all(1)
	check("tiger" in Game.unlocked, "tiger form unlocked")
	check(Game.quest_stage == 4, "boss quest done (got %d)" % Game.quest_stage)
	await frames(30)
	await shot("09_boss_defeated")
	await tap("form_next")
	check(Game.form_id == "tiger", "switch to tiger form")
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
	p.global_position.x = 2050.0
	await frames(20)
	await talk_through()
	check(Game.quest_stage == 5, "quest chain complete (got %d)" % Game.quest_stage)
	await shot("11_end")

	Game.reset_save()
	print("RESULT: %s (%d failed)" % ["PASS" if fails == 0 else "FAIL", fails])
	get_tree().quit(1 if fails > 0 else 0)
