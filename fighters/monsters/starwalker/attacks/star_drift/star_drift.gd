extends StarwalkerAttack
## Звёздные дорожки: каждая группа мягко изгибается при полёте.

func get_duration() -> float:
	return 9.8 + (0.85 if chicken_reaction else 0.0)

func run() -> void:
	await wait(0.5)
	for wave in 4:
		var side := 1.0 if wave % 2 == 0 else -1.0
		var center_y: float = [-30.0, 27.0, -18.0, 20.0][wave]
		var curve := 0.55 * side * (1.0 if wave % 2 == 0 else -1.0)
		warn_line(Vector2(side * 70.0, center_y), Vector2(side * 42.0, center_y), 0.65, BLUE)
		await wait(0.67)
		pulse()
		Sounds.play("snd_power", 0.25)
		for i in 6:
			var shot := shoot(Vector2(side * 88.0, center_y), Vector2(-side * 105.0, (i - 2.5) * 2.0), curve)
			shot.lifetime = 3.0
			await wait(0.15)
		await wait(0.33)
