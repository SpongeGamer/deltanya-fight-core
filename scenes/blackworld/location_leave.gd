extends CanvasLayer

@onready var dark_rect: ColorRect = $DarkRect

@export var fade_time: float = 1.0
@export var darken_time: float = 1.5

# TravelTrigger variables
@export_file("*.tscn") var target_scene: String = ""
@export var spawn_point: String = ""
@export var set_dark_world: bool = false

func _ready() -> void:
	dark_rect.modulate.a = 0

func start_fadeout() -> void:
	# Затемняем экран
	var t := create_tween()
	t.tween_property(dark_rect, "modulate:a", 1.0, fade_time)
	await t.finished
	
	# Дополнительная пауза если нужна
	await get_tree().create_timer(darken_time).timeout

func _travel() -> void:
	if target_scene == "":
		push_error("TravelTrigger: target_scene не задан!")
		return
	
	# Не трогаем Global.is_dark_world напрямую.
	# Передаём желаемое состояние в SceneTransition,
	# а там оно применится уже после fade_out.
	SceneTransition.travel(target_scene, spawn_point, set_dark_world)
