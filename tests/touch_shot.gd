extends Node
## ถ่ายภาพหน้าจอปุ่มสัมผัส (ใช้ตรวจตำแหน่งปุ่มบนจอแนวตั้ง/แนวนอน)
## รัน: xvfb-run godot --path . --resolution 720x1280 res://tests/touch_shot.tscn -- shots=<dir>

var shot_dir := "/tmp"


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("shots="):
			shot_dir = a.trim_prefix("shots=")
	var main = load("res://main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	main.start_game()
	if main.hud._touch_root == null:
		main.hud._build_touch()
	for i in 90:
		await get_tree().physics_frame
	main.hud._on_screen_resized()
	for i in 30:
		await get_tree().physics_frame
	await RenderingServer.frame_post_draw
	var s := DisplayServer.window_get_size()
	get_viewport().get_texture().get_image().save_png("%s/touch_%dx%d.png" % [shot_dir, s.x, s.y])
	main.hud.toggle_bag()
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/touch_bag_%dx%d.png" % [shot_dir, s.x, s.y])
	Game.reset_save()
	get_tree().quit()
