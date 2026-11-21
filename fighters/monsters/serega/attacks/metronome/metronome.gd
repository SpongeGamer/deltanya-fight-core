extends "res://fighters/monsters/serega/attacks/common/serega_attack.gd"
const METRONOME := preload("res://fighters/monsters/serega/attacks/common/serega_metronome.gd")

func get_duration() -> float:
	return 12.0

func run() -> void:
	await wait(0.45)
	var pendulum = METRONOME.new()
	pendulum.attack = self
	field.add_child(pendulum)
	await wait(1.5)
	for phrase in 6:
		var side: int = -1 if phrase % 2 == 0 else 1
		var n = shot(Vector2(side * 84, 34), Vector2(-side * 90, 0), VIOLET, 12)
		n.wave_amplitude = 11.0
		n.wave_frequency = 3.2
		await wait(1.25)
