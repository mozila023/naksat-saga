class_name Zodiac
## ข้อมูล 12 นักษัตร (+ ร่างเทพ) เรียงตามปีจริง: นักษัตรแต่ละตัวมาทดสอบตัวเอกทุก 10 เลเวล
## ชนะการประลอง = ได้ร่างแปลงของนักษัตรตัวนั้น
##
## ready = มีภาพและบอสพร้อมแล้ว (ตัวที่ยังไม่พร้อม เกมจะบอกว่า "เร็ว ๆ นี้")
## หมู่บ้าน: หมู่บ้านที่ N มีเลเวลตัน N x 20 และนักษัตร 2 ตัว (เลเวล 20N-10 และ 20N) เช่น หมู่บ้าน 1 = ชวด + ฉลู
## arena = แผนที่ที่ใช้ประลอง, boss = ค่าของบอส (ดู ZodiacBoss)

const LIST := [
	{"id": "rat", "year": "ชวด", "animal": "หนู", "level": 10, "ready": true, "arena": "trial_hall",
		"color": Color(0.7, 0.85, 1.0),
		"boss": {"name": "ชวด — มูสิกะผู้พิทักษ์", "hp": 450.0, "size": Vector2(140, 72), "frames": "rat_boss",
			"walk": [230.0, 300.0], "tel": 0.8, "claw": 12.0, "pounce": 14.0, "contact": 8.0, "wave": 10.0,
			"reach": 200.0, "shout": "จี๊ด!!", "aura": Color(0.6, 0.85, 1.0)},
		"intro": [
			"จี๊ด! เจ้าหนูน้อย ข้าคือ ชวด ผู้พิทักษ์ปีหนู นักษัตรตัวแรก แห่ง 12 นักษัตร",
			"ข้าจะยืมพลังให้ เฉพาะคนที่ว่องไว พอจะตามข้าทัน มาประลองกันสักตั้ง!",
		],
		"win": "ว่องไวกว่าที่คิด! พลังปีชวดเป็นของเจ้าแล้ว รับชิ้นส่วนของข้าไป ให้ช่างตีเหล็กทำเป็นชุดได้"},
	{"id": "ox", "year": "ฉลู", "animal": "วัว", "level": 20, "ready": true, "arena": "trial_hall",
		"color": Color(0.85, 0.6, 0.35),
		"boss": {"name": "ฉลู — มหาอุสุภราช", "hp": 900.0, "size": Vector2(150, 150), "frames": "ox_boss",
			"walk": [140.0, 190.0], "tel": 1.1, "claw": 18.0, "pounce": 22.0, "contact": 12.0, "wave": 16.0,
			"reach": 250.0, "shout": "ฮึ่มมม!!", "aura": Color(1.0, 0.75, 0.4)},
		"intro": [
			"ฮึ่ม... ข้าคือ ฉลู ผู้พิทักษ์ปีวัว นักษัตรผู้แข็งแกร่ง ดั่งภูผา",
			"เจ้าว่องไวแล้ว แต่ความว่องไวจะไร้ค่า ถ้าใจไม่หนักแน่น มารับแรงขวานของข้าดู!",
		],
		"win": "ยืนหยัดได้จนจบ! พลังปีฉลูเป็นของเจ้าแล้ว รับชิ้นส่วนของข้าไปให้ช่างตีเป็นชุดเกราะเถิด"},
	{"id": "tiger", "year": "ขาล", "animal": "เสือ", "level": 30, "ready": true, "arena": "trial_hall",
		"color": Color(1.0, 0.7, 0.3),
		"boss": {"name": "ขาล — พญาเสือโคร่ง", "hp": 650.0, "size": Vector2(170, 118), "frames": "tiger_boss",
			"walk": [160.0, 220.0], "tel": 1.0, "claw": 16.0, "pounce": 20.0, "contact": 10.0, "wave": 14.0,
			"reach": 240.0, "shout": "โฮก!!", "aura": Color(1.0, 0.7, 0.3)},
		"intro": [
			"โฮก... ข้าคือ ขาล พญาเสือโคร่ง ผู้พิทักษ์ปีเสือ",
			"ข้ารอเจ้าอยู่ใน ห้องประลอง หลังบ้านผู้ใหญ่ มาพิสูจน์ความกล้าของเจ้า!",
		],
		"win": "ใจเด็ดสมเป็นนักสู้! พลังปีขาลเป็นของเจ้าแล้ว รับชิ้นส่วนของข้าไปให้ช่างตีเป็นชุดได้"},
	{"id": "rabbit", "year": "เถาะ", "animal": "กระต่าย", "level": 40, "ready": false},
	{"id": "dragon", "year": "มะโรง", "animal": "มังกร", "level": 50, "ready": false},
	{"id": "snake", "year": "มะเส็ง", "animal": "งูเล็ก", "level": 60, "ready": false},
	{"id": "horse", "year": "มะเมีย", "animal": "ม้า", "level": 70, "ready": false},
	{"id": "goat", "year": "มะแม", "animal": "แพะ", "level": 80, "ready": false},
	{"id": "monkey", "year": "วอก", "animal": "ลิง", "level": 90, "ready": false},
	{"id": "rooster", "year": "ระกา", "animal": "ไก่", "level": 100, "ready": false},
	{"id": "dog", "year": "จอ", "animal": "หมา", "level": 110, "ready": false},
	{"id": "pig", "year": "กุน", "animal": "หมู", "level": 120, "ready": false},
	{"id": "god", "year": "เทพ", "animal": "ร่างเทพ", "level": 150, "ready": false},
]


static func get_data(id: String) -> Dictionary:
	for z in LIST:
		if z["id"] == id:
			return z
	return {}


## หมู่บ้านที่นักษัตรตัวนี้อยู่ (ทุก 20 เลเวล = 1 หมู่บ้าน)
static func village_of(z: Dictionary) -> int:
	return (int(z["level"]) - 1) / 20 + 1


## นักษัตรที่พร้อมให้ประลองตอนนี้ (เลเวลถึง + อยู่หมู่บ้านที่ไปถึงแล้ว + มีของพร้อม + ยังไม่ได้ร่าง) — ตัวแรกตามลำดับปี
static func available(level: int, unlocked: Array) -> Dictionary:
	for z in LIST:
		if z["ready"] and level >= int(z["level"]) and village_of(z) <= Game.village and not (z["id"] in unlocked):
			return z
	return {}


## นักษัตรที่พร้อมแล้วตัวถัดไปที่เลเวลยังไม่ถึง
static func upcoming(level: int, unlocked: Array) -> Dictionary:
	for z in LIST:
		if z["ready"] and level < int(z["level"]) and village_of(z) <= Game.village and not (z["id"] in unlocked):
			return z
	return {}


static func display_name(z: Dictionary) -> String:
	return "%s (%s)" % [z["year"], z["animal"]]
