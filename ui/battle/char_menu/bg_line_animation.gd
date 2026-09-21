extends Node2D

var initial_positions := PackedVector2Array()
var final_positions := PackedVector2Array()

func _ready() -> void:
	for i: int in get_child_count():
		var panel: Panel = get_child(i)
		var direction := remap(int(i < 2), 0, 1, -1, 1)
		initial_positions.append(panel.position)
		final_positions.append(panel.position + Vector2(30.0, 0.0) * direction)
		if i % 2 == 1:
			panel.position.x = (panel.position.x + final_positions[i].x * 2.0) / 2.0
			panel.modulate.a = 0.5
			var tween := get_tree().create_tween().set_parallel(true)
			tween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_LINEAR)
			tween.tween_property(panel, "position", final_positions[i], 0.5)
			tween.tween_property(panel, "modulate", Color.TRANSPARENT, 0.5)

func _process(_delta: float) -> void:
	for i: int in get_child_count():
		var panel: Panel = get_child(i)
		if panel.position != initial_positions[i]:
			if panel.position == final_positions[i]:
				panel.position = initial_positions[i]
				panel.modulate.a = 1.0
			continue
		var tween := get_tree().create_tween().set_parallel(true)
		tween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		tween.tween_property(panel, "position", final_positions[i], 1.0)
		tween.tween_property(panel, "modulate", Color.TRANSPARENT, 1.0)
