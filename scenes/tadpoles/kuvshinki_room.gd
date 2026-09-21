extends Node

signal all_placed

@export var required_count  : int            = 3
@export var water_spawn     : NodePath       # Marker2D — точка появления в воде
@export var slot_markers    : Array[NodePath] = []  # Marker2D-ы — точки назначения по порядку
@export var wall            : NodePath
@export var open_sound      : String         = "snd_secret"

var _placed_count : int = 0
var _next_slot    : int = 0


func _ready() -> void:
	for k in get_tree().get_nodes_in_group("kuvshinki"):
		if is_ancestor_of(k):
			k.placed.connect(_on_kuvshinka_placed)


func get_water_spawn() -> Vector2:
	var marker := get_node_or_null(water_spawn) as Node2D
	if marker:
		return marker.global_position
	push_warning("kuvshinki_room: water_spawn не задан, используется Vector2.ZERO")
	return Vector2.ZERO


func request_slot() -> Vector2:
	if _next_slot < slot_markers.size():
		var marker := get_node_or_null(slot_markers[_next_slot]) as Node2D
		_next_slot += 1
		if marker:
			return marker.global_position
		push_warning("kuvshinki_room: slot_marker[%d] не найден" % (_next_slot - 1))
		return Vector2.ZERO
	push_warning("kuvshinki_room: кончились слоты, проверь slot_markers")
	return Vector2.ZERO


func _on_kuvshinka_placed(_id: int) -> void:
	_placed_count += 1
	if _placed_count >= required_count:
		_bloom_all()
		await get_tree().create_timer(0.6).timeout
		_open_wall()


func _bloom_all() -> void:
	for k in get_tree().get_nodes_in_group("kuvshinki"):
		if is_ancestor_of(k):
			k.bloom()


func _open_wall() -> void:
	Sounds.play(open_sound)
	var wall_node := get_node_or_null(wall)
	if not wall_node:
		push_warning("kuvshinki_room: wall не найдена — " + str(wall))
		return
	if wall_node is StaticBody2D:
		for child in wall_node.get_children():
			if child is CollisionShape2D:
				child.disabled = true
		wall_node.visible = false
	elif wall_node is CollisionShape2D:
		wall_node.disabled = true
