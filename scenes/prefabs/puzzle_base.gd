extends Area2D

## Настройки
@export var switch_id: String = "switch_1"
@export var state_images: Array[Texture2D] = []  # Картинки для переключения
@export var display_sprite: Sprite2D = null
@export var change_sound: String = ""

var current_state: int = 0
var _player_in: bool = false

signal state_changed(switch_id: String, new_state: int)

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_update_display()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in = false

func _input(event: InputEvent) -> void:
	if _player_in and event.is_action_pressed("interact"):
		_next_state()

func _next_state() -> void:
	current_state = (current_state + 1) % state_images.size()
	_update_display()
	
	if change_sound:
		Sounds.play(change_sound)
	
	state_changed.emit(switch_id, current_state)

func _update_display() -> void:
	if display_sprite and current_state < state_images.size():
		display_sprite.texture = state_images[current_state]

## Публичный метод для сброса
func reset_state() -> void:
	current_state = 0
	_update_display()

## Получить текущее состояние
func get_state() -> int:
	return current_state
