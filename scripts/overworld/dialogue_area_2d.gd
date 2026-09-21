extends Area2D

const DialogueSystemPreload = preload("res://scenes/prefabs/dialogue_system.tscn")

@export var activate_instant: bool
@export var only_activate_once: bool
## Если задан — состояние "уже активировано" сохраняется в Global.flags.
## Используй уникальный ключ, например: "npc_zahar_candy"
@export var flag_key: String = ""
@export var dialogue: Array[DE]

## Включить проверку ретранслятора
@export var use_translator_check: bool = false
## Диалог когда ретранслятор включён
@export var dialogue_translated: Array[DE]

var player_body_in: bool = false
var has_activated_already: bool = false
var player_node: CharacterBody2D = null
var _is_active: bool = false  # локальная блокировка повторного вызова

func _ready() -> void:
	for i in get_tree().get_nodes_in_group("player"):
		player_node = i
	# Восстанавливаем состояние из флагов если ключ задан
	if flag_key != "" and Global.get_flag(flag_key):
		has_activated_already = true

func _process(_delta: float) -> void:
	if !player_node:
		for i in get_tree().get_nodes_in_group("player"):
			player_node = i
		return

	if !activate_instant and player_body_in:
		if only_activate_once and has_activated_already:
			set_process(false)
			return
		# Не запускаем диалог пока открыт инвентарь или игрок уже заблокирован
		if player_node.get("inventory_open"):
			return
		if not player_node.can_move:
			return
		if Input.is_action_just_pressed("interact"):
			_activate_dialogue()
			player_body_in = false

func _activate_dialogue() -> void:
	if _is_active:
		return
	if player_node == null or player_node.get("inventory_open"):
		return
	# Глобальная блокировка — не запускаем если уже идёт любой диалог или катсцена
	if Global.get_flag("dialogue_in_progress"):
		return
	if flag_key != "":
		Global.set_flag(flag_key)

	# Если игрок уже заблокирован (другой диалог, бой, инвентарь и т.д.) — не запускаем
	if not player_node.can_move:
		return

	_is_active = true
	Global.set_flag("dialogue_in_progress")
	player_node.can_move = false

	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 10
	get_tree().current_scene.add_child(canvas_layer)

	var new_dialogue = DialogueSystemPreload.instantiate()
	# Выбираем нужный набор диалогов
	var active_dialogue := dialogue
	if use_translator_check \
			and not dialogue_translated.is_empty() \
			and Global.get_flag("translator_active"):
		active_dialogue = dialogue_translated
	new_dialogue.dialogue = active_dialogue
	new_dialogue.caller = self
	canvas_layer.add_child(new_dialogue)

	await new_dialogue.tree_exited

	_is_active = false
	Global.clear_flag("dialogue_in_progress")
	if is_instance_valid(player_node):
		player_node.can_move = true

	has_activated_already = true
	

func _on_body_entered(body: Node2D) -> void:
	if only_activate_once and has_activated_already:
		return
	if body.is_in_group("player"):
		player_body_in = true
		if activate_instant:
			_activate_dialogue()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_body_in = false
		
## Заморозить игрока (запретить движение).
## Вызывай перед запуском диалога или катсцены.
func freeze_player() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.can_move = false
 
## Разморозить игрока (разрешить движение).
## Вызывай после окончания диалога или катсцены.
func unfreeze_player() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.can_move = true

func restart_with_dialogue(new_dialogue: Array[DE]) -> void:
	dialogue_translated = new_dialogue
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	_activate_dialogue()
