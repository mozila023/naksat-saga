extends Stage
## แผนที่ 3: ถ้ำเสือ — ลานประลองของขาล (พญาเสือโคร่ง) นักษัตรปีเสือ Lv.30


func build() -> void:
	width = 2200.0
	title = "ถ้ำเสือ"
	style = "cave"
	spawns = {"entrance": Vector2(260, GROUND_Y)}

	add_bg("cave_far", 0.4)

	for x in [200.0, 700.0, 1100.0, 1500.0, 2000.0]:
		add_prop("torch", x)
	for x in [450.0, 1750.0]:
		add_prop("rock", x)

	add_platform(560.0, 440.0, 220.0)
	add_platform(1420.0, 440.0, 220.0)

	add_portal(100.0, "ออกจากถ้ำ", "rice_field", "from_cave", Callable(), Color(0.6, 1.0, 0.5))

	if Game.active_trial != "tiger":
		return
	var boss := ZodiacBoss.create("tiger")
	boss.position = Vector2(1650, GROUND_Y - 2.0)
	boss.arena_left = 330.0
	boss.arena_right = width - 120.0
	add_child(boss)
