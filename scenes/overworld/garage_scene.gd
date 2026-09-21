extends Node2D

func _ready() -> void:
	Global.location_name = "Гараж"
	Sounds.set_music("garage")
	# SceneTransition.scene_changed обрабатывает спавн автоматически — ручной вызов убран
