class_name Quests
## เควสหลักจากผู้ใหญ่บ้าน (ทำเรียงตามลำดับ) — แต่ละหมู่บ้านมีหลายเควส เควสสุดท้ายคือใบเบิกทางไปหมู่บ้านถัดไป
##
## ชนิดเควส (type):
##   kill    = กำจัด target ให้ครบ n ตัว (นับเฉพาะหลังรับเควส)
##   collect = หาไอเทม target มาส่ง n ชิ้น (ส่งแล้วของหายไป)
##   zodiac  = ผ่านการประลองกับนักษัตร target
##   craft   = คราฟของที่ช่างตีเหล็ก n ชิ้น
##   travel  = ใบเบิกทางไปหมู่บ้าน target (ได้ทันทีที่รับ)
## give = บทพูดตอนให้เควส, reward = {"exp", "money", "items": {รหัส: จำนวน}}

const CHIEF := "ผู้ใหญ่บ้าน"

const LIST := [
	{"village": 1, "type": "kill", "target": "frog", "n": 5, "title": "กำจัดกบนาที่ทุ่งนา",
		"give": [
			"มาแล้วหรือ {name} บ้านลุงเป็น หอบูชา 12 นักษัตร ผู้พิทักษ์หมู่บ้านเรามาแต่โบราณ",
			"นักษัตรจะยืมพลังแปลงร่าง ให้คนที่ผ่านการประลองเท่านั้น หมู่บ้านเรามีนักษัตรคุ้มครอง 2 องค์ คือ ชวด กับ ฉลู",
			"เริ่มจากฝึกฝีมือก่อน ไปกำจัด กบนา 5 ตัว ที่ทุ่งนา ทางขวาของหมู่บ้าน",
		], "reward": {"money": 30, "items": {"potion": 1}}},
	{"village": 1, "type": "collect", "target": "frog_leg", "n": 5, "title": "หาขากบให้ป้าศรี",
		"give": ["ป้าศรีอยากได้ ขากบ ไปทำแกงเลี้ยงคนทั้งหมู่บ้าน หลานช่วยหามาให้ 5 ชิ้นได้ไหม"],
		"reward": {"money": 40, "items": {"potion": 1}}},
	{"village": 1, "type": "kill", "target": "mushroom", "n": 6, "title": "กำจัดเห็ดพิษ",
		"give": ["เห็ดพิษ ลุกลามมาจากทุ่งนาฝั่งไกล ชาวนาเดือดร้อนกันหมด ไปกำจัดมัน 6 ตัว"],
		"reward": {"exp": 120, "items": {"potion": 2}}},
	{"village": 1, "type": "zodiac", "target": "rat", "title": "ประลองกับ ชวด (หนู)",
		"give": ["ได้เวลาแล้ว เมื่อหลานถึง Lv.10 ชวด นักษัตรองค์แรก จะปรากฏที่หิ้งบูชานี้ ไปพิสูจน์ตัวเองให้ท่านเห็น"],
		"reward": {"money": 50}},
	{"village": 1, "type": "craft", "n": 1, "title": "ให้ช่างตีเหล็กทำของ",
		"give": ["นักษัตรมอบชิ้นส่วนให้หลานแล้วใช่ไหม เอาไปให้ ลุงเหล็ก ช่างตีเหล็กกลางหมู่บ้าน ตีเป็นของใช้สักชิ้นสิ"],
		"reward": {"money": 50}},
	{"village": 1, "type": "kill", "target": "mist_giant", "n": 1, "title": "ปราบยักษ์หมอกทมิฬ",
		"give": ["หมอกดำ ที่ปกคลุมแผ่นดิน มาจากถ้ำสุดทางทุ่งนา มี ยักษ์หมอกทมิฬ ซ่อนอยู่ เมื่อหลานถึง Lv.15 จงไปปราบมัน"],
		"reward": {"exp": 300, "items": {"potion": 3}}},
	{"village": 1, "type": "collect", "target": "mushroom_cap", "n": 6, "title": "หาหมวกเห็ดพิษให้ลุงหมู",
		"give": ["ลุงหมูจะเอา หมวกเห็ดพิษ ไปทำยาแก้พิษ ให้ชาวบ้าน หามาให้ 6 ชิ้น"],
		"reward": {"money": 80}},
	{"village": 1, "type": "zodiac", "target": "ox", "title": "ประลองกับ ฉลู (วัว)",
		"give": ["นักษัตรองค์ที่ 2 ของหมู่บ้านเรา คือ ฉลู ผู้แข็งแกร่งดั่งภูผา ท่านจะมาทดสอบหลานเมื่อถึง Lv.20"],
		"reward": {"money": 100}},
	{"village": 1, "type": "travel", "target": 2, "title": "เดินทางไปหมู่บ้านถัดไป",
		"give": [
			"หลานผ่านการทดสอบของนักษัตร ทั้ง 2 องค์ของหมู่บ้านเราแล้ว ลุงภูมิใจมาก",
			"นี่คือ ใบเบิกทาง ออกไปทางประตูซ้ายสุดของหมู่บ้าน นักษัตรองค์ต่อไป รออยู่ที่หมู่บ้านถัดไป",
		], "reward": {}},
]


static func get_quest(index: int) -> Dictionary:
	return LIST[index] if index >= 0 and index < LIST.size() else {}


## ข้อความบอกความคืบหน้า เช่น "3/5"
static func progress_text(q: Dictionary) -> String:
	match q.get("type", ""):
		"kill", "craft":
			return "%d/%d" % [mini(Game.quest_progress, int(q["n"])), int(q["n"])]
		"collect":
			return "%d/%d" % [mini(Game.item_count(q["target"]), int(q["n"])), int(q["n"])]
	return ""


## เควสนี้ทำครบแล้วหรือยัง
static func is_done(q: Dictionary) -> bool:
	match q.get("type", ""):
		"kill", "craft":
			return Game.quest_progress >= int(q["n"])
		"collect":
			return Game.item_count(q["target"]) >= int(q["n"])
		"zodiac":
			return q["target"] in Game.unlocked
		"travel":
			return true
	return false
