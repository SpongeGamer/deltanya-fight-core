extends "res://scenes/battle/battle.gd"

# Только для демо: поражение возвращает в комнату вместо загрузки сохранения.
func hurt(p_damage: int) -> void:
	if _is_ending:
		return
	var alive_characters: Array[Character] = []
	for character: Character in Global.characters:
		if character.alive:
			alive_characters.append(character)
	if alive_characters.is_empty():
		return
	alive_characters.pick_random().hurt(p_damage)
	if not Global.characters.any(func(c): return c.alive) and not _is_ending:
		_is_ending = true
		await get_tree().create_timer(1.2).timeout
		Global.battle_in_progress = false
		Sounds.fade_out_current(0.35)
		PostProcessing.fade_out()
		await PostProcessing.fade_finished
		queue_free()
