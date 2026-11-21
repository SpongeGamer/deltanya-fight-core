extends "res://fighters/monsters/serega/attacks/common/serega_attack.gd"
const ORCHESTRA := preload("res://fighters/monsters/serega/attacks/common/serega_orchestra.gd")

func get_duration() -> float:
	return 12.5

func run() -> void:
	await wait(0.6)
	var orchestra = ORCHESTRA.new()
	orchestra.attack = self
	orchestra.direction = -1.0 if randi() % 2 == 0 else 1.0
	field.add_child(orchestra)
	await wait(2.5)
	for wave in 4:
		var side: int = -1 if wave % 2 == 0 else 1
		var n = shot(Vector2(side * 84, -55), Vector2(-side * 87, 38), VIOLET, 12)
		n.wave_amplitude = 8.0
		await wait(1.6)
