extends "res://fighters/monsters/serega/attacks/common/serega_attack.gd"
const MARKER := preload("res://fighters/monsters/serega/attacks/common/serega_marker.gd")

func get_duration() -> float:
	return 13.0

func run() -> void:
	await wait(0.7)
	for i in 11:
		var mark = MARKER.new()
		mark.attack = self
		mark.position = soul_pos()
		mark.phase = float(i % 2) * PI / 6.0
		field.add_child(mark)
		if i % 2 == 0:
			beat()
		await wait(0.82)
