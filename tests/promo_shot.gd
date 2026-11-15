extends Node
## ถ่ายภาพฉากในเกม (ไม่มี HUD) ไว้ทำวิดีโอโปรโมท
## รัน: xvfb-run godot --path . --resolution 1280x720 res://tests/promo_shot.tscn -- shots=<dir> [gender=girl]

var shot_dir := ""
var main: Node


func frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func shot(n: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(shot_dir.path_join(n + ".png"))


func go(stage: String, spawn: String, x: float, form: String) -> void:
	main.change_stage(stage, spawn)
	await frames(70)
	Game.set_form(form)
	main.player.global_position = Vector2(x, 560)
	main.player.reset_physics_interpolation()
	main.hud.visible = false
	await frames(60)


func hold(action: String, n: int) -> void:
	Input.action_press(action)
	await frames(n)
	Input.action_release(action)


func _ready() -> void:
	var gender := "boy"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("shots="):
			shot_dir = a.trim_prefix("shots=")
		if a.begins_with("gender="):
			gender = a.trim_prefix("gender=")
	main = load("res://main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	Game.reset_save()
	Game.set_profile(gender, "ฮีโร่" if gender == "boy" else "ฮีโร่สาว")
	main.start_game()
	await frames(30)
	Game.village = 2
	Game.travel_permit = 2
	Game.level = 32
	Game.unlocked = ["normal", "rat", "ox", "tiger", "rabbit"]
	Game._apply_level()
	main.player.set("_invuln", 99999.0)
	var p = main.player

	await go("village", "start", 1900.0, "normal")
	await hold("move_right", 30)
	await frames(10)
	await shot("a_village")

	await go("rice_field", "from_village", 1500.0, "rat")
	await hold("move_right", 40)
	Input.action_press("attack")
	await frames(8)
	await shot("b_field_fight")
	Input.action_release("attack")

	await go("bamboo_forest", "from_village", 7300.0, "tiger")
	await hold("move_left", 30)
	p.use_skill(2)
	await frames(14)
	await shot("c_forest_beetles")

	await go("bamboo_forest", "from_village", 3300.0, "rabbit")
	await hold("move_left", 20)
	p.use_skill(0)
	await frames(6)
	await shot("d_forest_ghosts")

	await go("village2", "start", 2600.0, "rabbit")
	await hold("move_right", 25)
	await frames(10)
	await shot("e_village2")

	Game.active_trial = "tiger"
	await go("trial_hall", "entrance", 700.0, "ox")
	await frames(120)
	await shot("f_tiger_boss")
	Game.active_trial = ""

	await go("ghost_lair", "entrance", 1300.0, "normal")
	await frames(150)
	await shot("g_pong_khang")
	Game.reset_save()
	get_tree().quit()
