class_name Forms
## ข้อมูลร่างทั้งหมดของตัวเอก
## เพิ่มร่างใหม่ = เพิ่มข้อมูลอีก 1 ก้อนใน LIST (ไม่ต้องเขียนระบบใหม่)
##
## ชนิดสกิล (kind):
##   melee = ตีด้านหน้า   (w, h = ขนาดระยะตี, hits = จำนวนครั้ง, interval = เวลาห่างแต่ละครั้ง)
##   dash  = พุ่งตัว       (speed, time, jump = แรงกระโดดตอนพุ่ง, dmg = ดาเมจตอนชน, invuln = อมตะระหว่างพุ่ง)
##   aoe   = ตีรอบตัว     (radius, stun = เวลาที่ศัตรูมึน, style = หน้าตาเอฟเฟกต์: spin หมุนฟาด / roar คำราม)
## dmg = ตัวคูณดาเมจ, cd = คูลดาวน์ (วินาที)

const LIST := [
	{
		"id": "normal",
		"name": "ร่างปกติ",
		"short": "ปกติ",
		"speed": 1.0,
		"jump": 1.0,
		"atk": 1.0,
		"outfit": {
			"shirt": Color(0.93, 0.95, 0.98),
			"pants": Color(0.25, 0.35, 0.6),
			"accent": Color(0.85, 0.3, 0.3),
			"hair": Color(0.12, 0.1, 0.12),
			"ears": "",
			"sprite": "res://assets/art/hero_normal.png",
			"frames": "res://assets/art/frames/hero_normal_",
			"grip": "normal",  # ตำแหน่งมือในท่าตี (ดู ChibiVisual.GRIPS)
			"rig": {"head_y": 0.535, "hip_y": 0.81, "arm_l": 0.335, "arm_r": 0.715, "leg_split": 0.52},
			"weapon_kind": "sword",
			"stripes": false,
			"weapon": Color(0.65, 0.45, 0.25),
		},
		"skills": [
			{"name": "ฟันแรง", "kind": "melee", "cd": 2.0, "dmg": 2.2, "w": 130.0, "h": 100.0, "hits": 1, "interval": 0.0, "fx": "slash"},
			{"name": "พุ่งหลบ", "kind": "dash", "cd": 3.0, "speed": 900.0, "time": 0.18, "jump": 0.0, "dmg": 0.0, "invuln": true},
			{"name": "หมุนฟาด", "kind": "aoe", "cd": 8.0, "dmg": 3.0, "radius": 150.0, "stun": 0.6, "style": "spin"},
		],
	},
	{
		"id": "rat",
		"name": "ร่างชวด (หนู)",
		"short": "หนู",
		"speed": 1.25,
		"jump": 1.1,
		"atk": 0.95,
		"outfit": {
			"shirt": Color(0.78, 0.8, 0.84),
			"pants": Color(0.15, 0.15, 0.18),
			"accent": Color(1.0, 0.6, 0.65),
			"hair": Color(0.12, 0.1, 0.12),
			"ears": "",
			"sprite": "res://assets/art/hero_rat.png",
			"frames": "res://assets/art/frames/hero_rat_",
			"weapon_kind": "claw",
			"stripes": false,
			"weapon": Color(1.0, 0.95, 0.9),
		},
		"skills": [
			{"name": "แทะรัว", "kind": "melee", "cd": 2.0, "dmg": 0.75, "w": 110.0, "h": 90.0, "hits": 4, "interval": 0.08, "fx": "claw"},
			{"name": "วิ่งพรวด", "kind": "dash", "cd": 2.5, "speed": 1150.0, "time": 0.24, "jump": 0.0, "dmg": 1.3, "invuln": true},
			{"name": "เสียงจี๊ด", "kind": "aoe", "cd": 9.0, "dmg": 2.6, "radius": 220.0, "stun": 1.4, "style": "roar", "shout": "จี๊ด!!"},
		],
	},
	{
		"id": "ox",
		"name": "ร่างฉลู (วัว)",
		"short": "วัว",
		"speed": 0.92,
		"jump": 0.95,
		"atk": 1.25,
		"outfit": {
			"shirt": Color(0.55, 0.35, 0.2),
			"pants": Color(0.3, 0.2, 0.12),
			"accent": Color(0.95, 0.75, 0.3),
			"hair": Color(0.12, 0.1, 0.12),
			"ears": "",
			"sprite": "res://assets/art/hero_ox.png",
			"frames": "res://assets/art/frames/hero_ox_",
			"weapon_kind": "sword",
			"stripes": false,
			"weapon": Color(0.95, 0.8, 0.35),
		},
		"skills": [
			{"name": "ขวานทุบ", "kind": "melee", "cd": 2.6, "dmg": 2.8, "w": 150.0, "h": 120.0, "hits": 1, "interval": 0.0, "fx": "slash"},
			{"name": "พุ่งชน", "kind": "dash", "cd": 3.5, "speed": 820.0, "time": 0.3, "jump": 0.0, "dmg": 2.2, "invuln": true},
			{"name": "กระทืบปฐพี", "kind": "aoe", "cd": 10.0, "dmg": 3.6, "radius": 240.0, "stun": 1.8, "style": "roar", "shout": "ฮึ่ม!!"},
		],
	},
	{
		"id": "tiger",
		"name": "ร่างขาล (เสือ)",
		"short": "เสือ",
		"speed": 1.1,
		"jump": 1.05,
		"atk": 1.3,
		"outfit": {
			"shirt": Color(0.96, 0.6, 0.15),
			"pants": Color(0.2, 0.15, 0.12),
			"accent": Color(0.15, 0.1, 0.08),
			"hair": Color(0.12, 0.1, 0.12),
			"ears": "tiger",
			"sprite": "res://assets/art/hero_tiger.png",
			"frames": "res://assets/art/frames/hero_tiger_",
			"rig": {"head_y": 0.56, "hip_y": 0.81, "arm_l": 0.31, "arm_r": 0.725, "leg_split": 0.5, "leg_x0": 0.31, "back_static": true},
			"weapon_kind": "claw",
			"stripes": true,
			"weapon": Color(1.0, 0.95, 0.8),
		},
		"skills": [
			{"name": "กรงเล็บ", "kind": "melee", "cd": 2.5, "dmg": 1.2, "w": 140.0, "h": 110.0, "hits": 3, "interval": 0.12, "fx": "claw"},
			{"name": "กระโจน", "kind": "dash", "cd": 4.0, "speed": 760.0, "time": 0.32, "jump": -420.0, "dmg": 2.0, "invuln": true},
			{"name": "คำราม", "kind": "aoe", "cd": 12.0, "dmg": 4.0, "radius": 260.0, "stun": 2.0, "style": "roar"},
		],
	},
]


static func get_form(id: String) -> Dictionary:
	for f in LIST:
		if f["id"] == id:
			return f
	return LIST[0]
