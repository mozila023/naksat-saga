extends Node
## วัดความลื่น (เวลา CPU ต่อเฟรม) ในแผนที่ที่มีมอนสเตอร์
## รัน: godot --headless --path . res://tests/perf.tscn

func _measure(main: Node, stage: String, spawn: String, x: float) -> void:
	main.change_stage(stage, spawn)
	for i in 90:
		await get_tree().physics_frame
	main.player.global_position.x = x
	for i in 30:
		await get_tree().physics_frame
	var procs: Array = []
	var physs: Array = []
	for i in 600:
		await get_tree().process_frame
		procs.append(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0)
		physs.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0)
	procs.sort()
	physs.sort()
	print("PERF %-14s process median %.2f p90 %.2f | physics median %.2f p90 %.2f | enemies %d" % [stage, procs[300], procs[540], physs[300], physs[540], get_tree().get_nodes_in_group("enemies").size()])


func _ready() -> void:
	Engine.max_fps = 0
	var main = load("res://main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	main.start_game()
	Game.level = 25
	Game.village = 2
	for i in 30:
		await get_tree().physics_frame
	main.player.set("_invuln", 99999.0)
	await _measure(main, "village", "start", 2000.0)
	await _measure(main, "rice_field", "from_village", 3000.0)
	await _measure(main, "bamboo_forest", "from_village", 7000.0)
	Game.reset_save()
	get_tree().quit()
