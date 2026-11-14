extends Node
## ภาพตรวจอาวุธที่ถือ: ทุกท่าตี + สะพายหลัง กับอาวุธหลายแบบ
## รัน: xvfb-run godot --path . res://tests/weapon_shot.tscn -- shots=<dir>

var shot_dir := "/tmp"


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("shots="):
			shot_dir = a.trim_prefix("shots=")
	var main = load("res://main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	main.start_game()
	for i in 60:
		await get_tree().physics_frame
	var p: Player = main.player
	p.set_physics_process(false)
	var img := Image.create(200 * 4, 140 * 8, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.2, 0.2, 0.25))
	var row := 0
	for setup in [["boy", "normal", "wood_sword"], ["boy", "normal", "frog_dagger"], ["girl", "normal", "mist_charm"], ["boy", "rat", "zset_rat_weapon"], ["girl", "rat", "zset_ox_weapon"], ["girl", "tiger", "zset_tiger_weapon"], ["boy", "ox", "zset_ox_weapon"], ["girl", "ox", "frog_dagger"]]:
		Game.gender = setup[0]
		Game._girl_forms.clear()
		if not (setup[1] in Game.unlocked):
			Game.unlocked.append(setup[1])
		Game.form_id = setup[1]
		p.visual.outfit = Game.current_form()["outfit"]
		var icon: String = setup[2]
		p.visual.weapon_icon = icon if icon != "mist_charm" else "craft_frog_dagger"
		if icon == "frog_dagger":
			p.visual.weapon_icon = "craft_frog_dagger"
		for col in 4:
			p.visual.hurt = 0.0
			p.visual.cast = 0.0
			p.visual.moving = false
			p.visual.in_air = false
			p.visual.swing = [-1.0, 0.1, 0.4, 0.8][col]
			await get_tree().process_frame
			await get_tree().process_frame
			await RenderingServer.frame_post_draw
			var shot := get_viewport().get_texture().get_image()
			var c: Vector2 = p.get_global_transform_with_canvas().origin
			img.blit_rect(shot, Rect2i(int(c.x) - 75, int(c.y) - 125, 200, 140), Vector2i(col * 200, row * 140))
		row += 1
	img.save_png(shot_dir + "/weapons.png")
	Game.reset_save()
	get_tree().quit()
