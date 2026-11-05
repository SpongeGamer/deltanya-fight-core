extends Node2D

const MARK := preload("res://fighters/monsters/captcha/attacks/human_check/reject_mark.gd")
const POSITIONS := [
	Vector2(-44, -44), Vector2(0, -44), Vector2(44, -44),
	Vector2(-44, 0), Vector2(0, 0), Vector2(44, 0),
	Vector2(-44, 44), Vector2(0, 44), Vector2(44, 44)
]
const ROUNDS := 3
const PREVIEW := 2.15
const SHOW_MARKS := 0.65
const BETWEEN := 0.45

var phase := 0
var timer := 0.25
var completed := 0
var safe_index := -1
var previous_safe := -1

func _physics_process(delta: float) -> void:
	timer -= delta
	if timer <= 0.0:
		match phase:
			0:
				_start_round()
			1:
				_reject_others()
				phase = 2
				timer = SHOW_MARKS
			2:
				completed += 1
				if completed < ROUNDS:
					phase = 0
					timer = BETWEEN
				else:
					phase = 3
	queue_redraw()

func _start_round() -> void:
	var choices := range(POSITIONS.size())
	choices.erase(previous_safe)
	safe_index = choices.pick_random()
	previous_safe = safe_index
	phase = 1
	timer = PREVIEW

func _reject_others() -> void:
	for i in POSITIONS.size():
		if i == safe_index:
			continue
		var mark := MARK.new()
		mark.position = POSITIONS[i]
		add_child(mark)

func _draw() -> void:
	if phase != 1 and phase != 2:
		return
	for i in POSITIONS.size():
		var p: Vector2 = POSITIONS[i]
		if i == safe_index:
			# A check mark distinguishes the safe choice even without color.
			draw_rect(Rect2(p - Vector2(10, 10), Vector2(20, 20)), Color("d9f0eb"))
			draw_rect(Rect2(p - Vector2(9, 9), Vector2(18, 18)), Color("357e68"))
			draw_line(p + Vector2(-5, 0), p + Vector2(-1, 4), Color.WHITE, 2.0)
			draw_line(p + Vector2(-1, 4), p + Vector2(6, -4), Color.WHITE, 2.0)
		elif phase == 1:
			# Small, quiet X markers show where the rejection icons will appear.
			var a := 0.38 + 0.18 * (1.0 - timer / PREVIEW)
			var col := Color(0.57, 0.67, 0.86, a)
			draw_rect(Rect2(p - Vector2(7, 7), Vector2(14, 14)), col, false, 1.0)
			draw_line(p + Vector2(-3, -3), p + Vector2(3, 3), col, 1.0)
			draw_line(p + Vector2(3, -3), p + Vector2(-3, 3), col, 1.0)
