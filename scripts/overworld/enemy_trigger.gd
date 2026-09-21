extends Area2D

@export var battle_type: String = "slime"

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	var helper := get_tree().current_scene.get_node_or_null("HelperNode")
	if helper == null:
		push_error("EnemyTrigger: HelperNode not found on current scene")
		return
	match battle_type:
		"nikita":
			if helper.has_method("start_nikita_battle"):
				helper.start_nikita_battle()
			else:
				helper.start_slime_battle()
		"slime":
			helper.start_slime_battle()
		"starwalker":
			helper.start_starwalker_battle()
		"clippy":
			helper.start_clippy_battle()
		_:
			helper.start_slime_battle()
	queue_free()
