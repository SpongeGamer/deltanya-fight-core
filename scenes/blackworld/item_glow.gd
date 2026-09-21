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
const MAX_INVENTORY_SIZE := 16   # ← подстрой под свой лимит

var _picked_up: bool = false

func pickup() -> void:
	if _picked_up:
		return

	# Проверяем полный инвентарь
	if item_resource and Global.items.size() >= MAX_INVENTORY_SIZE:
		_show_full_inventory_dialogue()
		return

	_picked_up = true

	if pickup_sound != "":
		Sounds.play(pickup_sound)

	if item_resource:
		Global.add_item(item_resource)

	if hide_self:
		visible = false

	if dialogue_collision:
		dialogue_collision.disabled = true

	for node in extra_nodes:
		if node:
			node.visible = false

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
