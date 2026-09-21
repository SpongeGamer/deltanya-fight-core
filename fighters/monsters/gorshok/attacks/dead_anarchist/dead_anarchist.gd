extends Node2D
# «Мёртвый анархист» — атака Горшка.
# Черепа восстают из земли и медленно идут к игроку.

const CAGE_NORMAL := Vector2(150.0, 150.0)
const CAGE_WIDE   := Vector2(240.0, 150.0)

const SKULL_COUNT:    int   = 5
const SPAWN_INTERVAL: float = 0.65

# X-позиции спавна — равномерно по широкой арене
const SPAWN_XS: Array[float] = [-90.0, -48.0, 0.0, 48.0, 90.0]

var soul_cage       = null
var spawned:   int  = 0
var spawn_timer: float = 0.3
var done:       bool = false
var cleaned_up: bool = false

# Спавним в случайном порядке чтобы не было одновременно слева-направо
var spawn_order: Array = []


func _ready() -> void:
	z_index = 5
	var soul := get_tree().get_first_node_in_group("soul") as Soul
	if soul:
		soul_cage = soul.get_parent().get_node_or_null("SoulCage")
	if soul_cage:
		soul_cage.resize(CAGE_WIDE)

	spawn_order = range(SKULL_COUNT)
	spawn_order.shuffle()


func _physics_process(delta: float) -> void:
	if done:
		return
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		_spawn_skull()
		spawned += 1
		spawn_timer = SPAWN_INTERVAL
		if spawned >= SKULL_COUNT:
			done = true


func _spawn_skull() -> void:
	var skull := $BaseSkull.duplicate() as WalkingSkull
	skull.visible = true
	skull.z_index = 5

	var xi: int   = spawn_order[spawned]
	var x:  float = SPAWN_XS[xi] + randf_range(-8.0, 8.0)
	# Начинают снизу арены — "встают из земли"
	skull.position = Vector2(x, 68.0)

	add_child(skull)


func _exit_tree() -> void:
	if cleaned_up:
		return
	cleaned_up = true
	if soul_cage != null and is_instance_valid(soul_cage):
		soul_cage.resize(CAGE_NORMAL)
