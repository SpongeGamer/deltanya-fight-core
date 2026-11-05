extends Node2D

const BUTTON := preload("res://fighters/monsters/clippy/attacks/cant_close/close_button.gd")
const WINDOW_POINTS := [Vector2(-47, -44), Vector2(42, 44), Vector2(42, -44), Vector2(-47, 44)]
const WINDOW_TOTAL := 8
const INTERVAL := 1.05

var timer := 0.35
var spawned := 0
var windows: Array[Dictionary] = []

func _physics_process(delta: float) -> void:
	timer -= delta
	if spawned < WINDOW_TOTAL and timer <= 0.0:
		_open_window()
		spawned += 1
		timer = INTERVAL
	for i in range(windows.size() - 1, -1, -1):
		var w := windows[i]
		w.age += delta
		if w.age >= 0.95 and not w.fired:
			w.fired = true
			_launch_button(w.pos + Vector2(11, -6), w.double)
		if w.age >= 1.32:
			windows.remove_at(i)
	queue_redraw()

func _open_window() -> void:
	var soul := get_tree().get_first_node_in_group("soul") as Node2D
	var soul_pos := to_local(soul.global_position) if soul else Vector2.ZERO
	var best: Vector2 = WINDOW_POINTS[spawned % WINDOW_POINTS.size()]
	if best.distance_to(soul_pos) < 38.0:
		for point in WINDOW_POINTS:
			if point.distance_to(soul_pos) > best.distance_to(soul_pos):
				best = point
	windows.append({"pos": best, "age": 0.0, "fired": false, "double": spawned >= 3 and spawned % 2 == 1})

func _launch_button(from: Vector2, double: bool) -> void:
	var soul := get_tree().get_first_node_in_group("soul") as Node2D
	var target := to_local(soul.global_position) if soul else Vector2.ZERO
	var direction := (target - from).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.DOWN
	var angles := [-0.20, 0.20] if double else [0.0]
	for angle in angles:
		var button := BUTTON.new()
		button.position = from
		button.velocity = direction.rotated(angle) * 80.0
		add_child(button)

func _draw() -> void:
	for w in windows:
		var p: Vector2 = w.pos
		var age: float = w.age
		var alpha := minf(1.0, age / 0.16)
		if age > 1.12:
			alpha = maxf(0.0, (1.32 - age) / 0.2)
		var outline := Color(0.10, 0.15, 0.34, alpha)
		var face := Color(0.87, 0.89, 0.85, alpha)
		var blue := Color(0.12, 0.30, 0.72, alpha)
		var light := Color(1, 1, 1, alpha)
		draw_rect(Rect2(p + Vector2(-16, -10), Vector2(32, 20)), outline)
		draw_rect(Rect2(p + Vector2(-15, -9), Vector2(30, 18)), face)
		draw_rect(Rect2(p + Vector2(-15, -9), Vector2(30, 6)), blue)
		# Two tiny lines suggest a message without covering the arena in text.
		draw_rect(Rect2(p + Vector2(-11, 0), Vector2(16, 1)), Color(0.48, 0.51, 0.55, alpha))
		draw_rect(Rect2(p + Vector2(-11, 4), Vector2(11, 1)), Color(0.61, 0.64, 0.66, alpha))
		if not w.fired:
			var pulse := 0.75 + 0.25 * sin(age * 14.0)
			draw_rect(Rect2(p + Vector2(8, -9), Vector2(6, 6)), Color(0.84, 0.25 * pulse, 0.20, alpha))
			draw_line(p + Vector2(9, -8), p + Vector2(12, -5), light, 1.0)
			draw_line(p + Vector2(12, -8), p + Vector2(9, -5), light, 1.0)
