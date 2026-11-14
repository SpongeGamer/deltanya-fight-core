extends "res://scripts/overworld/dialogue_area_2d.gd"

signal nikita_departed(result)
const DEPARTED_FLAG := "mk_nikita_left"

func _ready() -> void:
	super._ready()
	if Global.get_flag(DEPARTED_FLAG):
		dialogue.resize(1)

func _activate_dialogue() -> void:
	await super._activate_dialogue()
	if Global.get_flag(DEPARTED_FLAG):
		dialogue.resize(1)

# Вызывается сразу после реплики Никиты, до вопроса «Никита?».
func send_nikita_down() -> void:
	var bodies := get_tree().get_nodes_in_group("nikita_body")
	var nikita: Companion = null
	for body in bodies:
		if body is Companion:
			nikita = body
			break

	Global.set_flag(DEPARTED_FLAG)
	Global.party.erase("nikita")
	OverworldParty.companions.erase("nikita")
	if is_instance_valid(nikita):
		nikita.stop_following()
		nikita.move_speed = 180.0
		# Катсценное перемещение проходит через заграждение только для Никиты.
		var path: Array[Vector2] = [nikita.global_position + Vector2(0, 300)]
		nikita.start_cutscene_path(path)
		await nikita.cutscene_path_finished
		if is_instance_valid(nikita):
			nikita.queue_free()
	else:
		# Сигнал должен прийти после подключения обработчика диалога.
		await get_tree().process_frame
	nikita_departed.emit(true)
