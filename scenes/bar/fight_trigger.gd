extends Node

var _overworld_music := ""
var _player: Node = null
var _canvas_layer: CanvasLayer = null
var _is_knyaz_battle := false

func _start_battle(battle_scene_path: String) -> void:
	if Global.battle_in_progress:
		return

	_overworld_music = Sounds.current_song
	_player = get_tree().get_first_node_in_group("player")

	if _player:
		Global.player_return_position = _player.global_position
		_player.can_move = false

	Global.battle_in_progress = true

	PostProcessing.flash_to_black()
	await PostProcessing.fade_finished

	get_tree().current_scene.hide()

	_canvas_layer = CanvasLayer.new()
	_canvas_layer.layer = 2
	get_tree().current_scene.add_child(_canvas_layer)

	var bg = ColorRect.new()
	bg.color = Color.BLACK
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.offset_right = 640
	bg.offset_bottom = 480
	bg.z_index = 0
	_canvas_layer.add_child(bg)

	var battle_scene = load(battle_scene_path).instantiate()
	battle_scene.add_to_group("battle")
	_canvas_layer.add_child(battle_scene)

	PostProcessing.flash_from_black()
	await PostProcessing.fade_finished

	print("fight_trigger: бой начался, is_knyaz=", _is_knyaz_battle)
	battle_scene.tree_exiting.connect(_on_battle_ended)


func _on_battle_ended() -> void:
	print("fight_trigger: _on_battle_ended вызван, is_knyaz=", _is_knyaz_battle)

	for i in Global.party.size():
		if i < Global.characters.size() and is_instance_valid(Global.characters[i]):
			PartyData.save_from_character(Global.party[i], Global.characters[i])

	Global.battle_in_progress = false

	await get_tree().process_frame

	if is_instance_valid(_canvas_layer):
		_canvas_layer.queue_free()

	get_tree().current_scene.show()

	if _player:
		_player.can_move = false
		_player.global_position = Global.player_return_position
		Global.player_return_position = Vector2.ZERO

	PostProcessing.flash_from_black()
	await PostProcessing.fade_finished

	if _overworld_music != "":
		Sounds.set_music(_overworld_music, 0.8)

	print("fight_trigger: проверяем катсцену, is_knyaz=", _is_knyaz_battle, " cutscene_done=", Global.get_flag("knyaz_cutscene_done"))

	if _is_knyaz_battle and not Global.get_flag("knyaz_cutscene_done"):
		var bar := get_tree().current_scene
		print("fight_trigger: current_scene=", bar.name, " has_method=", bar.has_method("start_post_knyaz_cutscene"))
		if bar.has_method("start_post_knyaz_cutscene"):
			bar.start_post_knyaz_cutscene(_player)
		else:
			if _player:
				_player.can_move = true
	else:
		if _player:
			_player.can_move = true

	_is_knyaz_battle = false


func start_knyaz_battle() -> void:
	print("fight_trigger: start_knyaz_battle вызван")
	Global.monsters.clear()
	Global.monsters.append(preload("res://fighters/monsters/knyaz/knyaz.tscn").instantiate())
	Global.load_party_characters()
	Global.set_flag("knyaz_battle_done")
	_is_knyaz_battle = true
	_start_battle("res://scenes/battle/battle.tscn")
