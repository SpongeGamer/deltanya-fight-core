extends "res://fighters/monsters/serega/attacks/common/serega_attack.gd"

# Echoes from the two sides overlap: one splits while the other enters.
func get_duration() -> float:
	return 14.5

func run() -> void:
	await wait(0.5)
	var side: int = -1 if randi() % 2 == 0 else 1
	for phrase in 6:
		var y: float = -48.0 if phrase % 2 == 0 else 48.0
		page(Vector2(side * 86, y), Vector2(-side * 42, -y * 0.28), 0.8)
		await wait(0.55)
		var origin := Vector2(-side * 84, -y)
		var dir: Vector2 = (soul_pos() - origin).normalized()
		for angle in [-0.18, 0.18]:
			var note = shot(origin, dir.rotated(angle) * 105.0, PINK, 14)
			note.wave_amplitude = 6.0
			note.wave_phase = angle * 8.0
		await wait(1.15 if variation == 0 else 1.0)
		side = -side
