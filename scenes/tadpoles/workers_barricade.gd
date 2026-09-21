extends Node2D
# Нода-контейнер для работяг, их диалоговых зон и стен-баррикад.
# Структура под этой нодой:
#   WorkersBarricade
#     ├── Worker1 (NPC)
#     │     └── DialogueArea2D  ← Area2D с диалогом
#     ├── Worker2 (NPC)
#     │     └── DialogueArea2D
#     ├── Wall1 (StaticBody2D)
#     └── Wall2 (StaticBody2D)

func enable() -> void:
	visible = true
	_set_walls(false)      # false = коллизии включены
	_set_areas(true)       # true  = зоны мониторят


func disable() -> void:
	visible = false
	_set_walls(true)       # disabled = коллизии выключены
	_set_areas(false)


# ── стены ─────────────────────────────────────────────────────────────────────
func _set_walls(p_disabled: bool) -> void:
	for child in _get_all_children(self):
		if child is CollisionShape2D or child is CollisionPolygon2D:
			# Только дети StaticBody2D — стены
			if child.get_parent() is StaticBody2D:
				child.set_deferred("disabled", p_disabled)


# ── диалоговые зоны ───────────────────────────────────────────────────────────
func _set_areas(p_monitoring: bool) -> void:
	for child in _get_all_children(self):
		if child is Area2D:
			child.set_deferred("monitoring",   p_monitoring)
			child.set_deferred("monitorable",  p_monitoring)
			var col: CollisionShape2D = child.get_node_or_null("CollisionShape2D")
			if col:
				col.set_deferred("disabled", not p_monitoring)


# ── рекурсивно все потомки ────────────────────────────────────────────────────
func _get_all_children(node: Node) -> Array:
	var result: Array = []
	for child in node.get_children():
		result.append(child)
		result.append_array(_get_all_children(child))
	return result
