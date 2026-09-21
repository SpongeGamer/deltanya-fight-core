extends Node2D

func _ready() -> void:
	visible = false

func _start() -> void:
	visible = true
	Sounds.set_music("bad", 0.3)
	
	# 1. Слой для затемнения (фон) — слой 5
	var cl_bg := CanvasLayer.new()
	cl_bg.layer = 5 
	get_tree().current_scene.add_child(cl_bg)
	
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cl_bg.add_child(overlay)

	# 2. Слой для ТИТРОВ — слой 6 (должен быть ВЫШЕ слоя 5)
	var cl_text := CanvasLayer.new()
	cl_text.layer = 6
	get_tree().current_scene.add_child(cl_text)
	
	# Переносим сам узел титров (self) в этот новый слой
	get_parent().remove_child(self)
	cl_text.add_child(self)
	
	# Теперь затемняем только слой 5
	var fade := create_tween()
	fade.tween_property(overlay, "color:a", 1.0, 1.5)
	await fade.finished

	# Скроллим Credits вверх
	var total_height := _get_content_height()
	var start_y := 300.0
	var end_y   := -total_height - 100.0
	position.y  = start_y

	var scroll := create_tween()
	scroll.tween_property(self, "position:y", end_y, total_height * 0.055)
	await scroll.finished

	# Ждём и возвращаемся в главное меню
	await get_tree().create_timer(5.0).timeout
	get_tree().change_scene_to_file(
		"C:/Users/Gor/Documents/deltanya-fight-core/scenes/menus/title_screen/title_screen.tscn"
	)

func _get_content_height() -> float:
	var max_y := 0.0
	for child in get_children():
		if child is Control:
			max_y = maxf(max_y, child.position.y + child.size.y)
		elif child is Node2D:
			max_y = maxf(max_y, child.position.y)
	return max_y if max_y > 0.0 else 800.0
