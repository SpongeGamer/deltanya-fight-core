extends Node

const KEY_ITEM = preload("res://holdables/items/mystery_key.tres")

@export var dialogue_no_key: Array[DE]
@export var dialogue_has_key: Array[DE]
@export var dialogue_area: NodePath
@export var travel_trigger: NodePath
@export var door_block: NodePath
@export var door_sprite: AnimatedSprite2D

func _ready() -> void:
	var area := get_node(dialogue_area) as Area2D
	if area == null:
		return
	var has_key := Global.items.any(func(i): return i != null and i.resource_path == KEY_ITEM.resource_path)
	if has_key:
		area.dialogue = dialogue_has_key
	else:
		area.dialogue = dialogue_no_key

func open_and_travel() -> void:
	Sounds.play("snd_key")
	if door_sprite:
		door_sprite.play("open")
	if door_block:
		var block := get_node(door_block)
		if is_instance_valid(block):
			block.queue_free()
	await get_tree().create_timer(1.5).timeout
	var trigger := get_node(travel_trigger) as Area2D
	if trigger == null:
		printerr("door: travel_trigger не задан")
		return
	trigger._travel()
