extends "res://fighters/monsters/serega/attacks/common/serega_attack.gd"

# Moving wheels, not rows: each hub carries a rotating ring of notes.
func get_duration() -> float:
	return 14.5

func run() -> void:
	await wait(0.5)
	var side: int = -1 if randi() % 2 == 0 else 1
	for wave in 6:
		var y: float = [-42.0, 35.0, 0.0][wave % 3]
		group(Vector2(side * 100, y), Vector2(-side * 95, -y * 0.65), 0, float(side))
		beat()
		if wave >= 2:
			await wait(0.55)
			var drop = shot(Vector2(-side * 84, -62), Vector2(side * 98, 28), PINK, 13, 1, 3.5)
			drop.spin = 4.0
			await wait(1.05 if variation == 0 else 0.9)
		else:
			await wait(1.6 if variation == 0 else 1.45)
		side = -side
