extends StarwalkerAttack
## Три силуэта: золотой — настоящий. Пунктир фиксирует выстрел до залпа.
const IDLE := preload("res://fighters/monsters/starwalker/starwalker_idle.png")
const POSITIONS := [Vector2(-105, -8), Vector2(0, -105), Vector2(105, -8)]

func get_duration() -> float:
	return 9.0 + (0.85 if chicken_reaction else 0.0)

func run() -> void:
	await wait(0.4)
	var previous := -1
	for round in 4:
		var real := randi_range(0, 2)
		if real == previous:
			real = (real + 1 + randi_range(0, 1)) % 3
		previous = real
		var ghosts: Array[Sprite2D] = []
		for i in 3:
			var ghost := Sprite2D.new()
			ghost.texture = IDLE
			ghost.hframes = 5
			ghost.frame = (round + i) % 5
			ghost.position = POSITIONS[i]
			ghost.scale = Vector2(0.45, 0.45)
			ghost.modulate = Color(0.5, 0.55, 0.7, 0.0)
			over.add_child(ghost)
			ghost.create_tween().tween_property(ghost, "modulate:a", 0.5, 0.25)
			ghosts.append(ghost)
		await wait(0.45)
		var shooter := ghosts[real]
		shooter.modulate = GOLD
		shooter.create_tween().tween_property(shooter, "scale", Vector2(0.53, 0.53), 0.25).set_trans(Tween.TRANS_BACK)
		var origin: Vector2 = POSITIONS[real]
		var target := soul_pos()
		var dir := (target - origin).normalized()
		# Направление фиксируется в начале предупреждения, а не после него.
		for offset in [-0.17, 0.0, 0.17]:
			warn_line(origin, origin + dir.rotated(offset) * 260.0, 0.75, GOLD)
		await wait(0.78)
		pulse()
		Sounds.play("snd_weaponpull", 0.35)
		for offset in [-0.17, 0.0, 0.17]:
			shoot(origin, dir.rotated(offset) * 115.0)
		for ghost in ghosts:
			ghost.create_tween().tween_property(ghost, "modulate:a", 0.0, 0.3)
		await wait(0.48)
		for ghost in ghosts:
			ghost.queue_free()
