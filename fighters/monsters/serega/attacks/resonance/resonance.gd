extends "res://fighters/monsters/serega/attacks/common/serega_attack.gd"
const RING := preload("res://fighters/monsters/serega/attacks/common/serega_ring.gd")

func get_duration() -> float:
	return 13.0

func run() -> void:
	await wait(0.4)
	var gap: int = randi_range(0, 13)
	for wave in 3:
		var ring = RING.new()
		ring.missing = (gap + wave * 4) % 14
		ring.rotation_direction = 1.0 if wave % 2 == 0 else -1.0
		field.add_child(ring)
		beat()
		await wait(2.7)
		# A lone note cuts through while the previous ring is still opening.
		var side: int = -1 if wave % 2 == 0 else 1
		shot(Vector2(side * 84, 42.0 * side), Vector2(-side * 104, -32.0 * side), PINK, 13)
		await wait(0.6)
