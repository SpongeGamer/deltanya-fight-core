extends Node2D
## Decorative only. Train positions and lights are edited in the scene tree.

var _time := 0.0
var _bugs: Array[Dictionary] = []
var _trains: Array[Dictionary] = []
var _bushes: Array[Dictionary] = []

func _ready() -> void:
	z_index = -4088
	z_as_relative = false
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var bg := get_parent().get_node_or_null("KurganBG")
	if bg:
		var bush_index := 0
		for node in bg.get_children():
			if node is Sprite2D and String(node.name).begins_with("Bush"):
				var bush := node as Sprite2D
				_bushes.append({"sprite": bush, "scale": bush.scale, "phase": bush_index * 1.9})
				if bush_index % 2 == 0:
					_add_bugs(bush.position + Vector2(0, -14), 2, bush_index * 2.3)
				bush_index += 1

	# Use the artist's saved positions, rotations and scales as the animation base.
	var trains := get_parent().get_node_or_null("Atmosphere/Trains")
	if trains:
		for node in trains.get_children():
			if node is Sprite2D:
				var train := node as Sprite2D
				_trains.append({"sprite": train, "origin": train.position, "angle": train.rotation, "phase": _trains.size() * 1.8})

func _add_bugs(origin: Vector2, amount: int, phase: float) -> void:
	for i in amount:
		_bugs.append({"origin": origin, "phase": phase + i * 2.1, "radius": 8.0 + i * 4.0})

func _process(delta: float) -> void:
	_time += delta
	for item in _trains:
		var train: Sprite2D = item["sprite"]
		if not is_instance_valid(train):
			continue
		var phase: float = item["phase"]
		var origin: Vector2 = item["origin"]
		train.position = (origin + Vector2(sin(_time * 0.24 + phase) * 2.0, sin(_time * 0.32 + phase) * 1.5)).round()
		train.rotation = float(item["angle"]) + sin(_time * 0.18 + phase) * 0.012
	for item in _bushes:
		var bush: Sprite2D = item["sprite"]
		if not is_instance_valid(bush):
			continue
		var base: Vector2 = item["scale"]
		var sway := sin(_time * 1.05 + float(item["phase"])) * 0.015
		bush.scale = base * Vector2(1.0 + sway, 1.0 - sway * 0.45)
	queue_redraw()

func _draw() -> void:
	for item in _bugs:
		var phase := float(item["phase"])
		var origin: Vector2 = item["origin"]
		var radius := float(item["radius"])
		var pos := (origin + Vector2(sin(_time * 0.65 + phase) * radius, cos(_time * 0.87 + phase * 1.3) * radius * 0.65)).round()
		var blink := clampf((sin(_time * 2.0 + phase) + 0.6) * 0.55, 0.05, 0.8)
		draw_rect(Rect2(pos, Vector2(2, 2)), Color(0.72, 0.88, 0.52, blink * 0.8))
