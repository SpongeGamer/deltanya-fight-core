extends Area2D

const SPOTLIGHT = preload("res://scenes/blackworld/mk_spotlight.gd")
const DIALOGUE_SCENE = preload("res://scenes/prefabs/dialogue_system.tscn")
const FOREST_SCENE := "res://scenes/last_floor/last_boss_fight.tscn"
const DONE_FLAG := "mk_descent_done"
const STAYED_FLAG := "mk_nikita_stayed"

const PORTRAITS := {
	"Катя": "res://assets/portraits/test_kate.png",
	"Егор": "res://assets/portraits/test_egor.png",
	"Никита": "res://assets/portraits/test_nikita.png",
}
const VOICES := {
	"Катя": "res://globals/sounds/voices/kate_voice.ogg",
	"Егор": "res://globals/sounds/voices/egor_voice.ogg",
	"Никита": "res://globals/sounds/voices/nikita_voice.ogg",
	"Аня": "res://globals/sounds/voices/anne_voice.ogg",
}

var _started := false
var _player: Node2D
var _spotlight

func _process(_delta: float) -> void:
	if _started or Global.get_flag(DONE_FLAG) or not Global.get_flag("knyaz_cutscene_done"):
		return
	if Global.get_flag("dialogue_in_progress") or Global.battle_in_progress:
		return
	# Повторяем проверку пока игрок внутри: диалог мог идти при входе в область.
	for body in get_overlapping_bodies():
		if body.is_in_group("player") and body.can_move and not body.inventory_open:
			_started = true
			_player = body
			_run()
			return

func _run() -> void:
	_player.can_move = false
	Global.set_flag("dialogue_in_progress")
	for companion in get_tree().get_nodes_in_group("kate_body") + get_tree().get_nodes_in_group("egor_body") + get_tree().get_nodes_in_group("nikita_body"):
		if companion is Companion:
			companion.stop_following()
	_spotlight = SPOTLIGHT.new()
	get_tree().root.add_child(_spotlight)
	var darken: Tween = _spotlight.tween_light(0.33, 0.14, 0.92, 3.0)
	await darken.finished

	var with_nikita := Global.party.has("nikita")
	var opening: Array[DE] = [
		_line("", "[wave amp=8.0 freq=1.5]Спектакль закончился. Просьба покинуть зрительский зал.[/wave]"),
		_line("Катя", "Свет выключили. Совсем.")
	]
	if with_nikita:
		opening.append(_line("Егор", "И там кто-то идет. Это не зрители."))
		opening.append(_line("Никита", "Погодите."))
	else:
		opening.append(_line("Егор", "Значит, нам туда."))
		opening.append(_line("", "Вы смотрите в дыру. Оттуда тянет мокрой землей."))
	await _show_dialogue(opening)

	if with_nikita:
		var light: Tween = _spotlight.tween_light(0.27, 0.10, 0.96, 1.1)
		await light.finished
		var lantern_lines: Array[DE] = [
			_line("Никита", "Держи. Светите вниз. В глаза не свети!"),
			_line("Катя", "А ты?"),
			_line("Никита", "А я их задержу.")
		]
		await _show_dialogue(lantern_lines)
		await _nikita_stays()
		var goodbye: Array[DE] = [_line("Аня", "Никит..."), _line("Егор", "Не стой. Прыгай.")]
		await _show_dialogue(goodbye)

	# Сначала черный экран, затем штатный переход. Флаг только в момент ухода.
	var close_light: Tween = _spotlight.tween_light(0.0, 0.01, 1.0, 0.8)
	await close_light.finished
	Global.set_flag(DONE_FLAG)
	Global.clear_flag("dialogue_in_progress")
	SceneTransition.transition_finished.connect(_spotlight.reveal_after_transition, CONNECT_ONE_SHOT)
	SceneTransition.travel(FOREST_SCENE, "Spawnpoint", true)

func _nikita_stays() -> void:
	Global.set_flag(STAYED_FLAG)
	Global.party.erase("nikita")
	var nikita := OverworldParty.get_companion("nikita") as Companion
	OverworldParty.companions.erase("nikita")
	if not is_instance_valid(nikita):
		for body in get_tree().get_nodes_in_group("nikita_body"):
			if body is Companion:
				nikita = body
				break
	if is_instance_valid(nikita):
		nikita.stop_following()
		nikita.move_speed = 65.0
		var path: Array[Vector2] = [nikita.global_position + Vector2(0, -75)]
		nikita.start_cutscene_path(path)
		await nikita.cutscene_path_finished

func _line(speaker: String, text: String) -> DialogueText:
	var line := DialogueText.new()
	line.speaker_name = speaker
	line.text = text
	line.text_speed = 16.0
	if PORTRAITS.has(speaker):
		line.speaker_img = load(PORTRAITS[speaker])
	if VOICES.has(speaker) and ResourceLoader.exists(VOICES[speaker]):
		line.text_sound = load(VOICES[speaker])
	return line

func _show_dialogue(entries: Array[DE]) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	get_tree().current_scene.add_child(layer)
	var dialogue = DIALOGUE_SCENE.instantiate()
	dialogue.dialogue = entries
	dialogue.caller = self
	dialogue.release_player_on_finish = false
	layer.add_child(dialogue)
	await dialogue.tree_exited
