extends Node2D

signal fall_finished

@onready var characters_container: Node2D = $Characters

@export var fall_duration: float = 4.0   # длительность звука snd_fall
@export var delay_after_impact: float = 4.0

var characters: Array[AnimatedSprite2D] = []

func _ready() -> void:
	for child in characters_container.get_children():
		if child is AnimatedSprite2D:
			characters.append(child)

func start_fall() -> void:
	# Запускаем анимации персонажей
	for character in characters:
		if character.sprite_frames.has_animation("fall"):
			character.play("fall")
		elif character.sprite_frames.has_animation("idle"):
			character.play("idle")

	# Звук падения — играет ~4 сек
	Sounds.play("snd_fall")

	# Уменьшаем персонажей до нуля за время падения
	for character in characters:
		_fall_animation(character)

	# Ждём конца падения
	await get_tree().create_timer(fall_duration).timeout

	# Удар о землю
	Sounds.play("snd_impact")

	# Ждём ещё перед «пробуждением»
	await get_tree().create_timer(delay_after_impact).timeout

	fall_finished.emit()

func _fall_animation(character: AnimatedSprite2D) -> void:
	var original_scale := character.scale
	var tween := create_tween().set_parallel(true)
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(character, "scale", Vector2.ZERO, fall_duration)
	tween.tween_property(character, "position:y", character.position.y + 80.0, fall_duration)
	tween.tween_property(character, "modulate:a", 0.0, fall_duration * 0.8)
