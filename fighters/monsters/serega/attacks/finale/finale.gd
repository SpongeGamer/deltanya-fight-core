extends "res://fighters/monsters/serega/attacks/common/serega_phrases.gd"
func get_duration() -> float:
	return 21.0
func run() -> void:
	await wait(0.8)
	var edge: int = -1
	var gap: int = -1
	for i in 4:
		edge = next_edge(edge)
		gap = next_gap(gap)
		phrase(0, 1, gap, 80.0, PALE, edge, randf_range(-0.20, 0.20), 0.15)
		beat()
		await wait(1.35)
	await wait(0.6)
	for i in 4:
		edge = next_edge(edge)
		gap = next_gap(gap)
		cue_edge(edge, 0)
		await wait(0.55)
		phrase(1, 1, gap, 96.0, PINK, edge, randf_range(-0.20, 0.20), -0.12)
		beat()
		await wait(0.95)
	await wait(0.55)
	for i in 3:
		edge = next_edge(edge)
		gap = next_gap(gap)
		cue_edge(edge, 1)
		await wait(0.55)
		phrase(3, 1, gap, 102.0, RED, edge, 0.18, 0.10)
		beat()
		await wait(1.05)
	await wait(0.35)
	edge = next_edge(edge)
	gap = next_gap(gap)
	phrase(0, 1, gap, 92.0, PALE, edge, 0.0, 0.18)
	beat()
