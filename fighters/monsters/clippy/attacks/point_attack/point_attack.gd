extends Node2D
# POINT_ATTACK — хоминг-курсоры спавнятся на случайном крае арены
# и изначально летят прямо в сторону соула.

var launch_timer := 0.3
var launched := 0
const MAX_LAUNCHES := 6
const LAUNCH_DELAY := 0.9

func _physics_process(delta: float) -> void:
	if launched >= MAX_LAUNCHES:
		return
	launch_timer -= delta
	if launch_timer > 0.0:
		return
	launch_timer = LAUNCH_DELAY
	_launch(launched)
	launched += 1

func _random_edge_position() -> Vector2:
	match randi() % 4:
		0: return Vector2(randf_range(-78.0, 78.0), -80.0)
		1: return Vector2(randf_range(-78.0, 78.0),  80.0)
		2: return Vector2(-80.0, randf_range(-78.0, 78.0))
		_: return Vector2( 80.0, randf_range(-78.0, 78.0))

func _launch(idx: int) -> void:
	var spawn := _random_edge_position()

	var soul: Node2D = get_parent().get_node_or_null("Soul")
	var aim_pos := Vector2.ZERO
	if soul:
		aim_pos = soul.position
	# Лёгкий разброс ±15° чтобы не было идеального прицела с первого кадра
	var base_dir := (aim_pos - spawn).normalized()
	var dir := base_dir.rotated(randf_range(-0.26, 0.26))

	var p := $BaseBullet.duplicate()
	p.visible    = true
	p.position   = spawn
	p.direction  = dir
	p.turn_speed = 1.6 + idx * 0.35
	p.velocity   = 80.0 + idx * 8.0
	add_child(p)
