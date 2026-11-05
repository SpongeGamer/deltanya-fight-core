extends "res://scripts/debug/test_enemy_encounter.gd"

const DEMO_BATTLE := preload("res://scenes/demo/demo_battle.gd")
const CANDY := preload("res://holdables/items/heal_candy.tres")

func _start_battle(battle_scene_path: String) -> void:
	if Global.battle_in_progress:
		return
	# Каждая попытка начинается в одинаковых условиях, без записи на диск.
	for key in Global.party:
		if PartyData.equipment.has(key):
			PartyData.equipment[key]["hp"] = -1
	for character in Global.characters:
		if is_instance_valid(character):
			character.current_hp = character.get_max_hp()
			character.alive = true
	Global.items.clear()
	for i in 6:
		var item: Item = CANDY.duplicate(true)
		if item.usePredicate:
			item.usePredicate.item = item
		Global.add_item(item)
	Global.tp = 0.0
	var overworld_music := Sounds.current_song
	var room := get_tree().current_scene
	var player := get_tree().get_first_node_in_group("player")
	if player:
		Global.player_return_position = player.global_position
		player.can_move = false
	Global.battle_in_progress = true
	PostProcessing.flash_to_black()
	await PostProcessing.fade_finished
	room.hide()
	room.get_node("DemoHint").visible = false
	var layer := CanvasLayer.new()
	layer.layer = 2
	room.add_child(layer)
	var bg := ColorRect.new()
	bg.color = Color.BLACK
	bg.size = Vector2(640, 480)
	layer.add_child(bg)
	var battle := (load(battle_scene_path) as PackedScene).instantiate()
	battle.set_script(DEMO_BATTLE)
	battle.add_to_group("battle")
	layer.add_child(battle)
	battle.tree_exiting.connect(func(): _return_to_room(room, layer, player, overworld_music))
	PostProcessing.flash_from_black()
	await PostProcessing.fade_finished

func _return_to_room(room: Node, layer: CanvasLayer, player: Node, overworld_music: String) -> void:
	Global.battle_in_progress = false
	layer.queue_free()
	if not is_instance_valid(room):
		return
	room.show()
	room.get_node("DemoHint").visible = true
	if is_instance_valid(player):
		player.can_move = true
		player.global_position = Global.player_return_position
	Global.player_return_position = Vector2.ZERO
	PostProcessing.flash_from_black()
	if overworld_music != "":
		await PostProcessing.fade_finished
		Sounds.set_music(overworld_music, 0.8)
