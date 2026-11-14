class_name GhostLair extends Stage
## ถ้ำผีโป่งค่าง (สุดทางป่าไผ่ หมู่บ้าน 2) — บอสปีศาจที่ตีซ้ำได้ทุกครั้งที่เข้ามา

const MIN_LEVEL := 35


func build() -> void:
	width = 2200.0
	title = "ถ้ำผีโป่งค่าง"
	style = "cave"
	spawns = {"entrance": Vector2(1940, GROUND_Y)}

	for x in [200.0, 700.0, 1100.0, 1500.0, 2000.0]:
		add_prop("torch", x)

	add_platform(560.0, 440.0, 220.0)
	add_platform(1420.0, 440.0, 220.0)

	add_portal(2100.0, "ออกจากถ้ำ", "bamboo_forest", "from_lair", Callable(), Color(0.6, 1.0, 0.5))

	var boss := ZodiacBoss.create("pong_khang")
	boss.position = Vector2(550, GROUND_Y - 2.0)
	boss.arena_left = 120.0
	boss.arena_right = width - 330.0
	add_child(boss)
