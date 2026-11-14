extends Stage
## ลานประลองในหอบูชา: สู้กับนักษัตรที่กำลังทดสอบอยู่ (Game.active_trial)


func build() -> void:
	width = 2200.0
	style = "house"
	spawns = {"entrance": Vector2(260, GROUND_Y)}
	var z := Zodiac.get_data(Game.active_trial)
	title = "ประลอง — %s" % (Zodiac.display_name(z) if not z.is_empty() else "")

	add_platform(560.0, 440.0, 220.0)
	add_platform(1420.0, 440.0, 220.0)
	var house := "chief_house" if z.is_empty() else str(Quests.village_info(Zodiac.village_of(z))["house"])
	add_portal(100.0, "กลับหอบูชา", house, "from_trial", Callable(), Color(0.6, 1.0, 0.5))

	if not z.is_empty():
		var boss := ZodiacBoss.create(z["id"])
		boss.position = Vector2(1650, GROUND_Y - 2.0)
		boss.arena_left = 330.0
		boss.arena_right = width - 120.0
		add_child(boss)
