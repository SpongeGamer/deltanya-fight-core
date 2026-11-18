extends Node

# Срабатывает только после спуска с Мамаева Кургана, а не при каждом входе.
const DIALOGUE_SCENE = preload("res://scenes/prefabs/dialogue_system.tscn")
const PORTRAITS := {
	"Катя": "res://assets/portraits/test_kate.png",
	"Егор": "res://assets/portraits/test_egor.png",
}
const VOICES := {
	"Катя": "res://globals/sounds/voices/kate_voice.ogg",
	"Егор": "res://globals/sounds/voices/egor_voice.ogg",
	"Аня": "res://globals/sounds/sound_effects/snd_text.wav",
}

func _ready() -> void:
	SceneTransition.transition_finished.connect(_on_arrival, CONNECT_ONE_SHOT)

func _on_arrival() -> void:
	if not Global.get_flag("mk_forest_arrival_pending"):
		queue_free()
		return
	Global.clear_flag("mk_forest_arrival_pending")
	Global.set_flag("dialogue_in_progress")
	var player = get_tree().get_first_node_in_group("player")
	var kate := OverworldParty.get_companion("kate") as Companion
	var egor := OverworldParty.get_companion("egor") as Companion
	if not is_instance_valid(player):
		Global.clear_flag("dialogue_in_progress")
		queue_free()
		return
	player.can_move = false
	player.velocity = Vector2.ZERO
	# Свет еще закрыт: Катя и Егор уже в лесу, Аня появляется между ними.
	var center: Vector2 = player.global_position
	if is_instance_valid(kate):
		kate.stop_following()
		kate.global_position = center + Vector2(-72, 0)
		_face(kate, Vector2.RIGHT)
	if is_instance_valid(egor):
		egor.stop_following()
		egor.global_position = center + Vector2(72, 0)
		_face(egor, Vector2.LEFT)
	_face(player, Vector2.DOWN)
	await get_tree().create_timer(1.5).timeout

	var lines: Array[DE] = [
		_line("Катя", "Аня! Ты цела?"),
		_line("Аня", "Вроде да. Тут... грибы светятся."),
		_line("Егор", "И что-то мурчит."),
		_line("Катя", "Только не говори, что это грибы."),
		_line("Егор", "После поездов с лицами Я уже ничему не удивлюсь.")
	]
	if Global.get_flag("mk_nikita_stayed"):
		lines.append(_line("Аня", "Надеюсь, Никита справится. Пойдем дальше."))
	else:
		lines.append(_line("Аня", "Пойдем. Надо найти Никиту."))
	await _show_dialogue(lines, player, kate, egor)
	Global.set_flag("mk_forest_intro_done")
	Global.clear_flag("dialogue_in_progress")
	if is_instance_valid(player):
		player.can_move = true
		# Не срываем спутников с места сразу после диалога.
		var start_pos: Vector2 = player.global_position
		while is_inside_tree() and is_instance_valid(player) and player.global_position.distance_to(start_pos) < 2.0:
			await get_tree().process_frame
	if is_instance_valid(kate):
		kate.start_following()
	if is_instance_valid(egor):
		egor.start_following()
	queue_free()

func _face(body, direction: Vector2) -> void:
	if is_instance_valid(body) and direction.length_squared() > 0.0:
		body.last_direction = direction.normalized()
		body.call("_play_idle_animation")

func _line(speaker: String, text: String) -> DialogueText:
	var line := DialogueText.new()
	line.speaker_name = speaker
	line.text = text
	line.text_speed = 12.0 if speaker == "Егор" else 16.0
	line.text_volume_db = 10 if speaker == "Егор" or speaker == "Аня" else 4
	line.text_volume_pitch_min = 1.0
	line.text_volume_pitch_max = 1.0
	if PORTRAITS.has(speaker):
		line.speaker_img = load(PORTRAITS[speaker])
	if VOICES.has(speaker) and ResourceLoader.exists(VOICES[speaker]):
		line.text_sound = load(VOICES[speaker])
	return line

func _show_dialogue(lines: Array[DE], player, kate: Companion, egor: Companion) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	get_tree().current_scene.add_child(layer)
	var dialogue = DIALOGUE_SCENE.instantiate()
	dialogue.dialogue = lines
	dialogue.release_player_on_finish = false
	layer.add_child(dialogue)
	var previous := -1
	while is_instance_valid(dialogue) and dialogue.is_inside_tree():
		var index: int = dialogue.current_dialogue_item
		if index != previous and index < dialogue.dialogue.size():
			previous = index
			var entry: DE = dialogue.dialogue[index]
			if entry is DialogueText:
				# Катя и Егор остаются обращены к Ане; Аня смотрит на говорящего.
				if entry.speaker_name == "Катя" and is_instance_valid(kate):
					_face(player, kate.global_position - player.global_position)
				elif entry.speaker_name == "Егор" and is_instance_valid(egor):
					_face(player, egor.global_position - player.global_position)
				else:
					_face(player, Vector2.DOWN)
		await get_tree().process_frame
