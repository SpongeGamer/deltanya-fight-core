extends AnimatedSprite2D

## Экспорты
@export var item_resource: Item = null
@export var pickup_sound: String = "snd_item"
@export var hide_self: bool = true
@export var dialogue_collision: CollisionShape2D
@export var extra_nodes: Array[Node2D] = []

## Диалог если инвентарь полон — задаётся в инспекторе
@export var full_inventory_dialogue: Array[DE] = []

const DialogueSystemPreload = preload("res://scenes/prefabs/dialogue_system.tscn")
@export var pickup_flag: String = ""
var _picked_up: bool = false

func _ready() -> void:
	if pickup_flag != "" and Global.get_flag(pickup_flag):
		_picked_up = true
		_hide_pickup()

func pickup() -> void:
	if _picked_up or item_resource == null:
		return
	var sent_to_storage := not Global.inventory_has_space()
	if not Global.add_item(item_resource):
		_append_message("Инвентарь и склад полны. Освободите место.")
		return
	_picked_up = true
	if pickup_flag != "":
		Global.set_flag(pickup_flag)
	if pickup_sound != "":
		Sounds.play(pickup_sound)
	_hide_pickup()
	if sent_to_storage:
		_append_message("В инвентаре нет места. Предмет отправлен на склад.")

func _hide_pickup() -> void:
	if hide_self:
		visible = false
	if dialogue_collision:
		dialogue_collision.set_deferred("disabled", true)
	for node in extra_nodes:
		if node:
			node.visible = false

func _append_message(message: String) -> void:
	var area := get_parent()
	if area and area.has_method("append_to_active_dialogue"):
		var line := DialogueText.new()
		line.text = message
		line.text_speed = 18.0
		var entries: Array[DE] = [line]
		area.call("append_to_active_dialogue", entries)

func _show_full_inventory_dialogue() -> void:
	if full_inventory_dialogue.is_empty():
		# Фоллбэк если диалог не задан
		push_warning("item_glow: инвентарь полон, но full_inventory_dialogue не задан")
		return

	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.can_move = false

	var cl := CanvasLayer.new()
	cl.layer = 10
	get_tree().current_scene.add_child(cl)
	var dlg := DialogueSystemPreload.instantiate()
	dlg.dialogue = full_inventory_dialogue.duplicate()
	dlg.caller = self
	cl.add_child(dlg)
	await cl.tree_exited

	if player and is_instance_valid(player):
		player.can_move = true
