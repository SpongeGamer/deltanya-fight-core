extends "res://fighters/monsters/serega/attacks/common/serega_attack.gd"
const KEY := preload("res://fighters/monsters/serega/attacks/common/serega_key.gd")
const MARKER := preload("res://fighters/monsters/serega/attacks/common/serega_marker.gd")
const RING := preload("res://fighters/monsters/serega/attacks/common/serega_ring.gd")

# If the battle continues after all twelve designed turns, compose new phrases.
func get_duration() -> float:
	return 14.5

func run() -> void:
	await wait(0.5)
	var composition: int = variation
	for section in 4:
		var pattern: int = composition % 4
		composition = int(composition / 4)
		var side: int = -1 if (section + variation) % 2 == 0 else 1
		match pattern:
			0:
				group(Vector2(side * 100, -30), Vector2(-side * 95, 30), 0, float(side))
				await wait(0.7)
				page(Vector2(-side * 84, -40), Vector2(side * 40, 8), 0.85)
			1:
				var ring = RING.new()
				ring.missing = (variation * 3 + section * 4) % 14
				ring.rotation_direction = float(side)
				field.add_child(ring)
				await wait(0.7)
				var note = shot(Vector2(side * 84, 35), Vector2(-side * 100, 0), PINK, 13)
				note.wave_amplitude = 12.0
			2:
				for i in 3:
					var key = KEY.new()
					key.attack = self
					key.position = Vector2(-48.0 + float((i + variation + section) % 5) * 24.0, -90)
					field.add_child(key)
					await wait(0.22)
			3:
				for i in 2:
					var mark = MARKER.new()
					mark.attack = self
					mark.position = soul_pos()
					mark.phase = float((i + section) % 2) * PI / 6.0
					field.add_child(mark)
					await wait(0.38)
		beat()
		await wait(2.0)
