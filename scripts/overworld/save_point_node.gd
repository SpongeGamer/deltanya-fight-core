extends Node2D

signal save_menu_closed

const SaveMenuScene := preload("res://ui/overworld/save_menu.tscn")

func _ready() -> void:
	var anim := get_node_or_null("AnimatedSprite2D")
	if anim and anim is AnimatedSprite2D:
		(anim as AnimatedSprite2D).play("idle")

## Вызывается из DialogueFunction при взаимодействии с точкой.
## Лечит пати, блокирует игрока и открывает меню сохранения.
func open_save_menu() -> void:
	_heal_party()

	# Явно блокируем движение на случай если dialogue_area не успел
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.can_move = false

	var cl := CanvasLayer.new()
	cl.layer = 20
	get_tree().current_scene.add_child(cl)

	var menu := SaveMenuScene.instantiate()
	cl.add_child(menu)
	menu.closed.connect(func():
		save_menu_closed.emit()
		cl.queue_free()
		# Возвращаем управление после закрытия меню
		if player:
			player.can_move = true
	)

func _heal_party() -> void:
	if Global.characters.is_empty():
		Global.load_party_characters(false)
	for ch in Global.characters:
		if is_instance_valid(ch):
			# heal() вызывает create_text() которой нужно дерево — ставим HP напрямую
			ch.current_hp = ch.get_max_hp()
			ch.alive = true
	# Сохраняем актуальное HP в PartyData
	for i in Global.party.size():
		if i < Global.characters.size() and is_instance_valid(Global.characters[i]):
			PartyData.save_from_character(Global.party[i], Global.characters[i])
