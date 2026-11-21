extends "res://fighters/monsters/serega/attacks/common/serega_phrases.gd"
func get_duration() -> float:
	return 15.0
func run() -> void:
	await wait(0.55)
	var edge: int = -1
	var gap: int = -1
	for i in 7:
		edge = next_edge(edge)
		gap = next_gap(gap)
		# The staff slowly turns while crossing; the opening turns with it.
		phrase(0, 1, gap, 76.0, PALE if i % 2 == 0 else PINK, edge, randf_range(-0.20, 0.20), randf_range(-0.18, 0.18))
		beat()
		await wait(1.56)
