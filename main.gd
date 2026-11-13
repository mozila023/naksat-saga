extends Node
## จุดเริ่มของเกม: สร้างผู้เล่น + HUD และสลับแผนที่

const STAGES := {
	"village": preload("res://stages/village.gd"),
	"rice_field": preload("res://stages/rice_field.gd"),
	"tiger_cave": preload("res://stages/tiger_cave.gd"),
	"chief_house": preload("res://stages/chief_house.gd"),
	"trial_hall": preload("res://stages/trial_hall.gd"),
}

var world: Node2D
var stage: Stage
var stage_id := ""
var player: Player
var hud: Hud
var _fade: ColorRect
var _changing := false
var title: TitleScreen
var creator: CharacterCreate
var story: StoryCutscene


func _ready() -> void:
	Game.main = self
	world = Node2D.new()
	world.name = "World"
	add_child(world)

	player = Player.new()
	player.name = "Player"
	world.add_child(player)

	hud = Hud.new()
	add_child(hud)

	var fade_layer := CanvasLayer.new()
	fade_layer.layer = 50
	add_child(fade_layer)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 1)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_layer.add_child(_fade)

	_load_stage("village", "start")
	create_tween().tween_property(_fade, "color:a", 0.0, 0.4)

	# หน้าปกเกม: ซ่อน HUD และล็อกตัวละครไว้จนกว่าจะคลิกเริ่ม
	Game.in_title = true
	hud.visible = false
	player.visible = false
	title = TitleScreen.new()
	title.started.connect(_on_title_started)
	add_child(title)


func _on_title_started() -> void:
	if Game.has_profile():
		_begin_play()
		return
	# ยังไม่มีตัวละคร: เลือกเพศ -> ตั้งชื่อ -> ฉากเล่าเรื่อง
	creator = CharacterCreate.new()
	creator.finished.connect(_on_character_created)
	add_child(creator)


func _on_character_created(new_gender: String, new_name: String) -> void:
	Game.set_profile(new_gender, new_name)
	story = StoryCutscene.new()
	story.gender = Game.gender
	story.player_name = Game.player_name
	story.finished.connect(_begin_play)
	add_child(story)


func _begin_play() -> void:
	Game.in_title = false
	hud.visible = true
	player.visible = true
	Game.banner.emit(stage.title)


## ข้ามหน้าปก (ใช้ในการทดสอบอัตโนมัติ)
func start_game() -> void:
	if not Game.has_profile():
		Game.set_profile("boy", "ทดสอบ")
	if title and is_instance_valid(title):
		title.begin()


func change_stage(id: String, spawn: String) -> void:
	if _changing or not STAGES.has(id):
		return
	_changing = true
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, 0.25)
	tw.tween_callback(_load_stage.bind(id, spawn))
	tw.tween_property(_fade, "color:a", 0.0, 0.3)
	tw.tween_callback(func() -> void: _changing = false)


func _load_stage(id: String, spawn: String) -> void:
	if stage:
		world.remove_child(stage)
		stage.queue_free()
	Game.boss = null
	stage_id = id
	stage = STAGES[id].new()
	stage.name = "Stage"
	world.add_child(stage)
	world.move_child(stage, 0)
	player.global_position = stage.spawns.get(spawn, Vector2(200, Stage.GROUND_Y))
	player.velocity = Vector2.ZERO
	player.set_camera_limits(stage.width)
	Game.banner.emit(stage.title)
	Sound.play_bgm("village" if id == "chief_house" else id)


func on_player_died() -> void:
	Game.banner.emit("หมดแรง... กลับไปพักที่หมู่บ้าน")
	Game.active_trial = ""  # แพ้การประลอง: กลับไปคุยกับนักษัตรใหม่ได้
	await get_tree().create_timer(1.6).timeout
	_changing = false
	change_stage("village", "start")
	await get_tree().create_timer(0.3).timeout
	player.revive()


func restart_game() -> void:
	# ลบเซฟแล้วเริ่มใหม่ตั้งแต่หน้าปก (สร้างตัวละครใหม่)
	Game.reset_save()
	Game.player = null
	Game.boss = null
	Game.in_dialogue = false
	get_tree().reload_current_scene()
