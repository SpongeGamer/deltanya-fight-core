extends Node2D

# Общая рампа представления. Указатели и искры не наносят урон.
var variation: int = 0
var soul: Soul
var cage: Node2D
var clip: Control
var field: Node2D
var stage_time := 0.0

func _ready() -> void:
	soul = get_tree().get_first_node_in_group("soul") as Soul
	var node := get_parent()
	while node:
		cage = node.get_node_or_null("SoulCage") as Node2D
		if cage:
			break
		node = node.get_parent()
	clip = Control.new()
	clip.clip_contents = true
	clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(clip)
	field = Node2D.new()
	clip.add_child(field)
	_update_clip()
	var timer := get_tree().create_timer(get_duration() - 0.6)
	timer.timeout.connect(_finish_visuals)

func get_duration() -> float:
	return 12.0

func _process(delta: float) -> void:
	stage_time += delta
	_update_clip()
	queue_redraw()

func box_rect() -> Rect2:
	if is_instance_valid(cage):
		var panel := cage.get_node_or_null("Panel") as Control
		if panel:
			return Rect2(to_local(cage.to_global(panel.position)), panel.size).grow(-4.0)
	return Rect2(Vector2(-71, -71), Vector2(142, 142))

func _update_clip() -> void:
	if not is_instance_valid(clip):
		return
	var r := box_rect()
	clip.position = r.position
	clip.size = r.size
	field.position = -r.position

func _draw() -> void:
	var r := box_rect()
	# Маленькие акценты по углам, без сеток и стенок поверх игры.
	var c := Color(0.95, 0.70, 0.30, 0.23 + 0.07 * sin(stage_time * 2.0))
	for side in [-1.0, 1.0]:
		var x: float = r.position.x if side < 0 else r.end.x - 1.0
		draw_rect(Rect2(x, r.position.y + 3, 1, 8), c)
		draw_rect(Rect2(x, r.end.y - 11, 1, 8), c)

func pause_for(seconds: float) -> Signal:
	var timer := Timer.new()
	timer.one_shot = true
	add_child(timer)
	timer.timeout.connect(timer.queue_free)
	timer.start(seconds)
	return timer.timeout

func warn(at: Vector2, duration := 0.65) -> void:
	var mark := Warning.new()
	mark.position = at
	mark.duration = duration
	field.add_child(mark)

func _finish_visuals() -> void:
	if not is_inside_tree():
		return
	for child in field.get_children():
		if child is Pellet:
			child.set_deferred("monitoring", false)
			child.set_deferred("monitorable", false)
	create_tween().tween_property(self, "modulate:a", 0.0, 0.55)

class Warning extends Node2D:
	var duration := 0.65
	var time := 0.0
	func _process(delta: float) -> void:
		time += delta
		if time >= duration:
			queue_free()
		else:
			queue_redraw()
	func _draw() -> void:
		var alpha: float = 0.35 + 0.4 * absf(sin(time * 9.0))
		var c := Color(1.0, 0.78, 0.38, alpha)
		draw_line(Vector2(-7, 0), Vector2(-3, 0), c, 1.0)
		draw_line(Vector2(3, 0), Vector2(7, 0), c, 1.0)
		draw_line(Vector2(0, -7), Vector2(0, -3), c, 1.0)
		draw_line(Vector2(0, 3), Vector2(0, 7), c, 1.0)
