extends Node

signal transition_finished

@export var duration: float = 2.5
@export var bubble_count: int = 200
@export var bubble_speed: float = 60.0

var _particles: GPUParticles2D
var _bubble_texture: Texture2D
var _canvas_layer: CanvasLayer

func _ready() -> void:
	_bubble_texture = load("res://assets/VFX/Bubble.png")

func _start_transition() -> void:
	_canvas_layer = CanvasLayer.new()
	_canvas_layer.layer = 9
	add_child(_canvas_layer)
	
	# Затемнение (сразу, но прозрачное)
	var fade_rect := ColorRect.new()
	fade_rect.color = Color.BLACK
	fade_rect.anchor_right = 1.0
	fade_rect.anchor_bottom = 1.0
	fade_rect.modulate = Color(1, 1, 1, 0)
	_canvas_layer.add_child(fade_rect)
	
	# Создаём несколько эмиттеров для полного покрытия
	for i in range(3):
		_create_bubble_emitter(i * 0.33, duration)
	
	# Ждём пока пузыри заполнят экран
	await get_tree().create_timer(duration * 0.8).timeout
	
	# Затемняем экран
	var fade_tween := create_tween()
	fade_tween.tween_property(fade_rect, "modulate:a", 1.0, duration * 0.2)
	await fade_tween.finished
	
	transition_finished.emit()
	
	# Держим затемнение
	await get_tree().create_timer(0.3).timeout
	
	queue_free()

func _create_bubble_emitter(offset_x: float, total_duration: float) -> void:
	var particles := GPUParticles2D.new()
	particles.visible = true
	particles.z_index = 10
	particles.texture = _bubble_texture
	
	# Увеличиваем количество для каждого эмиттера
	particles.amount = bubble_count / 3
	particles.lifetime = 15.0  # Достаточно долго чтобы достичь верха
	particles.one_shot = true
	particles.explosiveness = 0.0
	particles.randomness = 0.5
	
	# Настраиваем материал
	var material := ParticleProcessMaterial.new()
	
	# Направление строго вверх с небольшим разбросом для естественности
	material.direction = Vector3(0, -1, 0)
	material.spread = 10.0  # Небольшой разброс чтобы пузыри перекрывались
	
	# Скорость достаточная чтобы достичь верха за время жизни
	var screen_height = 480
	var needed_speed = screen_height / particles.lifetime
	material.initial_velocity_min = needed_speed * 0.9
	material.initial_velocity_max = needed_speed * 1.1
	material.gravity = Vector3(0, 0, 0)
	
	# УВЕЛИЧИВАЕМ РАЗМЕР
	material.scale_min = 1.0
	material.scale_max = 4.0
	
	# Цвет с прозрачностью	
	material.color = Color(1, 1, 1, 0.9)
	
	# Эмиссия по всей ширине экрана
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	material.emission_box_extents = Vector3(320, 20, 0)  # Вся ширина + небольшая высота
	
	particles.process_material = material
	
	# Позиция внизу с небольшим смещением по X для перекрытия
	particles.position = Vector2(320 + (offset_x - 0.33) * 100, 480)
	
	_canvas_layer.add_child(particles)
	particles.emitting = true
	
