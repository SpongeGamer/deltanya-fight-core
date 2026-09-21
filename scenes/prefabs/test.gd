extends Node2D

func _ready() -> void:
	Global.location_name = "Тест-подземка"
	Sounds.set_music("forest")
	# SceneTransition.scene_changed обрабатывает спавн автоматически — ручной вызов убран

	# Тестовые предметы — только если нет ни одного реального предмета
	# (is_empty учитывает null-слоты, поэтому проверяем наличие хоть одного Item)
	var has_any_item := false
	for item in Global.items:
		if item != null:
			has_any_item = true
			break
	if not has_any_item:
		var defaults : Array[Item] = [
			preload("res://holdables/items/dark_candy.tres"),
			preload("res://holdables/items/dark_candy.tres"),
			preload("res://holdables/items/heal_candy.tres"),
			preload("res://holdables/items/mystery_key.tres"),
		]
		Global.items.clear()
		for item in defaults:
			if item.usePredicate != null and item.usePredicate.item == null:
				item.usePredicate.item = item
			Global.add_item(item)
