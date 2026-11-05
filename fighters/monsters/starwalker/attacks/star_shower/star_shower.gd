extends StarwalkerAttack
## Звёздный дождь: показ колонок, затем залп с широким проходом.

func get_duration() -> float:
	return 8.8 + (0.85 if chicken_reaction else 0.0)

func run() -> void:
	await wait(0.5)
	var previous_gap := -1
	for wave in 5:
		var gap := randi_range(0, 5)
		if gap == previous_gap:
			gap = (gap + 2) % 6
		previous_gap = gap
		for lane in 7:
			if lane == gap or lane == gap + 1:
				continue
			var x := -60.0 + lane * 20.0
			warn_line(Vector2(x, -70), Vector2(x, 70), 0.7)
		await wait(0.72)
		pulse()
		Sounds.play("snd_power", 0.25)
		for lane in 7:
			if lane == gap or lane == gap + 1:
				continue
			var x := -60.0 + lane * 20.0
			shoot(Vector2(x, -88), Vector2(0, 125.0))
		await wait(0.62)
