extends Area2D

signal activated(mushroom_id: int)

@export var mushroom_id : int = 0
@export var tilemap : NodePath
@export var grass_tiles : Array[Vector2i] = []
@export var lit_grass_source_id   : int      = 0
@export var lit_grass_atlas_coord : Vector2i = Vector2i(1, 0)
@export var wall : Array[NodePath] = []

var _lit           := false
var _player_inside := false
var _glow_time := 0.0
var _activation_glow := 0.0

func _ready() -> void:
	_lit = Global.get_flag(_flag_key())
	if _lit:
		_apply_lit_state()
	else:
		$AnimatedSprite2D.play("unlit")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	_glow_time += delta
	_activation_glow = maxf(0.0, _activation_glow - delta * 0.55)
	queue_redraw()

func _draw() -> void:
	# Небольшие частицы и свет не меняют коллизии или поведение загадки.
	var phase := _glow_time + mushroom_id * 1.7
	var brightness := 0.018 if not _lit else 0.045 + _activation_glow * 0.035
	var center := Vector2(0, 1)
	for radius in [20.0, 14.0, 8.0]:
		draw_circle(center, radius, Color(0.45, 0.83, 0.84, brightness))
	if _lit:
		for i in 3:
			var p := phase * (0.55 + float(i) * 0.08) + float(i) * 2.1
			var pos := (center + Vector2(sin(p) * (10.0 + float(i) * 3.0), cos(p * 0.8) * 7.0 - 6.0)).round()
			var alpha: float = 0.48 + 0.35 * (sin(p * 1.8) + 1.0) * 0.5
			draw_rect(Rect2(pos, Vector2(2, 2)), Color(0.7, 1.0, 0.92, alpha))

func _unhandled_input(event: InputEvent) -> void:
	if _player_inside and event.is_action_pressed("interact"):
		interact()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_inside = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_inside = false

func _flag_key() -> String:
	return "mushroom_forest_lit_%d" % mushroom_id

func interact() -> void:
	if _lit:
		return
	_lit = true
	Global.set_flag(_flag_key())
	_activation_glow = 1.0
	Sounds.play("snd_shroom")
	_apply_lit_state()
	activated.emit(mushroom_id)

# Используется и при нажатии, и при загрузке сохранения.
func _apply_lit_state() -> void:
	$AnimatedSprite2D.play("lit")
	var tm := get_node_or_null(tilemap) as TileMapLayer
	if tm:
		for cell in grass_tiles:
			tm.set_cell(cell, lit_grass_source_id, lit_grass_atlas_coord)
	else:
		push_warning("Mushroom: tilemap not found or wrong type — " + str(tilemap))
	_remove_walls()

func _remove_walls() -> void:
	for path in wall:
		var wall_node := get_node_or_null(path)
		if not wall_node:
			push_warning("Mushroom: wall not found — " + str(path))
			continue
		if wall_node is StaticBody2D:
			for child in wall_node.get_children():
				if child is CollisionShape2D:
					child.disabled = true
			wall_node.visible = false
		elif wall_node is CollisionShape2D:
			wall_node.disabled = true
