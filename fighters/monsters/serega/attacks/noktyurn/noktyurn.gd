extends "res://fighters/monsters/serega/attacks/common/serega_attack.gd"

# Broken scores fall into the field and split into drifting fragments.
func get_duration() -> float:
	return 13.5

func run() -> void:
	await wait(0.45)
	var offset: int = randi_range(0, 3)
	for i in 7:
		var x: float = [-54.0, -18.0, 20.0, 54.0][(i + offset) % 4]
		page(Vector2(x, -84.0), Vector2((-1.0 if i % 2 == 0 else 1.0) * 12.0, 42.0), 0.85)
		if i >= 3:
			var side: int = -1 if i % 2 == 0 else 1
			var bullet = shot(Vector2(side * 84, 40), Vector2(-side * 93, -20), VIOLET, 12)
			bullet.wave_amplitude = 5.0
			bullet.wave_phase = float(i)
		await wait(1.42 if variation == 0 else 1.25)
