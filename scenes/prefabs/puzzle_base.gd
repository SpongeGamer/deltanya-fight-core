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
	_remember_visual_base()

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
	_animate_tile(Color(1.2, 1.25, 1.4), true)
	
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

# Только декоративная реакция: состояние переключателя меняется сразу, как и раньше.
var _visual_tween: Tween
var _visual_base_scale: Vector2
var _visual_base_color: Color

class PuzzleSpark extends Node2D:
	var age: float = 0.0
	var tint: Color = Color.WHITE
	const LIFE: float = 0.48

	func _process(delta: float) -> void:
		age += delta
		if age >= LIFE:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var t := age / LIFE
		var c := tint
		c.a *= 1.0 - t
		var r := 11.0 + t * 5.0
		for i in range(4):
			var a := float(i) * PI * 0.5 + PI * 0.25
			var pos := Vector2(cos(a), sin(a)) * r
			draw_rect(Rect2(pos.round(), Vector2(2.0, 2.0)), c)

func _remember_visual_base() -> void:
	if display_sprite:
		_visual_base_scale = display_sprite.scale
		_visual_base_color = display_sprite.modulate

func _animate_tile(color: Color, squash: bool = false) -> void:
	if not is_instance_valid(display_sprite) or not is_inside_tree():
		return
	if _visual_tween and _visual_tween.is_valid():
		_visual_tween.kill()
	display_sprite.scale = _visual_base_scale
	display_sprite.modulate = color
	if squash:
		display_sprite.scale = _visual_base_scale * Vector2(1.12, 0.84)
	_visual_tween = create_tween().set_parallel(true)
	_visual_tween.tween_property(display_sprite, "scale", _visual_base_scale, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_visual_tween.tween_property(display_sprite, "modulate", _visual_base_color, 0.32)
	var sparks := PuzzleSpark.new()
	sparks.tint = color
	sparks.position = display_sprite.position
	sparks.z_index = display_sprite.z_index + 1
	add_child(sparks)

func puzzle_visual_feedback(success: bool) -> void:
	_animate_tile(Color(1.3, 1.4, 1.2) if success else Color(1.35, 0.65, 0.7), true)
