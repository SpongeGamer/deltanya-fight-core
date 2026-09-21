extends Node

func _start_battle(battle_scene_path: String) -> void:
	if Global.battle_in_progress:
		return

	var overworld_music := Sounds.current_song

	var player = get_tree().get_first_node_in_group("player")
	if player:
		# Сохраняем позицию ДО того, как заблокируем игрока
		Global.player_return_position = player.global_position
		player.can_move = false

	# Ставим флаг ДО await, чтобы dialogue_system не восстановил can_move раньше времени
	Global.battle_in_progress = true

	# Вспых при входе в бой
	PostProcessing.flash_to_black()
	await PostProcessing.fade_finished

	# Скрываем оверворлд — убирает коллизии стен из физического мира
	get_tree().current_scene.hide()

	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 2
	get_tree().current_scene.add_child(canvas_layer)

	var bg = ColorRect.new()
	bg.color = Color.BLACK
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.offset_right = 640
	bg.offset_bottom = 480
	bg.z_index = 0
	canvas_layer.add_child(bg)

	var battle_scene = load(battle_scene_path).instantiate()
	battle_scene.add_to_group("battle")
	canvas_layer.add_child(battle_scene)

	# Вспых при загрузке сцены боя
	PostProcessing.flash_from_black()
	await PostProcessing.fade_finished

	battle_scene.tree_exiting.connect(func():
		# Сохраняем ХП персонажей перед тем как сцена боя удалится
		for i in Global.party.size():
			if i < Global.characters.size() and is_instance_valid(Global.characters[i]):
				PartyData.save_from_character(Global.party[i], Global.characters[i])

		Global.battle_in_progress = false
		canvas_layer.queue_free()
		get_tree().current_scene.show()

		if player:
			player.can_move = true
			player.global_position = Global.player_return_position

		# Вспых при возврате в оверворлд
		PostProcessing.flash_from_black()
		await PostProcessing.fade_finished

		# Возобновляем музыку оверворлда
		if overworld_music != "":
			Sounds.set_music(overworld_music, 0.8)
	)

func start_slime_battle() -> void:
	Global.monsters.clear()
	Global.monsters.append(preload("res://fighters/monsters/slime/slime.tscn").instantiate() as Monster)
	Global.load_party_characters()
	_start_battle("res://scenes/battle/battle.tscn")

func start_starwalker_battle() -> void:
	Global.monsters.clear()
	Global.monsters.append(preload("res://fighters/monsters/starwalker/starwalker.tscn").instantiate())
	Global.load_party_characters()
	_start_battle("res://scenes/battle/battle.tscn")

func start_clippy_battle() -> void:
	Global.monsters.clear()
	Global.monsters.append(preload("res://fighters/monsters/clippy/clippy.tscn").instantiate())
	Global.load_party_characters()
	_start_battle("res://scenes/battle/battle.tscn")


func start_nikita_battle() -> void:
	Global.monsters.clear()
	Global.monsters.append(preload("res://fighters/monsters/nikita/nikita.tscn").instantiate())
	Global.load_party_characters()
	_start_battle("res://scenes/battle/battle.tscn")

func start_captcha_battle() -> void:
	Global.monsters.clear()
	Global.monsters.append(preload("res://fighters/monsters/captcha/captcha.tscn").instantiate())
	Global.load_party_characters()
	_start_battle("res://scenes/battle/battle.tscn")

func start_shroompal_battle() -> void:
	Global.monsters.clear()
	Global.monsters.append(preload("res://fighters/monsters/shroompals/shroompal/shroompal.tscn").instantiate())
	Global.load_party_characters()
	_start_battle("res://scenes/battle/battle.tscn")

func start_knyaz_battle() -> void:
	Global.monsters.clear()
	Global.monsters.append(preload("res://fighters/monsters/knyaz/knyaz.tscn").instantiate())
	Global.load_party_characters()
	_start_battle("res://scenes/battle/battle.tscn")

func start_gorshok_battle() -> void:
	Global.monsters.clear()
	Global.monsters.append(preload("res://fighters/monsters/gorshok/gorshok.tscn").instantiate())
	Global.load_party_characters()
	_start_battle("res://scenes/battle/battle.tscn")

func start_gateguard_battle() -> void:
	Global.monsters.clear()
	Global.monsters.append(preload("res://fighters/monsters/gateguard/gate_guard.tscn").instantiate())
	Global.load_party_characters()
	_start_battle("res://scenes/battle/battle.tscn")

func start_serega_battle() -> void:
	Global.monsters.clear()
	Global.monsters.append(preload("res://fighters/monsters/serega/seroga.tscn").instantiate())
	Global.load_party_characters()
	_start_battle("res://scenes/battle/battle.tscn")
