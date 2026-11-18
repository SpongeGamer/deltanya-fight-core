extends CanvasLayer

const SHADER = preload("res://scenes/blackworld/mk_spotlight.gdshader")
var material_instance: ShaderMaterial
var _focus: Node2D

func _ready() -> void:
	layer = 5
	process_mode = Node.PROCESS_MODE_ALWAYS
	var rect := ColorRect.new()
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rect)
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	material_instance = ShaderMaterial.new()
	material_instance.shader = SHADER
	material_instance.set_shader_parameter("radius", 0.8)
	material_instance.set_shader_parameter("softness", 0.16)
	material_instance.set_shader_parameter("darkness", 0.0)
	rect.material = material_instance

func _process(_delta: float) -> void:
	if not is_instance_valid(_focus):
		_focus = get_tree().get_first_node_in_group("player") as Node2D
	if not is_instance_valid(_focus) or material_instance == null:
		return
	var viewport := get_viewport()
	var viewport_size := viewport.get_visible_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	var screen_pos: Vector2 = viewport.get_canvas_transform() * _focus.global_position
	material_instance.set_shader_parameter("center", screen_pos / viewport_size)
	material_instance.set_shader_parameter("aspect", viewport_size.x / viewport_size.y)

func tween_light(radius: float, softness: float, darkness: float, duration: float) -> Tween:
	var tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	for pair in [["radius", radius], ["softness", softness], ["darkness", darkness]]:
		var parameter: String = pair[0]
		var target: float = pair[1]
		var current: float = float(material_instance.get_shader_parameter(parameter))
		tween.tween_method(func(value: float): material_instance.set_shader_parameter(parameter, value), current, target, duration)
	return tween

# Оверлей живет в корне дерева, переживает смену сцены и затем раскрывает свет в лесу.
func reveal_after_transition() -> void:
	_focus = null
	await get_tree().process_frame
	material_instance.set_shader_parameter("radius", 0.22)
	material_instance.set_shader_parameter("softness", 0.10)
	var reveal := tween_light(1.6, 0.3, 0.0, 2.5)
	await reveal.finished
	queue_free()
