extends Stage
## หมู่บ้าน 2: บ้านผาจันทร์ (หมู่บ้านบนเชิงเขา ปลอดภัย ไม่มีมอนสเตอร์)
## ขวาสุด = กลับหมู่บ้านนักษัตร, กลางหมู่บ้าน = เรือนยายจันทร์ (หอบูชา), ซ้ายสุด = ป่าไผ่ผาจันทร์
## ทางไปหมู่บ้าน 3 (ทะเลสาบพญานาค) อยู่ฝั่งซ้าย ล็อกไว้จนกว่าจะได้ใบเบิกทาง

const VILLAGE_NO := 2


func build() -> void:
	width = 5600.0
	title = "บ้านผาจันทร์"
	style = "village2"
	spawns = {
		"start": Vector2(2600, GROUND_Y), "from_village1": Vector2(5300, GROUND_Y),
		"from_house": Vector2(2900, GROUND_Y), "from_forest": Vector2(330, GROUND_Y),
	}
	Game.arrive_village(VILLAGE_NO)

	add_sign(560.0, "← ป่าไผ่ผาจันทร์")
	add_sign(1060.0, "← ทะเลสาบพญานาค")
	add_sign(5120.0, "หมู่บ้านนักษัตร →")
	add_prop("gate", 2900.0)

	# ---- แคร่ไม้ไผ่ให้กระโดดเล่น ----
	add_platform(1500.0, 470.0, 220.0)
	add_platform(1800.0, 350.0, 200.0)
	add_platform(3500.0, 460.0, 240.0)
	add_platform(3850.0, 340.0, 200.0)
	add_platform(4300.0, 470.0, 220.0)

	# ---- ชาวบ้าน ----
	add_npc(1950.0, "แม่ค้าดอย", {"shirt": Color(0.3, 0.25, 0.4), "hat": "", "sprite": "res://assets/art/npc_merchant.png"}, _talk_merchant)
	add_npc(3350.0, "ลุงเหล็ก", {"shirt": Color(0.45, 0.35, 0.3), "hat": "", "sprite": "res://assets/art/npc_smith.png"}, _talk_smith)

	# ---- ประตู ----
	add_portal(90.0, "ป่าไผ่ผาจันทร์", "bamboo_forest", "from_village", Callable(), Color(0.6, 1.0, 0.5))
	add_portal(1060.0, "ไปทะเลสาบพญานาค", "village", "start", _next_village_lock, Color(1.0, 0.6, 0.9))
	add_portal(2900.0, "เรือนยายจันทร์", "elder_house", "entrance", Callable(), Color(1.0, 0.82, 0.4))
	add_portal(5480.0, "กลับหมู่บ้านนักษัตร", "village", "from_village2", Callable(), Color(0.5, 0.85, 1.0))


func _next_village_lock() -> String:
	if Game.travel_permit <= VILLAGE_NO:
		return "ทางไปทะเลสาบพญานาค ต้องมี ใบเบิกทาง จากยายจันทร์ก่อน (ทำเควสของหมู่บ้านนี้ให้ครบ)"
	return "หมู่บ้านถัดไป กำลังสร้างอยู่ เร็ว ๆ นี้!"


func _talk_merchant() -> void:
	# แม่ค้าดอย: ร้านขาย-รับซื้อของ (หน้าร้านเดียวกับป้าศรี)
	if not Game.has_meta("merchant2_met"):
		Game.set_meta("merchant2_met", true)
		Game.start_dialogue([
			{"who": "แม่ค้าดอย", "text": "สวัสดีจ้า คนจากหมู่บ้านล่างหรือ ของในตะกร้าฉัน ขนขึ้นดอยมาเองเลยนะ ของเก่าของหลานก็ขายให้ฉันได้"},
		], func() -> void: Game.open_shop())
	else:
		Game.open_shop()


func _talk_smith() -> void:
	if not Game.has_meta("smith2_met"):
		Game.set_meta("smith2_met", true)
		Game.start_dialogue([
			{"who": "ลุงเหล็ก", "text": "อ้าว เจอกันอีกแล้ว! ลุงตามขึ้นมาตั้งเตาบนผาจันทร์ เพราะของในป่าไผ่นี่ดีกว่าข้างล่างเยอะ"},
			{"who": "ลุงเหล็ก", "text": "เขาด้วงกว่าง แข็งยิ่งกว่าเหล็ก แก่นไผ่ ก็เหนียวสุด ๆ เอามาให้ลุงตีได้เลย"},
		], func() -> void: Game.open_crafting())
	else:
		Game.open_crafting()
