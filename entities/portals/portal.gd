class_name Portal extends Interactable
## ประตูวาร์ปไปแผนที่อื่น

var target_stage := ""
var target_spawn := ""
var lock_check := Callable()  # ถ้าคืนข้อความที่ไม่ว่าง = ยังเข้าไม่ได้ และจะแสดงข้อความนั้น
var tint := Color(0.5, 0.85, 1.0)
var _t := 0.0


func _ready() -> void:
	prompt = "กด ↑ เพื่อเข้า"
	label_height = 150.0
	super()


func _process(delta: float) -> void:
	super(delta)
	_t += delta
	queue_redraw()


func interact() -> void:
	if lock_check.is_valid():
		var msg: String = lock_check.call()
		if msg != "":
			Game.start_dialogue([{"who": "", "text": msg}])
			return
	Sound.play("portal")
	Game.main.change_stage(target_stage, target_spawn)


func _draw() -> void:
	var pulse := 0.5 + 0.5 * sin(_t * 3.0)
	var c := Vector2(0, -72)
	Art.ellipse(self, Vector2(0, 0), 46.0, 9.0, Color(tint.r, tint.g, tint.b, 0.35))
	for i in 5:
		var k := 1.0 - i * 0.17
		Art.ellipse(self, c, (44.0 + pulse * 4.0) * k, (74.0 + pulse * 5.0) * k, Color(tint.r, tint.g, tint.b, 0.16 + i * 0.05))
	Art.ellipse(self, c, 16.0, 30.0, Color(1, 1, 1, 0.55 + pulse * 0.25))
	# เกลียวแสงหมุน
	for j in 2:
		var pts := PackedVector2Array()
		for i in 14:
			var a := _t * 2.2 + j * PI + i * 0.32
			var r := 1.0 - i / 16.0
			pts.append(c + Vector2(cos(a) * 40.0 * r, sin(a) * 68.0 * r))
		draw_polyline(pts, Color(1, 1, 1, 0.7), 3.0, true)
	for i in 6:
		var a := _t * 1.4 + i * TAU / 6.0
		var pos := c + Vector2(cos(a) * 52.0, sin(a * 1.3) * 78.0)
		Art.circle(self, pos, 2.5 + sin(_t * 5.0 + i) * 1.0, Color(1, 1, 0.9, 0.85))
