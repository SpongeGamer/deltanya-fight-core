extends Node

# ── Экспорты ─────────────────────────────────────────────────────────────────
@export var cutscene_dialogue : Array[DE] = []
@export var timer_fallback_dialogue : Array[DE] = []
@export var exit_node: Area2D

# ── Флаги гаража ─────────────────────────────────────────────────────────────
const GARAGE_FLAGS := [
	"chair_left", "chair_right", "balloon", "shelf_left", "shelf_right",
	"descent", "serega", "bike", "nikita"
]
const CUTSCENE_FLAG := "garage_cutscene_done"

# ── Сцены компаньонов ─────────────────────────────────────────────────────────
const EGOR_SCENE := preload("res://scenes/prefabs/egor_body.tscn")
const KATE_SCENE := preload("res://scenes/prefabs/kate_body.tscn")

# ── НАСТРОЙКА КАТCЦЕНЫ (всё в инспекторе) ─────────────────────────────────────
@export var egor_spawn_position : Vector2 = Vector2(95, 588)
@export var egor_path : Array[Vector2] = []
@export var egor_final_idle : Vector2 = Vector2.DOWN

@export var kate_spawn_position : Vector2 = Vector2(95, 620)
@export var kate_path : Array[Vector2] = []
@export var kate_final_idle : Vector2 = Vector2.DOWN

var _timer : Timer = null

# ── _ready / timer ───────────────────────────────────────────────────────────
func _ready() -> void:
	_timer = Timer.new()
	_timer.wait_time = 180.0
	_timer.one_shot = true
	_timer.autostart = true
	add_child(_timer)
	_timer.timeout.connect(_on_timer_timeout)

# ── ГЛАВНАЯ ПРОВЕРКА С ДЕБАГОМ ───────────────────────────────────────────────
func check_flags() -> void:
	if Global.get_flag(CUTSCENE_FLAG):
		return
	for flag in GARAGE_FLAGS:
		if not Global.get_flag(flag):
			return
	# Все флаги собраны — останавливаем таймер и запускаем катсцену
	_timer.stop()
	_start_cutscene(cutscene_dialogue)

# ── Таймер ───────────────────────────────────────────────────────────────────
func _on_timer_timeout() -> void:
	if Global.get_flag(CUTSCENE_FLAG):
		return
	_start_cutscene(timer_fallback_dialogue if not timer_fallback_dialogue.is_empty() else cutscene_dialogue)

# ── Катсцена ──────────────────────────────────────────────────────────────────
func _start_cutscene(p_dialogue: Array[DE]) -> void:
	if Global.get_flag(CUTSCENE_FLAG):
		return
	Global.set_flag(CUTSCENE_FLAG)
	Global.set_flag("dialogue_in_progress")

	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.can_move = false

	var scene := get_tree().current_scene
	var egor : Companion = null
	var kate : Companion = null

	# СПАВН СРАЗУ
	if EGOR_SCENE:
		egor = EGOR_SCENE.instantiate() as Companion
		egor.global_position = egor_spawn_position
		scene.add_child(egor)

	if KATE_SCENE:
		kate = KATE_SCENE.instantiate() as Companion
		kate.global_position = kate_spawn_position
		scene.add_child(kate)

	# ДВИЖЕНИЕ СРАЗУ (параллельно диалогу)
	if egor:
		egor.start_cutscene_path(egor_path, egor_final_idle)
	if kate:
		kate.start_cutscene_path(kate_path, kate_final_idle)

	# ДИАЛОГ
	if not p_dialogue.is_empty():
		await _launch_dialogue(p_dialogue)

	# Ждём окончания движения
	if egor:
		await egor.cutscene_path_finished
	if kate:
		await kate.cutscene_path_finished

	if player and is_instance_valid(player):
		player.can_move = true
	Global.clear_flag("dialogue_in_progress")

func egor_vanish() -> void:
	var egor_node = get_tree().get_first_node_in_group("egor_body")
	if egor_node and is_instance_valid(egor_node):
		Sounds.play("gaster_fade")
		var fade := get_tree().create_tween()
		fade.tween_property(egor_node, "modulate:a", 0.0, 1.2)
		await fade.finished
		egor_node.queue_free()

func exit_open() -> void:
	if exit_node and exit_node is Area2D:
		exit_node.set_collision_layer_value(3, true)  # включаем слой 1
		exit_node.set_collision_mask_value(3, true)   # включаем маску 1

func _launch_dialogue(p_dialogue: Array[DE]) -> void:
	var DialogueScene := load("res://scenes/prefabs/dialogue_system.tscn") as PackedScene
	if DialogueScene == null:
		push_error("HelperNodeGarage: не найден dialogue_system.tscn")
		return
	var cl := CanvasLayer.new()
	cl.layer = 10
	get_tree().current_scene.add_child(cl)
	var dlg = DialogueScene.instantiate()
	dlg.dialogue = p_dialogue.duplicate()
	dlg.caller = self
	cl.add_child(dlg)
	await cl.tree_exited
