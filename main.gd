extends Node
## จุดเริ่มของเกม: สร้างผู้เล่น + HUD และสลับแผนที่

const STAGES := {
	"village": preload("res://stages/village.gd"),
	"rice_field": preload("res://stages/rice_field.gd"),
	"tiger_cave": preload("res://stages/tiger_cave.gd"),
}

var world: Node2D
var stage: Stage
var stage_id := ""
var player: Player
var hud: Hud
var _fade: ColorRect
var _changing := false


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
	Sound.play_bgm(id)


func on_player_died() -> void:
	Game.banner.emit("หมดแรง... กลับไปพักที่หมู่บ้าน")
	await get_tree().create_timer(1.6).timeout
	_changing = false
	change_stage("village", "start")
	await get_tree().create_timer(0.3).timeout
	player.revive()


func restart_game() -> void:
	Game.reset_save()
	player.revive()
	_changing = false
	change_stage("village", "start")
