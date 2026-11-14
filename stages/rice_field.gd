extends Stage
## แผนที่ 2: ทุ่งนา (มีมอนสเตอร์) — ครึ่งแรกเป็นกบนา ครึ่งหลังเป็นเห็ดพิษ สุดทางคือถ้ำของยักษ์หมอกทมิฬ


func build() -> void:
	width = 9600.0
	title = "ทุ่งนาท้ายหมู่บ้าน"
	style = "field"
	spawns = {"from_village": Vector2(240, GROUND_Y), "from_cave": Vector2(9180, GROUND_Y)}

	add_bg("clouds", 0.05, -8.0)
	add_bg("hills", 0.12)
	add_bg("field_mid", 0.35)

	add_portal(90.0, "กลับหมู่บ้าน", "village", "from_field", Callable(), Color(0.5, 0.85, 1.0))
	add_sign(420.0, "ระวังกบนา!")

	# ---- ของประกอบฉาก ----
	for x in [700.0, 2300.0, 3900.0, 6300.0, 8000.0]:
		add_prop("haystack", x)
	for x in [1300.0, 3100.0, 5600.0, 7300.0]:
		add_prop("scarecrow", x)
	for x in [1000.0, 1900.0, 2700.0, 4400.0, 5100.0, 6000.0, 6900.0, 7700.0, 8600.0]:
		add_prop("tree" if int(x) % 200 == 0 else "banana", x)
	for x in [1600.0, 3500.0, 4800.0, 6600.0, 8300.0]:
		add_prop("rock", x)
	add_sign(4750.0, "ดงเห็ดพิษ →")
	add_sign(8900.0, "ถ้ำยักษ์ →")
	add_prop("cave_mouth", 9400.0)

	# ---- โซนกบนา (x 600 - 4500) ----
	add_platform(800.0, 470.0, 360.0)
	add_platform(1250.0, 350.0, 300.0)
	add_platform(1700.0, 470.0, 420.0)
	add_platform(2400.0, 460.0, 360.0)
	add_platform(2850.0, 340.0, 320.0)
	add_platform(3300.0, 470.0, 400.0)
	add_platform(3950.0, 450.0, 380.0)
	for x in [900.0, 1500.0, 2100.0, 2750.0, 3400.0, 4050.0]:
		add_spawner("frog", x, GROUND_Y, 260.0)
	add_spawner("frog", 980.0, 470.0, 150.0)
	add_spawner("frog", 1910.0, 470.0, 180.0)
	add_spawner("frog", 3010.0, 340.0, 130.0)
	add_spawner("frog", 3500.0, 470.0, 170.0)

	# ---- โซนเห็ดพิษ (x 5000 - 8800) ----
	add_platform(5150.0, 470.0, 380.0)
	add_platform(5650.0, 350.0, 320.0)
	add_platform(6150.0, 470.0, 420.0)
	add_platform(6750.0, 340.0, 300.0)
	add_platform(7150.0, 460.0, 400.0)
	add_platform(7800.0, 350.0, 320.0)
	add_platform(8250.0, 470.0, 380.0)
	for x in [5300.0, 5950.0, 6600.0, 7250.0, 7900.0, 8500.0]:
		add_spawner("mushroom", x, GROUND_Y, 240.0)
	add_spawner("mushroom", 5340.0, 470.0, 160.0)
	add_spawner("frog", 5810.0, 350.0, 130.0)
	add_spawner("mushroom", 6360.0, 470.0, 180.0)
	add_spawner("mushroom", 7350.0, 460.0, 170.0)
	add_spawner("frog", 7960.0, 350.0, 130.0)

	# ---- ปากถ้ำยักษ์หมอกทมิฬ (เข้าได้ตั้งแต่ Lv.15) ----
	add_portal(9400.0, "ถ้ำยักษ์หมอกทมิฬ", "demon_lair", "entrance", _cave_lock, Color(0.75, 0.5, 1.0))


func _cave_lock() -> String:
	if Game.level < DemonLair.MIN_LEVEL:
		return "หมอกทมิฬหนาเกินไป... ต้อง Lv.%d ขึ้นไป ถึงจะฝ่าเข้าไปได้" % DemonLair.MIN_LEVEL
	return ""
