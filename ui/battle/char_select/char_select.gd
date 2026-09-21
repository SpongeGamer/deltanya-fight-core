extends SelectMenu

func set_selected_item(p_item: int) -> void:
	if items[selected_item]:
		Global.characters[get_current_id()].set_selected(false)
	Global.characters[items[p_item].char_id].set_selected(true and focused)

func get_current_id() -> int:
	return items[selected_item].char_id

func initialize_panels() -> void:
	clear_items()
	for character: Character in Global.characters:
		var char_panel := preload("res://ui/battle/char_select/char_panel/char_panel.tscn").instantiate()
		char_panel.set_from_character(character)
		$Characters.add_child(char_panel)
		items.append(char_panel)
	visible_items = items
	super()
