extends Node2D

const CAGE_SIZE        := Vector2(180.0, 220.0)
const SPAWN_TOP_Y      := -70.0
const CAULDRON_START_Y := 200.0

# Два элеватора: левый и правый X
const LEFT_X  : float = -45.0
const RIGHT_X : float =  45.0

# Интервал между спавном одной платформы на каждой стороне
const SPAWN_INTERVAL : float = 1.5

var left_timer  : float = 0.5   # первая платформа слева почти сразу
var right_timer : float = 1.0  # первая платформа справа — со сдвигом

var ended_early : bool = false

@onready var cauldron : Area2D = $Cauldron

func _ready() -> void:
	var soul := get_tree().get_first_node_in_group("soul") as Soul
	if soul:
		soul.assign_heart_properties(SoulType.BLUE)

	var cage := get_tree().get_first_node_in_group("cage")
	if cage and cage.has_method("resize"):
		cage.resize(CAGE_SIZE)

	cauldron.position = Vector2(0.0, CAULDRON_START_Y)
	if not cauldron.hit_soul.is_connected(_on_cauldron_hit):
		cauldron.hit_soul.connect(_on_cauldron_hit)


func _physics_process(delta: float) -> void:
	if ended_early:
		return

	left_timer -= delta
	if left_timer <= 0.0:
		left_timer = SPAWN_INTERVAL
		_spawn_platform(LEFT_X)

	right_timer -= delta
	if right_timer <= 0.0:
		right_timer = SPAWN_INTERVAL
		_spawn_platform(RIGHT_X)


func _spawn_platform(x: float) -> void:
	var plank: AnimatableBody2D = $BasePlatform.duplicate()
	plank.visible = true
	plank.position = Vector2(x, SPAWN_TOP_Y)
	add_child(plank)


func _on_cauldron_hit() -> void:
	if ended_early:
		return
	ended_early = true

	var battle := get_parent().get_parent()
	if battle and battle.has_method("end_attack"):
		battle.end_attack()


func _exit_tree() -> void:
	var soul := get_tree().get_first_node_in_group("soul") as Soul
	if soul:
		soul.assign_heart_properties(SoulType.RED)

	var cage := get_tree().get_first_node_in_group("cage")
	if cage and cage.has_method("reset_size"):
		cage.reset_size()
