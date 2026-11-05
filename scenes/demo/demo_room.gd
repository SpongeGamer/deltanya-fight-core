extends Node2D

# Самостоятельная копия Testing Room: не открывает сюжетные локации и не сохраняет игру.
func _enter_tree() -> void:
	Global.is_dark_world = true
	Global.party.assign(["anne", "kate", "egor"])
	Global.player_return_position = Vector2.ZERO

func _ready() -> void:
	Global.location_name = "Демо: бои"
	if Sounds.music.has("field"):
		Sounds.set_music("field", 0.3)
	$AnnePlayer.position = Vector2(-320, 20)
	# Пустые проходы исходной комнаты используем для оставшихся боев.
	$EnemyNodes/ShroomFight.position.x = 55
	$EnemyNodes/KnyazFight.position.x = 184
	var captions := ["НИКИТА", "ЗВЕЗДОХОД", "СКРЕПОЧКА", "КАПЧА", "КОТОГРИБ", "КНЯЗЬ"]
	for i in captions.size():
		var label: Label = $RoomLabels.get_child(i)
		label.text = captions[i]
		var center_x: float = (label.offset_left + label.offset_right) * 0.5
		label.offset_left = center_x - 58
		label.offset_right = center_x + 58
		label.offset_top = -53
		label.offset_bottom = -25
		label.label_settings = label.label_settings.duplicate()
		label.label_settings.font = load("res://fonts/8bitoperator Cyrillic Extension.otf")
		label.label_settings.font_size = 17
		label.z_index = 1000
	_make_hint()

func _make_hint() -> void:
	var layer := CanvasLayer.new()
	layer.name = "DemoHint"
	layer.layer = 1
	add_child(layer)
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.02, 0.07, 0.85)
	bg.position = Vector2(8, 8)
	bg.size = Vector2(624, 52)
	layer.add_child(bg)
	var label := Label.new()
	label.position = Vector2(16, 10)
	label.size = Vector2(608, 48)
	label.add_theme_font_override("font", load("res://fonts/8bitoperator Cyrillic Extension.otf"))
	label.add_theme_font_size_override("font_size", 17)
	label.text = "ДЕМО БОЕВ  •  Стрелки / WASD — движение\nПодойди к проходу: стрелки — выбор, Z — подтвердить"
	layer.add_child(label)
