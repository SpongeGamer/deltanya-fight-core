extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Global.is_dark_world = true
	Sounds.set_music("field", 0.3)
	Global.location_name = "Тестовая комната"
	
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
			preload("res://holdables/equippables/weapons/mic_dark.tres"),
			preload("res://holdables/items/heal_candy.tres"),
			preload("res://holdables/items/beer.tres"),
			preload("res://holdables/items/translator.tres"),
			preload("res://holdables/equippables/free_money_test.tres"),
			preload("res://holdables/items/mystery_key.tres")
		]
		Global.items.clear()
		for item in defaults:
			if item.usePredicate != null and item.usePredicate.item == null:
				item.usePredicate.item = item
			Global.add_item(item)
