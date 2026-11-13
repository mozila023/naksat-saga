class_name Forms
## ข้อมูลร่างทั้งหมดของตัวเอก
## เพิ่มร่างใหม่ = เพิ่มข้อมูลอีก 1 ก้อนใน LIST (ไม่ต้องเขียนระบบใหม่)
##
## ชนิดสกิล (kind):
##   melee = ตีด้านหน้า   (w, h = ขนาดระยะตี, hits = จำนวนครั้ง, interval = เวลาห่างแต่ละครั้ง)
##   dash  = พุ่งตัว       (speed, time, jump = แรงกระโดดตอนพุ่ง, dmg = ดาเมจตอนชน, invuln = อมตะระหว่างพุ่ง)
##   aoe   = ตีรอบตัว     (radius, stun = เวลาที่ศัตรูมึน)
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
			"stripes": false,
			"weapon": Color(0.65, 0.45, 0.25),
		},
		"skills": [
			{"name": "ฟันแรง", "kind": "melee", "cd": 2.0, "dmg": 2.2, "w": 130.0, "h": 100.0, "hits": 1, "interval": 0.0, "fx": "slash"},
			{"name": "พุ่งหลบ", "kind": "dash", "cd": 3.0, "speed": 900.0, "time": 0.18, "jump": 0.0, "dmg": 0.0, "invuln": true},
			{"name": "หมุนฟาด", "kind": "aoe", "cd": 8.0, "dmg": 3.0, "radius": 150.0, "stun": 0.6},
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
			"stripes": true,
			"weapon": Color(1.0, 0.95, 0.8),
		},
		"skills": [
			{"name": "กรงเล็บ", "kind": "melee", "cd": 2.5, "dmg": 1.2, "w": 140.0, "h": 110.0, "hits": 3, "interval": 0.12, "fx": "claw"},
			{"name": "กระโจน", "kind": "dash", "cd": 4.0, "speed": 760.0, "time": 0.32, "jump": -420.0, "dmg": 2.0, "invuln": true},
			{"name": "คำราม", "kind": "aoe", "cd": 12.0, "dmg": 4.0, "radius": 260.0, "stun": 2.0},
		],
	},
]


static func get_form(id: String) -> Dictionary:
	for f in LIST:
		if f["id"] == id:
			return f
	return LIST[0]
