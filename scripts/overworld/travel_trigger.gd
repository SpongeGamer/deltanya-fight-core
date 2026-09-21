extends Area2D
# TravelTrigger — Area2D, которая переносит игрока в другую сцену.
# Поставь в сцене, назначь target_scene и spawn_point.
# spawn_point — имя Node2D в целевой сцене, где появится игрок.

@export_file("*.tscn") var target_scene: String = ""
@export var spawn_point: String = ""
@export var require_interact: bool = false
@export var set_dark_world: bool = false

var _player_inside := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	_player_inside = true
	if not require_interact:
		_travel()


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_inside = false


func _unhandled_key_input(event: InputEvent) -> void:
	if require_interact and _player_inside:
		if event.is_action_pressed("interact"):
			_travel()


func _travel() -> void:
	if target_scene == "":
		push_error("TravelTrigger: target_scene не задан!")
		return

	# Не трогаем Global.is_dark_world напрямую.
	# Передаём желаемое состояние в SceneTransition,
	# а там оно применится уже после fade_out.
	SceneTransition.travel(target_scene, spawn_point, set_dark_world)
