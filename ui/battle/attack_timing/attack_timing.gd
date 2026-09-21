extends Node2D

var focused := false:
	set(p_focused):
		focused = p_focused
		visible = focused
var char_timings: Array[CharTiming] = []
var active_timings: Array[CharTiming] = []
var handle_input := true

func _ready() -> void:
	for character: Character in Global.characters:
		var char_timing := preload("res://ui/battle/attack_timing/char_timing/char_timing.tscn").instantiate()
		char_timing.set_from_character(character)
		$CharTimings.add_child(char_timing)
		char_timings.append(char_timing)

func set_as_attacking(p_char: int, p_is_attacking: bool) -> void:
	char_timings[p_char].set_active(p_is_attacking)
	if p_is_attacking:
		active_timings.append(char_timings[p_char])

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action("confirm") and event.is_pressed() and focused and handle_input:
		hit()

func hit() -> void:
	var closest_timings: Array[CharTiming] = []
	for timing: CharTiming in active_timings:
		if closest_timings.is_empty():
			closest_timings.append(timing)
			continue
		if is_equal_approx(closest_timings[0].indicator.position.x, timing.indicator.position.x):
			closest_timings.append(timing)
		elif closest_timings[0].indicator.position.x > timing.indicator.position.x:
			closest_timings.clear()
			closest_timings.append(timing)
	if closest_timings[0].indicator.position.x < 202.0:
		for timing: CharTiming in closest_timings:
			var damage := timing.hit()
			get_parent().do_attack(timing.char_id, damage)
			active_timings.erase(timing)
	if active_timings.is_empty():
		handle_input = false
		await get_tree().create_timer(1.0).timeout
		handle_input = true
		focused = false
		get_parent().do_next_action()
