extends "res://fighters/monsters/serega/attacks/common/serega_attack.gd"

const SOURCE := preload("res://fighters/monsters/serega/attacks/common/serega_echo_source.gd")

func get_duration() -> float:
	return 13.5

func run() -> void:
	await wait(0.6)
	var source = SOURCE.new()
	source.attack = self
	source.position = Vector2(-102, -44 if randi() % 2 == 0 else 44)
	source.velocity = Vector2(69, 48 if source.position.y < 0 else -48)
	field.add_child(source)
	await wait(2.0)
	for wave in 5:
		var side: int = -1 if wave % 2 == 0 else 1
		var target: Vector2 = soul_pos()
		var origin := Vector2(side * 88, -48.0 + wave * 24.0)
		var dir: Vector2 = (target - origin).normalized()
		for angle in [-0.25, 0.25]:
			shot(origin, dir.rotated(angle) * 100.0, PINK, 13)
		beat()
		await wait(1.5)
