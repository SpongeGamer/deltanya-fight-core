extends Node

signal transition_finished

var _traveling           : bool = false
var _spawn_player_on_load := true

func _ready() -> void:
	get_tree().scene_changed.connect(_on_scene_loaded)

# Оставляем 4 параметра как было
func travel(scene_path: String, spawn_point: String = "", set_dark_world: bool = Global.is_dark_world, spawn_player: bool = true) -> void:
	if _traveling:
		return
	_traveling = true
	_spawn_player_on_load = spawn_player

	var player: Node2D = get_tree().get_first_node_in_group("player")
	if player:
		player.can_move = false

	PostProcessing.fade_out(0.2)
	await PostProcessing.fade_finished

	Global.is_dark_world = set_dark_world
	Global.player_spawn_point = spawn_point
	get_tree().change_scene_to_file(scene_path)

func _on_scene_loaded(_scene: Node = null) -> void:
	await get_tree().process_frame

	if not _traveling:
		OverworldParty.spawn_companions()
		return

	if _spawn_player_on_load:
		var player: Node2D = OverworldParty.spawn_player_if_needed()
		if player:
			# ПРИОРИТЕТ: сначала сохранённая позиция (если не Zero)
			if Global.player_return_position != Vector2.ZERO:
				player.global_position = Global.player_return_position
				print("✅ Spawned at saved position: ", Global.player_return_position)
				Global.player_return_position = Vector2.ZERO  # Сбрасываем после использования
			# Затем спавн-поинт
			elif Global.player_spawn_point != "":
				var spawn: Node2D = get_tree().current_scene.find_child(
					Global.player_spawn_point, true, false
				)
				if spawn:
					player.global_position = spawn.global_position
					print("✅ Spawned at spawn point: ", Global.player_spawn_point)
				else:
					print("❌ Spawn point NOT found: ", Global.player_spawn_point)
			else:
				print("❌ No spawn point or saved position!")
			
			print("Final player position: ", player.global_position)
			player.can_move = true
		OverworldParty.spawn_companions()

	PostProcessing.fade_in(0.2)
	await PostProcessing.fade_finished
	_traveling = false
	transition_finished.emit()
