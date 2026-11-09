extends "res://scripts/overworld/dialogue_area_2d.gd"

# На первом подходе камера показывает памятник, потом возвращается к отряду.
func _activate_dialogue() -> void:
	if _is_active or has_activated_already or Global.get_flag(flag_key):
		return
	if not is_instance_valid(player_node) or not player_node.can_move or player_node.get("inventory_open"):
		return
	if Global.get_flag("dialogue_in_progress"):
		return
	var camera := CameraController.instance
	var landmark := get_tree().current_scene.get_node_or_null("KurganBG/Background") as Node2D
	if not is_instance_valid(camera) or not is_instance_valid(landmark):
		super._activate_dialogue()
		return

	_is_active = true
	Global.set_flag("dialogue_in_progress")
	player_node.can_move = false
	player_node.velocity = Vector2.ZERO
	var stopped: Array[Companion] = []
	for key in Global.party:
		for companion in get_tree().get_nodes_in_group(key + "_body"):
			if companion is Companion and companion.following:
				companion.stop_following()
				companion.is_moving = false
				stopped.append(companion)

	await camera.pan_to(landmark.global_position + Vector2(110, 0), 3.0)
	await get_tree().create_timer(0.8).timeout
	await camera.pan_to_node(player_node, 2.5, true)

	player_node.position_history.clear()
	for companion in stopped:
		if is_instance_valid(companion):
			companion.position_history.clear()
			companion.start_following()
	Global.clear_flag("dialogue_in_progress")
	_is_active = false
	player_node.can_move = true
	super._activate_dialogue()
