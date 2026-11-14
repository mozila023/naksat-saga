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
		func() -> bool: return _has_news())

	# วิญญาณนักษัตรที่พร้อมประลอง (ถ้ามี) ปรากฏหน้าหิ้งบูชา (หลังรับเควสแรกแล้ว)
	var z := Zodiac.available(Game.level, Game.unlocked)
	if (Game.quest_index > 0 or Game.quest_accepted) and not z.is_empty():
		var spirit := ZodiacSpirit.new()
		spirit.zodiac = z
		spirit.position = Vector2(1560, GROUND_Y)
		add_child(spirit)


## มีเควสใหม่ให้รับ หรือมีเควสที่ทำครบรอส่ง (ขึ้นเครื่องหมาย ! เหนือหัว)
func _has_news() -> bool:
	var q := Game.current_quest()
	return not q.is_empty() and (not Game.quest_accepted or (q["type"] != "travel" and Quests.is_done(q)))


func _talk_chief() -> void:
	var q := Game.current_quest()
	if q.is_empty():
		Game.start_dialogue([{"who": CHIEF, "text": "หมู่บ้านถัดไป ยังไปไม่ได้ในตอนนี้ รออีกสักพักนะหลาน"}])
		return
	if not Game.quest_accepted:
		_give(q)
		return
	if q["type"] != "travel" and Quests.is_done(q):
		# ส่งเควส แล้วให้เควสถัดไปต่อเลย
		Game.start_dialogue([{"who": CHIEF, "text": "เก่งมาก %s! นี่คือรางวัลของหลาน" % Game.player_name}], func() -> void:
			Game.turn_in_quest()
			var next := Game.current_quest()
			if not next.is_empty():
				_give.call_deferred(next))
		return
	Game.start_dialogue([{"who": CHIEF, "text": _hint(q)}])


func _give(q: Dictionary) -> void:
	var lines: Array = []
	for t in q["give"]:
		lines.append({"who": CHIEF, "text": str(t).replace("{name}", Game.player_name)})
	Game.start_dialogue(lines, func() -> void: Game.accept_quest())


## คำใบ้ระหว่างทำเควส
func _hint(q: Dictionary) -> String:
	match q["type"]:
		"kill", "collect", "craft":
			return "%s (ตอนนี้ %s)" % [q["title"], Quests.progress_text(q)]
		"zodiac":
			var z := Zodiac.get_data(q["target"])
			if Game.level < int(z["level"]):
				return "ฝึกต่อให้ถึง Lv.%d แล้ว %s จะมาทดสอบหลานที่หิ้งบูชา" % [int(z["level"]), Zodiac.display_name(z)]
			return "%s มารออยู่ที่หิ้งบูชาแล้ว ไปคุยกับท่านได้เลย" % Zodiac.display_name(z)
		"travel":
			return "ใบเบิกทางอยู่กับหลานแล้ว ออกไปทางประตูซ้ายสุดของหมู่บ้านได้เลย"
	return ""
