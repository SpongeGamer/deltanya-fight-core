extends StarwalkerAttack
## Размеренные взмахи: волна слева, затем справа; каждая оставляет проход.

func get_duration() -> float:
	return 8.7 + (0.85 if chicken_reaction else 0.0)

func run() -> void:
	await wait(0.5)
	for wave in 5:
		var side := -1.0 if wave % 2 == 0 else 1.0
		var gap := randi_range(1, 3)
		for row in 5:
			if row == gap:
				continue
			var y := -60.0 + row * 30.0
			warn_line(Vector2(side * 70.0, y), Vector2(-side * 70.0, y), 0.7)
		await wait(0.72)
		pulse()
		Sounds.play("snd_weaponpull", 0.3)
		for row in 5:
			if row == gap:
				continue
			var y := -60.0 + row * 30.0
			shoot(Vector2(side * 88.0, y), Vector2(-side * 135.0, 0))
		await wait(0.65)
