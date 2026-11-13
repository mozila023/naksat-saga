class_name Portal extends Interactable
## ประตูวาร์ปไปแผนที่อื่น

var target_stage := ""
var target_spawn := ""
var lock_check := Callable()  # ถ้าคืนข้อความที่ไม่ว่าง = ยังเข้าไม่ได้ และจะแสดงข้อความนั้น
var tint := Color(0.5, 0.85, 1.0)
var _t := 0.0


func _ready() -> void:
	prompt = "กด W / ↑ เพื่อเข้า"
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
	Game.main.change_stage(target_stage, target_spawn)


func _draw() -> void:
	var pulse := 0.5 + 0.5 * sin(_t * 3.0)
	for i in 4:
		var r := 34.0 + i * 9.0 + pulse * 4.0
		draw_set_transform(Vector2(0, -70), 0.0, Vector2(1.0, 1.6))
		draw_arc(Vector2.ZERO, r * 0.6, 0, TAU, 32, Color(tint.r, tint.g, tint.b, 0.55 - i * 0.12), 6.0)
	draw_set_transform(Vector2(0, -70), 0.0, Vector2(1.0, 1.6))
	draw_circle(Vector2.ZERO, 20.0, Color(1, 1, 1, 0.35 + pulse * 0.25))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for i in 5:
		var a := _t * 1.5 + i * TAU / 5.0
		draw_circle(Vector2(cos(a) * 34.0, -70 + sin(a) * 60.0), 3.0, Color(1, 1, 1, 0.8))
