extends Node

var _dark_layer: CanvasLayer = null
var _player: CharacterBody2D

const APPLE_ITEM := preload("res://holdables/items/apple.tres")

# Настраивается прямо в инспекторе
@export var first_dialogue  : Array[DE] = []
@export var second_dialogue : Array[DE] = []

const ROOM_FLAGS := [
	"hall1", "hall2", "bath_door", "table",
	"apple", "sink", "counter", "fridge"
]

const FIRST_THRESHOLD := 3
const FIRST_FLAG_KEY  := "first_room_dialogue1_done"
const SECOND_FLAG_KEY := "first_room_dialogue2_done"

func _ready() -> void:
	# Снимаем флаг при старте сцены на случай если он завис с прошлого раза
	Global.clear_flag("dialogue_in_progress")

func pick_up_apple() -> void:
	var apple_sprite := get_tree().current_scene.get_node_or_null("Furniture/Apple3")
	if apple_sprite:
		apple_sprite.visible = false
	Sounds.play("snd_item")
	Global.add_item(APPLE_ITEM)

func check_flags() -> void:
	var count := 0
	for flag in ROOM_FLAGS:
		if Global.get_flag(flag):
			count += 1

	if count >= ROOM_FLAGS.size() and not Global.get_flag(SECOND_FLAG_KEY):
		Global.set_flag(SECOND_FLAG_KEY)
		_launch_dialogue(second_dialogue)
		return

	if count >= FIRST_THRESHOLD and not Global.get_flag(FIRST_FLAG_KEY):
		Global.set_flag(FIRST_FLAG_KEY)
		_launch_dialogue(first_dialogue)

func _launch_dialogue(p_dialogue: Array[DE]) -> void:
	if p_dialogue.is_empty():
		return
	var DialogueScene := load("res://scenes/prefabs/dialogue_system.tscn") as PackedScene
	if DialogueScene == null:
		push_error("HelperNodeHouse2: не найден dialogue_system.tscn")
		return

	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.can_move = false
	Global.set_flag("dialogue_in_progress")

	var cl := CanvasLayer.new()
	cl.layer = 10
	get_tree().current_scene.add_child(cl)
	var dlg = DialogueScene.instantiate()
	dlg.dialogue = p_dialogue.duplicate()
	# caller = self чтобы _resolve_target работал правильно для nikita_rage_leave
	dlg.caller = self
	cl.add_child(dlg)
	await cl.tree_exited

	Global.clear_flag("dialogue_in_progress")
	if player and is_instance_valid(player):
		player.can_move = true

func nikita_rage_leave() -> void:
	_player = get_tree().get_first_node_in_group("player")
	Sounds.fade_out_current(3)
	if _player:
		_player.can_move = false
	_dark_layer = _get_or_create_dark_layer()
	_dark_layer.visible = true
	Sounds.fade_out_current()

func _get_or_create_dark_layer() -> CanvasLayer:
	for child in get_children():
		if child is CanvasLayer and child.name == "DarknessLayer":
			return child

	var layer := CanvasLayer.new()
	layer.name = "DarknessLayer"
	layer.layer = 9
	layer.visible = false

	var rect := ColorRect.new()
	rect.color = Color.BLACK
	rect.anchor_right = 1.0
	rect.anchor_bottom = 1.0
	rect.size = get_viewport().get_visible_rect().size

	layer.add_child(rect)
	add_child(layer)
	return layer
