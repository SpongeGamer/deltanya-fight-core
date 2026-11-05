extends Node2D

const MARK := preload("res://fighters/monsters/captcha/attacks/loading/loading_mark.gd")
const SOURCES := [Vector2(-35, -35), Vector2(35, -35), Vector2(-35, 35), Vector2(35, 35), Vector2.ZERO]
const CHARGE := 1.25
const TOTAL := 4

var phase := 0
var timer := 0.3
var source := Vector2.ZERO
var waves := 0
var last_source := -1
var skip := 0
var base_angle := 0.0
var spin := 0.0

func _physics_process(delta: float) -> void:
	spin += delta * 5.0
	timer -= delta
	if timer <= 0.0:
		match phase:
			0:
				_begin_loading()
			1:
				_release()
				waves += 1
				if waves < TOTAL:
					phase = 0
					timer = 1.0
				else:
					phase = 2
	queue_redraw()

func _begin_loading() -> void:
	var soul := get_tree().get_first_node_in_group("soul") as Node2D
	var soul_pos := to_local(soul.global_position) if soul else Vector2.ZERO
	var choices := range(SOURCES.size())
	choices.shuffle()
	var best: int = choices[0]
	for i in choices:
		if i != last_source and (best == last_source or SOURCES[i].distance_to(soul_pos) > SOURCES[best].distance_to(soul_pos)):
			best = i
	last_source = best
	source = SOURCES[best]
	skip = randi_range(0, 9)
	base_angle = randf_range(0.0, TAU)
	phase = 1
	timer = CHARGE

func _release() -> void:
	for i in 10:
		if i == skip or i == (skip + 1) % 10:
			continue
		var mark := MARK.new()
		mark.position = source
		mark.velocity = Vector2.RIGHT.rotated(base_angle + TAU * i / 10.0) * (65.0 + waves * 4.0)
		add_child(mark)

func _draw() -> void:
	if phase != 1:
		return
	# A small Windows-style progress box, not a damaging wall.
	draw_rect(Rect2(source - Vector2(13, 10), Vector2(26, 20)), Color("143d90"))
	draw_rect(Rect2(source - Vector2(12, 9), Vector2(24, 18)), Color("f4f4ed"))
	draw_rect(Rect2(source - Vector2(12, 9), Vector2(24, 4)), Color("3179e8"))
	for i in 8:
		var a := spin + TAU * i / 8.0
		var p := source + Vector2(cos(a), sin(a)) * 5.0 + Vector2(0, 2)
		var alpha := 0.25 + 0.75 * float(i + 1) / 8.0
		draw_rect(Rect2(p - Vector2.ONE, Vector2(2, 2)), Color(0.12, 0.34, 0.72, alpha))

	# The dots preview the outgoing marks and reveal the gap before firing.
	for i in 10:
		if i == skip or i == (skip + 1) % 10:
			continue
		var a := base_angle + TAU * i / 10.0
		var p := source + Vector2(cos(a), sin(a)) * 19.0
		draw_rect(Rect2(p - Vector2.ONE, Vector2(2, 2)), Color(0.43, 0.67, 0.94, 0.75))
