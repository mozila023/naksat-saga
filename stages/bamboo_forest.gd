extends Stage
## ป่าไผ่ผาจันทร์ (หมู่บ้าน 2, มีมอนสเตอร์): ฝั่งหมู่บ้าน (ขวา) เป็นด้วงกว่าง ลึกเข้าไป (ซ้าย) เป็นผีไผ่
## สุดทางซ้ายคือถ้ำผีโป่งค่าง (Lv.35 ขึ้นไป)


func build() -> void:
	width = 9800.0
	title = "ป่าไผ่ผาจันทร์"
	style = "forest"
	spawns = {"from_village": Vector2(9520, GROUND_Y), "from_lair": Vector2(420, GROUND_Y)}

	add_portal(9700.0, "กลับบ้านผาจันทร์", "village2", "from_forest", Callable(), Color(0.5, 0.85, 1.0))
	add_sign(9300.0, "← ระวังด้วงกว่าง!")
	add_sign(5000.0, "← ดงผีไผ่")
	add_sign(800.0, "← ถ้ำผีโป่งค่าง")

	# ---- โซนด้วงกว่าง (x 5400 - 9200) ----
	add_platform(8700.0, 470.0, 340.0)
	add_platform(8200.0, 350.0, 300.0)
	add_platform(7600.0, 470.0, 400.0)
	add_platform(7050.0, 340.0, 320.0)
	add_platform(6500.0, 460.0, 380.0)
	add_platform(5800.0, 350.0, 320.0)
	for x in [9000.0, 8400.0, 7800.0, 7150.0, 6500.0, 5850.0]:
		add_spawner("beetle", x, GROUND_Y, 260.0)
	add_spawner("beetle", 8850.0, 470.0, 150.0)
	add_spawner("beetle", 7780.0, 470.0, 180.0)
	add_spawner("beetle", 6650.0, 460.0, 170.0)

	# ---- โซนผีไผ่ (x 1300 - 4800) ----
	add_platform(4300.0, 470.0, 380.0)
	add_platform(3800.0, 350.0, 320.0)
	add_platform(3200.0, 470.0, 420.0)
	add_platform(2650.0, 340.0, 300.0)
	add_platform(2100.0, 460.0, 400.0)
	add_platform(1500.0, 350.0, 320.0)
	for x in [4600.0, 3950.0, 3300.0, 2650.0, 2000.0, 1450.0]:
		add_spawner("bamboo_ghost", x, GROUND_Y, 240.0)
	add_spawner("bamboo_ghost", 4480.0, 470.0, 160.0)
	add_spawner("bamboo_ghost", 3400.0, 470.0, 180.0)
	add_spawner("beetle", 3950.0, 350.0, 130.0)
	add_spawner("bamboo_ghost", 2300.0, 460.0, 170.0)
	add_spawner("bamboo_ghost", 1650.0, 350.0, 130.0)

	# ---- ปากถ้ำผีโป่งค่าง (เข้าได้ตั้งแต่ Lv.35) ----
	add_prop("cave_mouth", 200.0)
	add_portal(200.0, "ถ้ำผีโป่งค่าง", "ghost_lair", "entrance", _lair_lock, Color(0.75, 0.5, 1.0))


func _lair_lock() -> String:
	if Game.level < GhostLair.MIN_LEVEL:
		return "เสียงคำรามในถ้ำ ทำเอาขาสั่น... ต้อง Lv.%d ขึ้นไป ถึงจะกล้าเข้าไป" % GhostLair.MIN_LEVEL
	return ""
