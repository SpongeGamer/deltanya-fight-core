extends "res://fighters/monsters/serega/attacks/common/serega_phrases.gd"
func get_duration() -> float:
	return 15.5
func run() -> void:
	var edge: int = -1
	var gap: int = -1
	for i in 5:
		edge = next_edge(edge)
		gap = next_gap(gap)
		cue_edge(edge, 1)
		await wait(0.7)
		phrase(3, 1, gap, 103.0, RED, edge, 0.18, 0.10)
		beat()
		await wait(0.65)
		var echo_edge: int = (edge + 2) % 4
		cue_edge(echo_edge, 1)
		await wait(0.55)
		var echo_gap: int = next_gap(gap)
		phrase(3, 1, echo_gap, 97.0, VIOLET, echo_edge, -0.18, -0.10)
		await wait(0.65)
