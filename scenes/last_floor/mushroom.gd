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

func _ready() -> void:
	$AnimatedSprite2D.play("unlit")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _unhandled_input(event: InputEvent) -> void:
	if _player_inside and event.is_action_pressed("interact"):
		interact()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_inside = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_inside = false

func interact() -> void:
	if _lit:
		return
	_lit = true
	Sounds.play("snd_shroom")
	$AnimatedSprite2D.play("lit")

	var tm := get_node_or_null(tilemap) as TileMapLayer
	if tm:
		for cell in grass_tiles:
			tm.set_cell(cell, lit_grass_source_id, lit_grass_atlas_coord)
	else:
		push_warning("Mushroom: tilemap not found or wrong type — " + str(tilemap))

	_remove_walls()
	activated.emit(mushroom_id)

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
