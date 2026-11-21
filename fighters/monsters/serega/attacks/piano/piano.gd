extends "res://fighters/monsters/serega/attacks/common/serega_attack.gd"
const KEY := preload("res://fighters/monsters/serega/attacks/common/serega_key.gd")

func get_duration() -> float:
	return 13.5

func run() -> void:
	await wait(0.5)
	var start: int = randi_range(0, 4)
	for beat_index in 14:
		var lane: int = (start + beat_index * 2) % 5
		var key = KEY.new()
		key.attack = self
		key.position = Vector2(-55.0 + lane * 27.5, -90)
		key.velocity = Vector2((float(beat_index % 3) - 1.0) * 10.0, 110.0 + float(beat_index % 3) * 8.0)
		field.add_child(key)
		if beat_index % 3 == 0:
			beat()
		await wait(0.66)
