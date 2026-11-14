extends "res://scripts/overworld/dialogue_area_2d.gd"

# Камера летит по маршруту одновременно с диалогом, а не до него.
func _activate_dialogue() -> void:
	if _is_active or has_activated_already or (flag_key != "" and Global.get_flag(flag_key)):
		return
	if not is_instance_valid(player_node) or not player_node.can_move or player_node.get("inventory_open"):
		return
	if Global.get_flag("dialogue_in_progress"):
		return

	var camera = CameraController.instance
	var scene := get_tree().current_scene
	var worker1 := scene.get_node_or_null("Interactable/WorkersBarricade/Worker1") as Node2D
	var worker3 := scene.get_node_or_null("Interactable/WorkersBarricade/Worker3") as Node2D
	var arrow := scene.get_node_or_null("Interactable/Arrow") as Node2D
	var lower_worker := scene.get_node_or_null("Interactable/WorkersBarricade/Worker7") as Node2D
	if not is_instance_valid(camera) or not worker1 or not worker3 or not arrow or not lower_worker:
		await super._activate_dialogue()
		return

	var stopped: Array[Companion] = []
	for member in Global.party:
		for body in get_tree().get_nodes_in_group(member + "_body"):
			if body is Companion and body.following:
				body.stop_following()
				body.is_moving = false
				stopped.append(body)
	player_node.velocity = Vector2.ZERO
	camera.stop_follow()
	var flyover := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	flyover.tween_property(camera, "global_position", (worker1.global_position + worker3.global_position) * 0.5, 3.5)
	flyover.tween_interval(0.5)
	flyover.tween_property(camera, "global_position", arrow.global_position, 4.5)
	flyover.tween_interval(0.5)
	flyover.tween_property(camera, "global_position", lower_worker.global_position + Vector2(0, -40), 4.0)

	await super._activate_dialogue()
	if not is_inside_tree():
		return
	if flyover.is_running():
		flyover.kill()
	if is_instance_valid(player_node) and is_instance_valid(camera):
		# Блокируем управление на обратный путь камеры.
		player_node.can_move = false
		Global.set_flag("dialogue_in_progress")
		await camera.pan_to_node(player_node, 1.8, true)
		if is_instance_valid(player_node):
			player_node.position_history.clear()
			player_node.can_move = true
		Global.clear_flag("dialogue_in_progress")
	for body in stopped:
		if is_instance_valid(body):
			body.position_history.clear()
			body.start_following()
