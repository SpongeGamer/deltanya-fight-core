extends "res://fighters/monsters/serega/attacks/common/serega_attack.gd"

# Two continuous melodies intersect, with different periods and directions.
func get_duration() -> float:
	return 14.0

func run() -> void:
	await wait(0.5)
	for i in 24:
		var side: int = -1 if i % 2 == 0 else 1
		var y: float = 47.0 * sin(float(i) * 0.8)
		var n = shot(Vector2(side * 84, y), Vector2(-side * 104, 0), PALE if side < 0 else PINK, 13, 1, 3.5)
		n.wave_amplitude = 13.0
		n.wave_frequency = 4.2
		n.wave_phase = float(i) * 0.45
		n.spin = 3.0 * side
		if i % 4 == 0:
			beat()
		await wait(0.38)
