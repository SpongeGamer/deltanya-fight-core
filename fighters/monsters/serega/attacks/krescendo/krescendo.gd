extends "res://fighters/monsters/serega/attacks/common/serega_attack.gd"

# Twisting bars cross the box while a second melody cuts between them.
func get_duration() -> float:
	return 15.0

func run() -> void:
	await wait(0.65)
	var side: int = -1 if randi() % 2 == 0 else 1
	for phrase in 5:
		group(Vector2(side * 105, -38), Vector2(-side * 95, 38), 1, float(side))
		beat()
		await wait(0.8)
		var x: float = -35.0 if phrase % 2 == 0 else 35.0
		for i in 3:
			var n = shot(Vector2(x + float(i - 1) * 19.0, -82), Vector2(12 * side, 100 + phrase * 5), PALE, 14)
			n.wave_amplitude = 7.0
			n.wave_phase = float(i) * 0.7
		await wait(1.25 if variation == 0 else 1.1)
		side = -side
