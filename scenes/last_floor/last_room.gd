extends Node2D
# DARK_SERYOGA_ROOM
# Слушает сигналы от грибов напрямую (без глобала).
# Когда все REQUIRED_MUSHROOMS зажжены — убирает невидимую стену.

@export var required_mushrooms : int  = 4

# Ссылка на StaticBody2D (или CollisionShape2D) невидимой стены
@export var wall               : NodePath

# Опционально: тайлмап + тайлы которые меняет сама комната
# когда ВСЕ грибы зажжены (например общий «разлив» света)
@export var tilemap            : NodePath
@export var reveal_tiles       : Array[Vector2i] = []
@export var reveal_source_id   : int        = 1
@export var reveal_atlas_coord : Vector2i   = Vector2i(2, 0)

var _lit_count := 0

func _ready() -> void:
	# Подписываемся на все грибы в комнате
	for mushroom in get_tree().get_nodes_in_group("mushrooms"):
		if mushroom.is_ancestor_of(self) or self.is_ancestor_of(mushroom):
			mushroom.activated.connect(_on_mushroom_activated)
	
	Sounds.set_music("waterfall",0.5)
	Global.location_name = "Грибной лес"

func _on_mushroom_activated(_id: int) -> void:
	_lit_count += 1
	if _lit_count >= required_mushrooms:
		_remove_wall()

func _remove_wall() -> void:
	var wall_node := get_node_or_null(wall)
	if wall_node:
		# Вариант А: убираем коллизию у StaticBody2D
		if wall_node is StaticBody2D:
			for child in wall_node.get_children():
				if child is CollisionShape2D:
					child.disabled = true
			wall_node.visible = false

		# Вариант Б: если передали прямо CollisionShape2D
		elif wall_node is CollisionShape2D:
			wall_node.disabled = true

	# Меняем тайлы «общего» открытия если указаны
	var tm := get_node_or_null(tilemap) as TileMap
	if tm:
		for cell in reveal_tiles:
			tm.set_cell(0, cell, reveal_source_id, reveal_atlas_coord)
