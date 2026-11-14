class_name Crafting
## ระบบคราฟของที่ช่างตีเหล็ก
##
## คุณภาพ (สุ่มตอนคราฟ): ธรรมดา / หายาก / สุดยอด / ตำนาน — ยิ่งสูงค่าพลังยิ่งมาก
## ชุดเซ็ทนักษัตร: ทำจากชิ้นส่วนที่นักษัตรมอบให้ตอนชนะการประลอง (ตัวละ 1 ชุด)
##   เขี้ยว/เขา -> อาวุธ, หัว -> หมวก, หนัง -> ชุด, เท้า -> รองเท้า, หาง -> เครื่องราง
##   ใส่ครบ 3 ชิ้น / 5 ชิ้น ได้ความสามารถพิเศษต่างกันตามนักษัตร
##
## รหัสของที่คราฟได้: "<สูตร>__q<คุณภาพ 1-4>" เช่น "frog_vest__q2" = เสื้อหนังกบ (หายาก)

# คุณภาพ: id, ชื่อ, ตัวคูณค่าพลัง (mult), โอกาสสุ่ม (chance)
# color = สีบนพื้นมืด (ป้ายเด้งในฉาก), ui = สีตัวหนังสือบนหน้าต่างสีครีม
const QUALITIES := [
	{"id": 1, "name": "ธรรมดา", "color": Color(0.92, 0.92, 0.9), "ui": Color(0.3, 0.18, 0.08), "mult": 1.0, "chance": 0.62},
	{"id": 2, "name": "หายาก", "color": Color(0.4, 0.75, 1.0), "ui": Color(0.12, 0.42, 0.85), "mult": 1.35, "chance": 0.26},
	{"id": 3, "name": "สุดยอด", "color": Color(0.8, 0.5, 1.0), "ui": Color(0.55, 0.2, 0.8), "mult": 1.8, "chance": 0.10},
	{"id": 4, "name": "ตำนาน", "color": Color(1.0, 0.65, 0.2), "ui": Color(0.85, 0.45, 0.0), "mult": 2.5, "chance": 0.02},
]
const ZODIAC_QUALITY := {"id": 5, "name": "เซ็ทนักษัตร", "color": Color(1.0, 0.35, 0.4), "ui": Color(0.85, 0.12, 0.25)}

# สูตรของทั่วไป (ใช้ของดรอปจากมอนสเตอร์) — mats = {รหัสไอเทม: จำนวน}, cost = ค่าแรงช่าง (บาท)
const RECIPES := [
	{"id": "frog_dagger", "name": "มีดขากบ", "slot": "weapon", "icon": "wood_sword", "atk": 5.0,
		"mats": {"frog_leg": 4, "mushroom_cap": 1}, "cost": 30},
	{"id": "mush_hat", "name": "หมวกเห็ด", "slot": "head", "icon": "straw_hat", "hp": 30.0,
		"mats": {"mushroom_cap": 4}, "cost": 30},
	{"id": "frog_vest", "name": "เสื้อหนังกบ", "slot": "body", "icon": "pha_khao_ma", "hp": 45.0,
		"mats": {"frog_leg": 6}, "cost": 40},
	{"id": "frog_boots", "name": "รองเท้ากบกระโดด", "slot": "feet", "icon": "sandals", "speed": 0.08, "hp": 10.0,
		"mats": {"frog_leg": 3, "mushroom_cap": 2}, "cost": 30},
	{"id": "mist_charm", "name": "เครื่องรางหมอก", "slot": "charm", "icon": "amulet", "atk": 4.0, "hp": 20.0,
		"mats": {"mist_horn": 1, "mushroom_cap": 3}, "cost": 60},
	# หมู่บ้าน 2 (village = ตีได้ตั้งแต่ไปถึงหมู่บ้านนั้น)
	{"id": "horn_spear", "name": "หอกเขาด้วง", "slot": "weapon", "icon": "wood_sword", "atk": 12.0, "village": 2,
		"mats": {"beetle_horn": 5, "bamboo_core": 2}, "cost": 120},
	{"id": "beetle_helm", "name": "หมวกเกราะด้วง", "slot": "head", "icon": "straw_hat", "hp": 70.0, "village": 2,
		"mats": {"beetle_horn": 4}, "cost": 100},
	{"id": "bamboo_armor", "name": "เกราะไผ่ถัก", "slot": "body", "icon": "pha_khao_ma", "hp": 100.0, "village": 2,
		"mats": {"bamboo_core": 5}, "cost": 120},
	{"id": "wind_sandals", "name": "รองเท้าไผ่ลม", "slot": "feet", "icon": "sandals", "speed": 0.12, "hp": 20.0, "village": 2,
		"mats": {"bamboo_core": 3, "beetle_horn": 1}, "cost": 100},
	{"id": "moon_charm", "name": "เครื่องรางแสงจันทร์", "slot": "charm", "icon": "amulet", "atk": 9.0, "hp": 40.0, "village": 2,
		"mats": {"ghost_fur": 1, "bamboo_core": 3}, "cost": 200},
]

# ชิ้นส่วนนักษัตร: [รหัสส่วน, ช่องที่ใช้ทำ]
const PARTS := [["fang", "weapon"], ["head", "head"], ["hide", "body"], ["foot", "feet"], ["tail", "charm"]]

# ชุดเซ็ทนักษัตร: ชื่อชิ้นส่วน + ชื่อของที่ทำได้ + ค่าพลัง + ความสามารถเซ็ท (3 ชิ้น / 5 ชิ้น)
const SETS := {
	"rat": {
		"name": "เซ็ทชวด",
		"parts": {"fang": "เขี้ยวชวด", "head": "หัวชวด", "hide": "หนังชวด", "foot": "เท้าชวด", "tail": "หางชวด"},
		"gear": {
			"weapon": {"name": "กรงเล็บชวด", "atk": 10.0},
			"head": {"name": "ฮู้ดชวด", "hp": 40.0},
			"body": {"name": "เสื้อคลุมชวด", "hp": 60.0},
			"feet": {"name": "รองเท้าชวด", "speed": 0.12},
			"charm": {"name": "กระดิ่งหางชวด", "atk": 5.0, "hp": 30.0},
		},
		"bonus3": {"text": "วิ่งเร็วขึ้น 12%", "speed": 0.12},
		"bonus5": {"text": "หลบการโจมตี 20%  สกิลคูลดาวน์ลด 20%", "dodge": 0.2, "cd_mult": 0.8},
	},
	"ox": {
		"name": "เซ็ทฉลู",
		"parts": {"fang": "เขาฉลู", "head": "หัวฉลู", "hide": "หนังฉลู", "foot": "กีบฉลู", "tail": "หางฉลู"},
		"gear": {
			"weapon": {"name": "ขวานเขาฉลู", "atk": 14.0},
			"head": {"name": "หมวกเขาฉลู", "hp": 60.0},
			"body": {"name": "เกราะหนังฉลู", "hp": 90.0},
			"feet": {"name": "รองเท้ากีบฉลู", "hp": 30.0, "speed": 0.04},
			"charm": {"name": "ห่วงทองฉลู", "atk": 4.0, "hp": 50.0},
		},
		"bonus3": {"text": "เลือดสูงสุด +80", "hp": 80.0},
		"bonus5": {"text": "รับดาเมจลด 30%  ไม่กระเด็นเมื่อโดนตี", "dmg_taken": 0.7, "no_knock": 1.0},
	},
	"tiger": {
		"name": "เซ็ทขาล",
		"parts": {"fang": "เขี้ยวขาล", "head": "หัวขาล", "hide": "หนังขาล", "foot": "อุ้งเท้าขาล", "tail": "หางขาล"},
		"gear": {
			"weapon": {"name": "กรงเล็บขาล", "atk": 18.0},
			"head": {"name": "ฮู้ดขาล", "hp": 55.0},
			"body": {"name": "เสื้อลายขาล", "hp": 80.0, "atk": 3.0},
			"feet": {"name": "รองเท้าอุ้งเท้าขาล", "speed": 0.1},
			"charm": {"name": "จี้หางขาล", "atk": 8.0},
		},
		"bonus3": {"text": "พลังโจมตี +15%", "atk_mult": 0.15},
		"bonus5": {"text": "โอกาสคริติคอล 20% (ดาเมจ 2 เท่า)", "crit": 0.2},
	},
	"rabbit": {
		"name": "เซ็ทเถาะ",
		"parts": {"fang": "ฟันเถาะ", "head": "หัวเถาะ", "hide": "ขนเถาะ", "foot": "เท้าเถาะ", "tail": "หางเถาะ"},
		"gear": {
			"weapon": {"name": "ค้อนจันทร์เถาะ", "atk": 22.0},
			"head": {"name": "ฮู้ดหูเถาะ", "hp": 70.0},
			"body": {"name": "เสื้อขนเถาะ", "hp": 100.0, "speed": 0.04},
			"feet": {"name": "รองเท้าเท้าเถาะ", "speed": 0.1, "hp": 30.0},
			"charm": {"name": "ปอมปอมหางเถาะ", "atk": 10.0, "hp": 30.0},
		},
		"bonus3": {"text": "กระโดดสูงขึ้น 15%", "jump": 0.15},
		"bonus5": {"text": "ตีเร็วขึ้น 30%  หลบการโจมตี 10%", "atk_speed": 0.3, "dodge": 0.1},
	},
}
# ของเซ็ทนักษัตรตียาก (สมเป็นของเทพ): ค่าแรงแพง ใช้ของทั่วไปเยอะ และมีโอกาสตีพัง
# ตีพัง = เสียของทั่วไปกับเงิน แต่ชิ้นส่วนนักษัตรยังอยู่ และครั้งต่อไปโอกาสสำเร็จเพิ่มขึ้น
const SET_COST := 500
const SET_EXTRA := {
	"weapon": {"frog_leg": 15, "mist_horn": 3},
	"head": {"mushroom_cap": 15, "mist_horn": 2},
	"body": {"frog_leg": 20, "mushroom_cap": 10},
	"feet": {"frog_leg": 10, "mushroom_cap": 10, "mist_horn": 1},
	"charm": {"mushroom_cap": 10, "mist_horn": 5},
}
# เซ็ทของหมู่บ้าน 2 (ขาล เถาะ) ใช้ของจากป่าไผ่แทน
const SET_EXTRA_V2 := {
	"weapon": {"beetle_horn": 15, "ghost_fur": 3},
	"head": {"beetle_horn": 12, "bamboo_core": 6, "ghost_fur": 1},
	"body": {"bamboo_core": 18, "beetle_horn": 6},
	"feet": {"bamboo_core": 10, "beetle_horn": 8, "ghost_fur": 1},
	"charm": {"bamboo_core": 10, "ghost_fur": 4},
}
const SET_CHANCE := 0.3       # โอกาสตีสำเร็จครั้งแรก
const SET_CHANCE_STEP := 0.15  # ตีพังแต่ละครั้ง โอกาสครั้งต่อไปเพิ่มเท่านี้


## ของทั่วไปที่ต้องใช้เพิ่มตอนตีของเซ็ทนักษัตร (นักษัตรหมู่บ้าน 2 ขึ้นไปใช้ของจากป่าไผ่)
static func set_extra(zodiac: String, slot: String) -> Dictionary:
	var z := Zodiac.get_data(zodiac)
	return SET_EXTRA_V2[slot] if not z.is_empty() and Zodiac.village_of(z) >= 2 else SET_EXTRA[slot]


## โอกาสตีของเซ็ทชิ้นนี้สำเร็จ (fails = จำนวนครั้งที่ตีพังมาแล้ว)
static func set_chance(fails: int) -> float:
	return minf(SET_CHANCE + SET_CHANCE_STEP * fails, 1.0)


## สร้างข้อมูลไอเทมทั้งหมดของระบบคราฟ (Game เอาไปรวมกับ ITEMS ตอนเริ่มเกม)
static func generated_items() -> Dictionary:
	var out := {}
	for r in RECIPES:
		for q in QUALITIES:
			var info := {"name": r["name"], "desc": "", "icon": _icon("craft_" + r["id"], r["icon"]), "tab": "equip", "slot": r["slot"],
				"quality": q["id"], "buy": 0, "sell": int(round(float(r["cost"]) * 0.5 * float(q["mult"])))}
			for stat in ["atk", "hp", "speed"]:
				if r.has(stat):
					info[stat] = snappedf(float(r[stat]) * float(q["mult"]), 0.01 if stat == "speed" else 1.0)
			out["%s__q%d" % [r["id"], q["id"]]] = info
	for z in SETS:
		var s: Dictionary = SETS[z]
		for p in PARTS:
			out[part_id(z, p[0])] = {"name": s["parts"][p[0]], "desc": "", "icon": _icon("zpart_%s_%s" % [z, p[0]], "tiger_fang"), "tab": "etc",
				"quality": 5, "buy": 0, "sell": 0}
			var g: Dictionary = s["gear"][p[1]]
			var info := {"name": g["name"], "desc": "", "icon": _icon("zset_%s_%s" % [z, p[1]], FALLBACK_ICON[p[1]]), "tab": "equip", "slot": p[1],
				"quality": 5, "set": z, "buy": 0, "sell": 0}
			for stat in ["atk", "hp", "speed"]:
				if g.has(stat):
					info[stat] = g[stat]
			out[set_item_id(z, p[1])] = info
	return out


# ไอคอนสำรอง (ถ้ายังไม่มีภาพของชิ้นนั้น)
const FALLBACK_ICON := {"weapon": "wood_sword", "head": "straw_hat", "body": "pha_khao_ma", "feet": "sandals", "charm": "amulet"}


static func _icon(name: String, fallback: String) -> String:
	return name if ResourceLoader.exists("res://assets/art/items/item_%s.png" % name) else fallback


static func part_id(zodiac: String, part: String) -> String:
	return "zpart_%s_%s" % [zodiac, part]


static func set_item_id(zodiac: String, slot: String) -> String:
	return "zset_%s_%s" % [zodiac, slot]


## ข้อมูลคุณภาพตามรหัส (1-5)
static func quality(id: int) -> Dictionary:
	if id == 5:
		return ZODIAC_QUALITY
	for q in QUALITIES:
		if q["id"] == id:
			return q
	return QUALITIES[0]


## สุ่มคุณภาพตอนคราฟ
static func roll_quality() -> int:
	var r := randf()
	var acc := 0.0
	for q in QUALITIES:
		acc += float(q["chance"])
		if r < acc:
			return int(q["id"])
	return 1


## รายการสูตรที่แสดงที่ช่าง: ของทั่วไป + ของเซ็ทนักษัตรที่มีชิ้นส่วนอยู่
## คืนค่า [{key, name, slot, icon, mats, cost, zodiac}]
static func recipe_list(items: Dictionary) -> Array:
	var out: Array = []
	for r in RECIPES:
		if int(r.get("village", 1)) > Game.village:
			continue
		out.append({"key": r["id"], "name": r["name"], "slot": r["slot"], "icon": _icon("craft_" + r["id"], r["icon"]), "mats": r["mats"], "cost": int(r["cost"]), "zodiac": ""})
	for z in SETS:
		for p in PARTS:
			var pid := part_id(z, p[0])
			if int(items.get(pid, 0)) <= 0:
				continue
			var mats: Dictionary = {pid: 1}
			mats.merge(set_extra(z, p[1]))
			out.append({"key": set_item_id(z, p[1]), "name": SETS[z]["gear"][p[1]]["name"], "slot": p[1],
				"icon": _icon("zset_%s_%s" % [z, p[1]], FALLBACK_ICON[p[1]]), "mats": mats, "cost": SET_COST, "zodiac": z})
	return out
