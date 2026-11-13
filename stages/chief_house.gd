extends Stage
## บ้านผู้ใหญ่บ้าน = หอบูชา 12 นักษัตร: ผู้ใหญ่บ้านให้เควส และวิญญาณนักษัตรจะปรากฏที่นี่ทุก 10 เลเวล

const CHIEF := "ผู้ใหญ่บ้าน"


func build() -> void:
	width = 2400.0
	title = "บ้านผู้ใหญ่บ้าน"
	style = "house"
	spawns = {"entrance": Vector2(260, GROUND_Y), "from_trial": Vector2(1200, GROUND_Y)}

	add_portal(100.0, "ออกจากบ้าน", "village", "from_house", Callable(), Color(0.6, 1.0, 0.5))
	add_npc(700.0, CHIEF, {"shirt": Color(0.3, 0.45, 0.75), "hat": "straw", "sprite": "res://assets/art/npc_chief.png"}, _talk_chief,
		func() -> bool: return Game.quest_stage in [0, 2])

	# วิญญาณนักษัตรที่พร้อมประลอง (ถ้ามี) ปรากฏหน้าหิ้งบูชา
	var z := Zodiac.available(Game.level, Game.unlocked)
	if Game.quest_stage >= 3 and not z.is_empty():
		var spirit := ZodiacSpirit.new()
		spirit.zodiac = z
		spirit.position = Vector2(1560, GROUND_Y)
		add_child(spirit)


func _talk_chief() -> void:
	match Game.quest_stage:
		0:
			Game.start_dialogue([
				{"who": CHIEF, "text": "มาแล้วหรือ %s บ้านลุงเป็น หอบูชา 12 นักษัตร ผู้พิทักษ์หมู่บ้านเรามาแต่โบราณ" % Game.player_name},
				{"who": CHIEF, "text": "นักษัตรจะยืมพลังแปลงร่าง ให้คนที่ผ่านการประลองเท่านั้น ทุกครั้งที่หลานเก่งขึ้น 10 เลเวล นักษัตรตัวถัดไป จะปรากฏที่หิ้งบูชานี้"},
				{"who": CHIEF, "text": "เริ่มจากฝึกฝีมือก่อน ไปกำจัด กบนา 5 ตัว ที่ทุ่งนา ทางขวาของหมู่บ้าน"},
			], func() -> void:
				Game.set_quest_stage(1)
				Game.banner.emit("รับเควส: กำจัดกบนา 5 ตัว"))
		1:
			Game.start_dialogue([{"who": CHIEF, "text": "กบนาอยู่ที่ทุ่งนา ทางขวาสุดของหมู่บ้าน (กำจัดแล้ว %d/%d ตัว)" % [Game.frog_kills, Game.FROGS_NEEDED]}])
		2:
			var first: Dictionary = Zodiac.LIST[0]
			Game.start_dialogue([
				{"who": CHIEF, "text": "เก่งมาก! ทีนี้ฝึกต่อที่ทุ่งนา ให้ถึง Lv.%d แล้ว %s นักษัตรตัวแรก จะมาทดสอบหลานที่นี่" % [int(first["level"]), Zodiac.display_name(first)]},
			], func() -> void:
				Game.set_quest_stage(3))
		_:
			var z := Zodiac.available(Game.level, Game.unlocked)
			var text := ""
			if not z.is_empty():
				text = "%s มารออยู่ที่หิ้งบูชาแล้ว ไปคุยกับท่านได้เลย" % Zodiac.display_name(z)
			else:
				var next := Zodiac.upcoming(Game.level, Game.unlocked)
				if next.is_empty():
					text = "นักษัตรตัวต่อไป ยังไม่ปรากฏตัว รออีกสักพักนะหลาน"
				else:
					text = "ฝึกต่อให้ถึง Lv.%d แล้ว %s จะมาทดสอบหลาน" % [int(next["level"]), Zodiac.display_name(next)]
			Game.start_dialogue([{"who": CHIEF, "text": text}])
