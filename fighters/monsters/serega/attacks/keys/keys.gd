extends "res://fighters/monsters/serega/attacks/common/serega_phrases.gd"
func get_duration() -> float:
	return 15.0
func run() -> void:
	await wait(0.65)
	var edge: int = -1
	var gap: int = -1
	for i in 7:
		edge = next_edge(edge)
		gap = next_gap(gap)
		# The keys pulsate individually; this phrase does not rotate like the staff.
		phrase(2, 1, gap, 90.0 + float(i) * 2.0, PALE, edge, randf_range(-0.10, 0.10), 0.0)
		beat()
		await wait(1.50 if i % 3 != 1 else 1.72)
