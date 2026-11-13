extends Stage
## แผนที่ 1: หมู่บ้าน (ปลอดภัย ไม่มีมอนสเตอร์) — รับเควสจากผู้ใหญ่บ้าน

const CHIEF := "ผู้ใหญ่บ้าน"


func build() -> void:
	width = 6400.0
	title = "หมู่บ้านนักษัตร"
	style = "village"
	spawns = {"start": Vector2(420, GROUND_Y), "from_field": Vector2(6080, GROUND_Y)}

	add_bg("clouds", 0.05, -8.0)
	add_bg("hills", 0.12)
	add_bg("village_mid", 0.35)

	# ---- ของประกอบฉาก (ไล่จากซ้ายไปขวา) ----
	add_prop("flower_tree", 120.0)
	add_prop("shop", 250.0)
	add_prop("mailbox", 540.0)
	add_prop("banana", 760.0)
	add_prop("rack", 720.0)
	add_prop("fence", 900.0, {"w": 330.0})
	add_prop("bush", 1000.0)
	add_prop("pole", 1380.0)
	add_prop("banana", 1620.0)
	add_prop("sala", 2050.0)
	add_sign(1760.0, "ศาลาประชาคม")
	add_prop("fence", 2320.0, {"w": 240.0})
	add_prop("house", 2800.0)
	add_prop("banana", 3020.0)
	add_prop("bush", 3150.0, {"color": Color(1.0, 0.85, 0.3)})
	add_prop("tree", 3400.0)
	add_prop("house", 3760.0, {"roof": Color(0.45, 0.5, 0.8)})
	add_prop("pole", 4020.0)
	add_prop("fence", 4160.0, {"w": 420.0})
	add_sign(4120.0, "คอกหมู")
	add_prop("haystack", 4500.0)
	add_prop("banana", 4700.0)
	add_prop("house", 4980.0)
	add_prop("flower_tree", 5250.0, {"color": Color(1.0, 0.6, 0.8)})
	add_prop("rack", 5450.0)
	add_prop("bush", 5650.0)
	add_prop("tree", 5850.0)
	add_sign(5980.0, "ทุ่งนา →")

	# ---- แท่นลอยให้กระโดดเล่น ----
	add_platform(2580.0, 470.0, 200.0)
	add_platform(3300.0, 460.0, 220.0)
	add_platform(3560.0, 340.0, 180.0)
	add_platform(4640.0, 470.0, 200.0)
	add_platform(5180.0, 450.0, 220.0)

	# ---- ชาวบ้าน ----
	add_npc(2050.0, CHIEF, {"shirt": Color(0.3, 0.45, 0.75), "pants": Color(0.2, 0.2, 0.25), "accent": Color(0.9, 0.75, 0.3), "hair": Color(0.75, 0.75, 0.75), "hat": "straw"}, _talk_chief, func() -> bool: return Game.quest_stage in [0, 2, 4])
	add_npc(1150.0, "ป้าศรี", {"shirt": Color(0.95, 0.6, 0.7), "pants": Color(0.5, 0.25, 0.4), "accent": Color(1, 1, 1), "hair": Color(0.25, 0.18, 0.15), "hat": "bun"}, _talk_auntie)
	add_npc(4360.0, "ลุงหมู", {"shirt": Color(0.6, 0.8, 0.5), "pants": Color(0.35, 0.3, 0.2), "accent": Color(0.4, 0.3, 0.2), "hair": Color(0.2, 0.2, 0.2), "hat": "straw"}, _talk_uncle)

	# ---- ประตู ----
	add_portal(6240.0, "ไปทุ่งนา", "rice_field", "from_village", Callable(), Color(0.6, 1.0, 0.5))


func _talk_chief() -> void:
	match Game.quest_stage:
		0:
			Game.start_dialogue([
				{"who": CHIEF, "text": "เจ้าหนุ่ม มาได้จังหวะพอดี! ช่วงนี้ สัตว์ประหลาด ออกอาละวาด ทั่วทุ่งนาเลย"},
				{"who": CHIEF, "text": "ลุงได้ยินว่า วิญญาณ 12 นักษัตร ถูกปลุกขึ้นมา ตัวแรกคือ พญาเสือโคร่ง อยู่ในถ้ำ สุดทางทุ่งนา"},
				{"who": CHIEF, "text": "แต่ก่อนอื่น ลองฝีมือดูหน่อย ไปกำจัด กบนา 5 ตัว ที่ทุ่งนา ทางขวาของหมู่บ้าน ให้ลุงที"},
			], func() -> void:
				Game.set_quest_stage(1)
				Game.banner.emit("รับเควส: กำจัดกบนา 5 ตัว"))
		1:
			Game.start_dialogue([{"who": CHIEF, "text": "กบนาอยู่ที่ทุ่งนา เดินไปทางขวาสุดของหมู่บ้าน แล้วเข้าประตูไปได้เลย (กำจัดแล้ว %d/%d ตัว)" % [Game.frog_kills, Game.FROGS_NEEDED]}])
		2:
			Game.start_dialogue([
				{"who": CHIEF, "text": "เก่งมาก! ฝีมือแบบนี้ ลุงฝากความหวังไว้ได้"},
				{"who": CHIEF, "text": "ลุงเปิดผนึก ปากถ้ำเสือ ให้แล้ว ถ้ำอยู่สุดทางทุ่งนา ไปปราบ พญาเสือโคร่ง ให้ได้นะ"},
				{"who": CHIEF, "text": "จำไว้ ก่อนเสือจะโจมตี จะมีกรอบสีแดงเตือน ให้รีบหลบออกมา ถ้ามันคำราม ให้กระโดดข้ามคลื่น"},
			], func() -> void:
				Game.set_quest_stage(3)
				Game.banner.emit("รับเควส: ปราบพญาเสือโคร่ง"))
		3:
			Game.start_dialogue([{"who": CHIEF, "text": "ถ้ำเสือ อยู่สุดทางทุ่งนา ระวังกรอบสีแดงให้ดี ใช้สกิลพุ่งหลบ (ปุ่ม I) ช่วยได้มาก"}])
		4:
			Game.start_dialogue([
				{"who": CHIEF, "text": "สุดยอด! เจ้าปราบ พญาเสือโคร่ง ได้จริง ๆ พลังปีขาล เป็นของเจ้าแล้ว"},
				{"who": CHIEF, "text": "กด Q หรือ E เพื่อสลับร่างได้ตลอดเวลา แต่ละร่าง มีสกิล 3 อย่าง ไม่เหมือนกัน"},
				{"who": CHIEF, "text": "ยังเหลือ นักษัตรอีก 11 ตัว รอเจ้าอยู่ พักให้หายเหนื่อยก่อน แล้วลุงจะบอกทางต่อไป"},
			], func() -> void:
				Game.set_quest_stage(5)
				Game.banner.emit("เควสสำเร็จ!"))
		_:
			Game.start_dialogue([{"who": CHIEF, "text": "ตอนนี้ลองฝึกร่างเสือ ที่ทุ่งนาไปก่อนนะ บอสนักษัตรตัวต่อไป กำลังจะมาเร็ว ๆ นี้"}])


func _talk_auntie() -> void:
	Game.start_dialogue([
		{"who": "ป้าศรี", "text": "ไหว้พระเถอะลูก จะออกไปทุ่งนาเหรอ ป้าสอนให้ก่อน"},
		{"who": "ป้าศรี", "text": "กด J เพื่อตี กด U I O เพื่อใช้สกิล กด Space เพื่อกระโดด และกด S พร้อม Space เพื่อลงจากแท่น"},
		{"who": "ป้าศรี", "text": "ถ้าเจ็บตัว ยืนพักสักครู่ เลือดจะค่อย ๆ ฟื้นเอง"},
	])


func _talk_uncle() -> void:
	Game.start_dialogue([
		{"who": "ลุงหมู", "text": "หมูน้อยของลุง ตัวละ 60 บาท... แต่ตอนนี้ยังไม่เปิดขายนะหลาน รอร้านเปิดก่อน"},
	])
