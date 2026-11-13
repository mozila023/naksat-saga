class_name ZodiacSpirit extends Interactable
## วิญญาณนักษัตรที่ปรากฏบนหิ้งบูชาในบ้านผู้ใหญ่บ้าน เมื่อเลเวลถึง — กด ↑ เพื่อคุยและเริ่มประลอง

var zodiac := {}
var _sprite: Sprite2D
var _t := 0.0


func _ready() -> void:
	title = Zodiac.display_name(zodiac)
	prompt = "กด ↑ เพื่อประลอง"
	label_height = 210.0
	reach = 110.0
	super()
	var path := "res://assets/art/frames/%s_walk_3.png" % zodiac["boss"]["frames"]
	_sprite = Sprite2D.new()
	_sprite.texture = load(path)
	_sprite.centered = false
	_sprite.offset = Vector2(-_sprite.texture.get_width() * 0.5, -_sprite.texture.get_height())
	_sprite.scale = Vector2(0.62, 0.62)
	add_child(_sprite)
	move_child(_sprite, 0)


func _process(delta: float) -> void:
	super(delta)
	_t += delta
	# ลอยขึ้นลงช้า ๆ หันหน้าหาผู้เล่น (ภาพต้นฉบับหันซ้าย)
	_sprite.position = Vector2(0, -70.0 + sin(_t * 2.0) * 10.0)
	var p := Game.player
	if p:
		_sprite.flip_h = p.global_position.x > global_position.x
	_sprite.modulate = Color(1.15, 1.15, 1.25, 0.85 + sin(_t * 3.0) * 0.1)
	queue_redraw()


func interact() -> void:
	var lines: Array = []
	for text in zodiac["intro"]:
		lines.append({"who": zodiac["year"], "text": text})
	Game.start_dialogue(lines, func() -> void: Game.start_trial(zodiac["id"]))


func _draw() -> void:
	var col: Color = zodiac.get("color", Color(1, 0.9, 0.5))
	var c := Vector2(0, -110.0 + sin(_t * 2.0) * 10.0)
	Art.glow(self, c, 120.0, Color(col.r, col.g, col.b, 0.55))
	Art.ellipse(self, Vector2(0, 2), 70.0, 12.0, Color(col.r, col.g, col.b, 0.35))
	for i in 6:
		var a := _t * 1.2 + i * TAU / 6.0
		Art.circle(self, c + Vector2(cos(a) * 90.0, sin(a) * 40.0), 3.0 + sin(_t * 4.0 + i) * 1.2, Color(1, 1, 0.9, 0.85))
