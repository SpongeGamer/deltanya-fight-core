extends "res://fighters/monsters/serega/attacks/common/serega_phrases.gd"
func get_duration() -> float:
	return 15.0
func run() -> void:
	var edge: int = -1
	var gap: int = -1
	for i in 7:
		edge = next_edge(edge)
		gap = next_gap(gap)
		cue_edge(edge, 0)
		await wait(0.55)
		phrase(1, 1, gap, 94.0 + float(i) * 2.0, PINK if i % 2 == 0 else VIOLET, edge, randf_range(-0.22, 0.22), randf_range(-0.12, 0.12))
		beat()
		await wait(1.0)
