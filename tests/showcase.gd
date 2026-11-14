extends Node
## เก็บภาพท่าทางและเอฟเฟกต์ของตัวเอก (ไว้ตรวจด้วยตา)
## รัน: xvfb-run godot --path . res://tests/showcase.tscn -- shots=โฟลเดอร์

var main: Node
var p: Player
var shot_dir := "/tmp/showcase"
var n := 0


func frames(count: int) -> void:
	for i in count:
		await get_tree().physics_frame


func snap(label: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var c := p.get_global_transform_with_canvas().origin
	var r := Rect2i(int(c.x) - 210, int(c.y) - 250, 420, 330).intersection(Rect2i(0, 0, img.get_width(), img.get_height()))
	img.get_region(r).save_png("%s/%02d_%s.png" % [shot_dir, n, label])
	n += 1


func hold(action: String, count: int, label: String, every: int) -> void:
	Input.action_press(action)
	for i in count:
		await frames(every)
		await snap(label)
	Input.action_release(action)


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("shots="):
			shot_dir = a.trim_prefix("shots=")
	Game.reset_save()
	Game.unlocked = ["normal", "tiger"]
	main = load("res://main.tscn").instantiate()
	add_child(main)
	main.start_game()
	p = main.player
	await frames(60)
	main.change_stage("rice_field", "from_village")
	await frames(60)
	p.global_position.x = 1650.0
	await frames(60)
	await snap("idle")
	await hold("move_right", 4, "walk", 5)
	Input.action_press("run")
	await hold("move_right", 3, "run", 5)
	Input.action_release("run")
	await frames(20)
	Input.action_press("jump")
	await frames(8)
	Input.action_release("jump")
	await snap("jump_up")
	await frames(26)
	await snap("fall")
	await frames(40)
	for form in ["normal", "tiger"]:
		if form == "tiger":
			Input.action_press("form_next")
			await frames(4)
			Input.action_release("form_next")
			await snap("transform")
			await frames(8)
			await snap("transform")
			await frames(50)
		p.global_position.x = 2000.0
		await frames(30)
		Input.action_press("attack")
		await frames(4)
		await snap(form + "_attack")
		await frames(5)
		await snap(form + "_attack")
		Input.action_release("attack")
		await frames(40)
		for i in 3:
			p.use_skill(i)
			await frames(6)
			await snap("%s_skill%d" % [form, i + 1])
			await frames(8)
			await snap("%s_skill%d" % [form, i + 1])
			await frames(70)
	# บอส
	Game.quest_index = 3
	Game.max_hp = 100000.0
	Game.set_hp(100000.0)
	main.change_stage("demon_lair", "entrance")
	await frames(60)
	p.global_position.x = 900.0
	for i in 16:
		await frames(22)
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("%s/boss_%02d_%s.png" % [shot_dir, i, Game.boss.state if Game.boss else "none"])
	Game.max_hp = 100.0
	get_tree().quit()
