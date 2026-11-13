extends Stage
## แผนที่ 1: หมู่บ้าน (ปลอดภัย ไม่มีมอนสเตอร์) — มีทางเข้าบ้านผู้ใหญ่บ้าน (หอบูชา 12 นักษัตร)


func build() -> void:
	width = 6400.0
	title = "หมู่บ้านนักษัตร"
	style = "village"
	spawns = {"start": Vector2(420, GROUND_Y), "from_field": Vector2(6080, GROUND_Y), "from_house": Vector2(2050, GROUND_Y)}

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
	add_prop("gate", 2050.0)
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
	add_npc(1150.0, "ป้าศรี", {"shirt": Color(0.95, 0.6, 0.7), "pants": Color(0.5, 0.25, 0.4), "accent": Color(1, 1, 1), "hair": Color(0.25, 0.18, 0.15), "hat": "bun", "sprite": "res://assets/art/npc_auntie.png"}, _talk_auntie)
	add_npc(4360.0, "ลุงหมู", {"shirt": Color(0.6, 0.8, 0.5), "pants": Color(0.35, 0.3, 0.2), "accent": Color(0.4, 0.3, 0.2), "hair": Color(0.2, 0.2, 0.2), "hat": "straw", "sprite": "res://assets/art/npc_uncle.png"}, _talk_uncle)

	# ---- ประตู ----
	add_portal(2050.0, "บ้านผู้ใหญ่บ้าน", "chief_house", "entrance", Callable(), Color(1.0, 0.82, 0.4))
	add_portal(6240.0, "ไปทุ่งนา", "rice_field", "from_village", Callable(), Color(0.6, 1.0, 0.5))


func _talk_auntie() -> void:
	# ร้านยาป้าศรี: คุย 1 ครั้ง = ซื้อยาแดง 1 ขวด
	var price := int(Game.ITEMS["potion"]["buy"])
	if Game.buy_item("potion"):
		Game.start_dialogue([
			{"who": "ป้าศรี", "text": "ยาแดงขวดละ %d บาทจ้ะ นี่จ้ะ 1 ขวด (ตอนนี้มี %d ขวด เหลือเงิน %d บาท) กด F เพื่อดื่ม ตอนเลือดเหลือน้อยนะลูก" % [price, Game.item_count("potion"), Game.money]},
		])
	else:
		Game.start_dialogue([
			{"who": "ป้าศรี", "text": "ป้าขายยาแดง ขวดละ %d บาทจ้ะ แต่หนูมีแค่ %d บาท ไปตีมอนสเตอร์ ที่ทุ่งนา เก็บเหรียญมาก่อนนะ" % [price, Game.money]},
			{"who": "ป้าศรี", "text": "ของที่มอนสเตอร์ทำตก เอาไปขาย ให้ลุงหมูได้ กด I เพื่อเปิดกระเป๋าดูของ"},
		])


func _talk_uncle() -> void:
	# ลุงหมูรับซื้อของดรอปทั้งหมด
	var earned := Game.sell_materials()
	if earned > 0:
		Game.start_dialogue([
			{"who": "ลุงหมู", "text": "ของดี ๆ ทั้งนั้นเลยหลาน ลุงรับซื้อหมด ได้ไป %d บาท (ตอนนี้มี %d บาท)" % [earned, Game.money]},
		])
	else:
		Game.start_dialogue([
			{"who": "ลุงหมู", "text": "ลุงรับซื้อ ขากบ ชิ้นละ %d บาท กับ หมวกเห็ดพิษ ชิ้นละ %d บาท ไปหามาจากทุ่งนา แล้วเอามาขายลุงได้เลย" % [int(Game.ITEMS["frog_leg"]["sell"]), int(Game.ITEMS["mushroom_cap"]["sell"])]},
		])
