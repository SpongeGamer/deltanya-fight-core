extends Area2D

const SPOTLIGHT = preload("res://scenes/blackworld/mk_spotlight.gd")
const DIALOGUE_SCENE = preload("res://scenes/prefabs/dialogue_system.tscn")
const FOREST_SCENE := "res://scenes/last_floor/last_boss_fight.tscn"
const DONE_FLAG := "mk_descent_done"
const STAYED_FLAG := "mk_nikita_stayed"
const FLASHLIGHT = preload("res://scenes/blackworld/res/mk_flashlight.png")

const PORTRAITS := {
	"Катя": "res://assets/portraits/test_kate.png",
	"Егор": "res://assets/portraits/test_egor.png",
	"Никита": "res://assets/portraits/test_nikita.png",
}
const VOICES := {
	"Катя": "res://globals/sounds/voices/kate_voice.ogg",
	"Егор": "res://globals/sounds/voices/egor_voice.ogg",
	"Никита": "res://globals/sounds/voices/nikita_voice.ogg",
	"Аня": "res://globals/sounds/sound_effects/snd_text.wav",
	"": "res://globals/sounds/sound_effects/snd_text.wav",
}

var _started := false
var _player
var _spotlight
var _approaching := false
var _away_from_hole := Vector2.LEFT
var _hole_position := Vector2.ZERO
var _lantern: Sprite2D

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
	var hole := get_parent().get_node_or_null("Hole") as Node2D
	_hole_position = hole.global_position if is_instance_valid(hole) else global_position
	_away_from_hole = (_player.global_position - _hole_position).normalized()
	if _away_from_hole == Vector2.ZERO:
		_away_from_hole = Vector2.LEFT
	for companion in get_tree().get_nodes_in_group("kate_body") + get_tree().get_nodes_in_group("egor_body") + get_tree().get_nodes_in_group("nikita_body"):
		if companion is Companion:
			companion.stop_following()
	_spotlight = SPOTLIGHT.new()
	get_tree().root.add_child(_spotlight)
	var darken: Tween = _spotlight.tween_light(0.33, 0.14, 0.92, 3.0)
	# Отряд не замирает на границе триггера: Аня ведет его к краю дыры.
	_approach_hole()
	await darken.finished
	while _approaching and is_inside_tree():
		await get_tree().process_frame

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
		_show_nikita_lantern()
		var light: Tween = _spotlight.tween_light(0.27, 0.10, 0.96, 1.1)
		await light.finished
		var handoff: Array[DE] = [_line("Никита", "Держи. Светите вниз. В глаза не свети!")]
		await _show_dialogue(handoff)
		await _pass_lantern_to_anya()
		var lantern_lines: Array[DE] = [_line("Катя", "А ты?"), _line("Никита", "А я их задержу.")]
		await _show_dialogue(lantern_lines)
		await _nikita_stays()
		var goodbye: Array[DE] = [_line("Аня", "Никит..."), _line("Егор", "Не стой. Прыгай.")]
		await _show_dialogue(goodbye)

	# Персонажи по очереди подходят к центру дыры и исчезают в ней.
	await _enter_hole()
	# Сначала черный экран, затем штатный переход. Флаг только в момент ухода.
	var close_light: Tween = _spotlight.tween_light(0.0, 0.01, 1.0, 0.8)
	await close_light.finished
	Global.set_flag(DONE_FLAG)
	Global.set_flag("mk_forest_arrival_pending")
	Global.clear_flag("dialogue_in_progress")
	SceneTransition.transition_finished.connect(_spotlight.reveal_after_transition, CONNECT_ONE_SHOT)
	SceneTransition.travel(FOREST_SCENE, "Spawnpoint", true)

# Расставляем героев возле ближнего края дыры, а не возле центра триггера.
func _approach_hole() -> void:
	_approaching = true
	var dir := _away_from_hole
	var side := Vector2(-dir.y, dir.x)
	# Размер изображения дыры примерно 139 x 89 в мировых координатах.
	var edge_distance: float = 1.0 / sqrt(pow(dir.x / 69.5, 2.0) + pow(dir.y / 44.4, 2.0))
	var front := _hole_position + dir * (edge_distance + 8.0)
	var player_done := {"value": false}
	_player.cutscene_path_finished.connect(func(): player_done["value"] = true, CONNECT_ONE_SHOT)
	var player_path: Array[Vector2] = [front]
	_player.start_cutscene_path(player_path)
	var moving: Array[Companion] = []
	var keys := ["kate", "egor", "nikita"]
	var offsets := [dir * 55.0 + side * 40.0, dir * 55.0 - side * 40.0, dir * 115.0]
	for i in keys.size():
		var member := OverworldParty.get_companion(keys[i]) as Companion
		if not is_instance_valid(member):
			continue
		await get_tree().create_timer(0.16).timeout
		var path: Array[Vector2] = [front + offsets[i]]
		member.start_cutscene_path(path)
		moving.append(member)
	while is_inside_tree():
		var still_moving: bool = not player_done["value"]
		for member in moving:
			if is_instance_valid(member) and member.in_cutscene:
				still_moving = true
		if not still_moving:
			break
		await get_tree().process_frame
	# Все смотрят на дыру. Никто не переставляется мгновенно.
	if is_instance_valid(_player):
		_player.last_direction = -dir
		_player.call("_play_idle_animation")
	for member in moving:
		if is_instance_valid(member):
			member.last_direction = -dir
			member.call("_play_idle_animation")
	_approaching = false

func _show_nikita_lantern() -> void:
	var nikita := OverworldParty.get_companion("nikita") as Companion
	if not is_instance_valid(nikita):
		return
	_lantern = Sprite2D.new()
	_lantern.texture = FLASHLIGHT
	_lantern.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_lantern.z_index = 4090
	get_tree().current_scene.add_child(_lantern)
	_lantern.global_position = nikita.global_position + Vector2(0, -50)

func _pass_lantern_to_anya() -> void:
	if not is_instance_valid(_lantern) or not is_instance_valid(_player):
		return
	var start_position: Vector2 = _lantern.global_position
	var destination: Vector2 = _player.global_position + Vector2(0, -50)
	var handoff := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	handoff.tween_method(func(t: float):
		if is_instance_valid(_lantern):
			_lantern.global_position = start_position.lerp(destination, t) + Vector2(0, -22.0 * sin(PI * t)), 0.0, 1.0, 0.8)
	await handoff.finished
	_lantern.reparent(_player)
	_lantern.z_index = 5
	_lantern.position = Vector2(0, -50)

func _enter_hole() -> void:
	# Катя с фонарем первой, затем Егор и Аня. Никита уже отошел.
	for key in ["kate", "egor"]:
		var member := OverworldParty.get_companion(key) as Companion
		if not is_instance_valid(member):
			continue
		var path: Array[Vector2] = [_hole_position]
		member.start_cutscene_path(path)
		await member.cutscene_path_finished
		var fade := create_tween()
		fade.tween_property(member, "modulate:a", 0.0, 0.3)
		await fade.finished
	var player_path: Array[Vector2] = [_hole_position]
	_player.start_cutscene_path(player_path)
	await _player.cutscene_path_finished
	var fade := create_tween()
	fade.tween_property(_player, "modulate:a", 0.0, 0.3)
	await fade.finished

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
		var path: Array[Vector2] = [nikita.global_position + _away_from_hole * 75.0]
		nikita.start_cutscene_path(path)
		await nikita.cutscene_path_finished

func _line(speaker: String, text: String) -> DialogueText:
	var line := DialogueText.new()
	line.speaker_name = speaker
	line.text = text
	line.text_speed = 12.0 if speaker == "Егор" else 16.0
	line.text_volume_db = 10 if speaker == "Егор" or speaker == "Аня" or speaker == "" else 4
	line.text_volume_pitch_min = 1.0
	line.text_volume_pitch_max = 1.0
	if PORTRAITS.has(speaker):
		line.speaker_img = load(PORTRAITS[speaker])
	if VOICES.has(speaker) and ResourceLoader.exists(VOICES[speaker]):
		line.text_sound = load(VOICES[speaker])
	return line

func _turn_to(body, target: Vector2) -> void:
	if not is_instance_valid(body):
		return
	var direction: Vector2 = target - body.global_position
	if direction.length_squared() < 1.0:
		return
	body.last_direction = direction.normalized()
	body.call("_play_idle_animation")

func _face_speaker(speaker: String) -> void:
	var members: Array = [_player]
	for key in ["kate", "egor", "nikita"]:
		var member = OverworldParty.get_companion(key)
		if is_instance_valid(member):
			members.append(member)
	var actor = _player if speaker == "Аня" else null
	var key_by_name := {"Катя": "kate", "Егор": "egor", "Никита": "nikita"}
	if key_by_name.has(speaker):
		actor = OverworldParty.get_companion(key_by_name[speaker])
	if not is_instance_valid(actor):
		for member in members:
			_turn_to(member, _hole_position)
		return
	var center := Vector2.ZERO
	var count := 0
	for member in members:
		if member != actor and is_instance_valid(member):
			_turn_to(member, actor.global_position)
			center += member.global_position
			count += 1
	if count > 0:
		_turn_to(actor, center / float(count))

func _show_dialogue(entries: Array[DE]) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	get_tree().current_scene.add_child(layer)
	var dialogue = DIALOGUE_SCENE.instantiate()
	dialogue.dialogue = entries
	dialogue.caller = self
	dialogue.release_player_on_finish = false
	layer.add_child(dialogue)
	var previous_index := -1
	while is_instance_valid(dialogue) and dialogue.is_inside_tree():
		var index: int = dialogue.current_dialogue_item
		if index != previous_index and index < dialogue.dialogue.size():
			previous_index = index
			var entry: DE = dialogue.dialogue[index]
			if entry is DialogueText:
				_face_speaker(entry.speaker_name)
		await get_tree().process_frame
