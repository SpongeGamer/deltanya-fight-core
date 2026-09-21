extends CanvasLayer

@onready var effect_rect := ColorRect.new()
var invert_shader: ShaderMaterial
var zoom_shader: ShaderMaterial

func _ready() -> void:
	# Настройка эффектов
	effect_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	effect_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	effect_rect.z_index = 200
	add_child(effect_rect)
	
	invert_shader = ShaderMaterial.new()
	invert_shader.shader = preload("res://shaders/invert.gdshader")
	
	zoom_shader = ShaderMaterial.new()
	zoom_shader.shader = preload("res://shaders/zoom_vignette.gdshader")

func apply_glitch_and_fade(duration: float = 2.0) -> void:
	# Фаза 1: глитч + инверсия (0.3 сек)
	effect_rect.material = invert_shader
	effect_rect.modulate.a = 1.0
	
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_method(_update_glitch, 0.0, 0.3, 0.3)
	tween.tween_method(_update_invert, 0.0, 0.5, 0.3)
	await tween.finished
	
	# Фаза 2: зум + виньетка (0.5 сек)
	effect_rect.material = zoom_shader
	var tween2 := create_tween()
	tween2.set_parallel(true)
	tween2.tween_method(_update_zoom, 1.0, 2.5, 0.5)
	tween2.tween_method(_update_vignette, 0.0, 1.5, 0.5)
	tween2.tween_method(_update_darkness, 0.0, 0.8, 0.5)
	await tween2.finished
	
	# Фаза 3: полная чернота
	effect_rect.material = null
	effect_rect.color = Color.BLACK

func _update_glitch(value: float) -> void:
	invert_shader.set_shader_parameter("glitch", value)

func _update_invert(value: float) -> void:
	invert_shader.set_shader_parameter("strength", value)

func _update_zoom(value: float) -> void:
	zoom_shader.set_shader_parameter("zoom", value)

func _update_vignette(value: float) -> void:
	zoom_shader.set_shader_parameter("vignette", value)

func _update_darkness(value: float) -> void:
	zoom_shader.set_shader_parameter("darkness", value)
