extends Node2D
# «Марионетка» — атака Князя.

const CAGE_NORMAL := Vector2(150.0, 150.0)
const CAGE_WIDE   := Vector2(280.0, 150.0)
const CAGE_HALF_X := 135.0   # половина ширины минус чуть-чуть от стены

# Y-позиции нитей (совпадают с string_move: line_count=5, line_spacing=30)
const LINE_YS: Array[float] = [-60.0, -30.0, 0.0, 30.0, 60.0]

var soul: Soul           = null
var soul_cage            = null
var original_soul_type: SoulType = null

var spawn_timer:    float = 1.0
var bullets_spawned: int  = 0
const MAX_BULLETS:  int   = 24

var done:       bool = false
var cleaned_up: bool = false


func _ready() -> void:
	z_index = 5   # выше Panel коробки

	soul = get_tree().get_first_node_in_group("soul") as Soul
	if soul == null:
		push_warning("Marionette: soul not found"); return

	soul_cage = soul.get_parent().get_node_or_null("SoulCage")
	if soul_cage == null:
		push_warning("Marionette: SoulCage not found"); return

	# Расширяем коробку
	soul_cage.resize(CAGE_WIDE)

	# Переключаем душу в режим нитей
	original_soul_type = soul.current_soul_type
	soul.assign_heart_properties(SoulType.PURPLE)

	# Патчим xClamp у StringMove чтобы нити растянулись на всю коробку
	for beh in soul.behaviors:
		if beh.get("xClamp") != null:
			beh.xClamp = CAGE_HALF_X

	# Вручную запускаем turn_start (там создаются нити и душа встаёт на них)
	if soul.active:
		for beh in soul.behaviors:
			beh.turn_start()


func _physics_process(delta: float) -> void:
	if done:
		if !cleaned_up:
			_cleanup()
		return

	spawn_timer -= delta
	if spawn_timer <= 0.0:
		_spawn_bullet()
		bullets_spawned += 1
		spawn_timer = randf_range(0.28, 0.52)
		if bullets_spawned >= MAX_BULLETS:
			done = true


func _spawn_bullet() -> void:
	var bullet := $BaseBullet.duplicate() as StringBullet
	bullet.visible = true
	bullet.z_index  = 5

	var y: float = LINE_YS[randi() % LINE_YS.size()]
	var left: bool = randf() > 0.5
	bullet.position = Vector2(-132.0 if left else 132.0, y)
	bullet.dir      = 1.0 if left else -1.0
	bullet.speed    = randf_range(70.0, 120.0)
	add_child(bullet)


func _exit_tree() -> void:
	if cleaned_up:
		return
	cleaned_up = true
	if soul != null and is_instance_valid(soul):
		if soul.active:
			for beh in soul.behaviors:
				beh.turn_end()
		if original_soul_type != null:
			soul.assign_heart_properties(original_soul_type)
	if soul_cage != null and is_instance_valid(soul_cage):
		soul_cage.resize(CAGE_NORMAL)

func _cleanup() -> void:
	_exit_tree()
