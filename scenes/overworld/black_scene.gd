extends Node2D

func _ready() -> void:
	Global.location_name = "???"
	Sounds.set_music("darkness")

# ── Пати ───────────────────────────────────────────────────────────────────────
func _add_party_members() -> void:
	if "kate" not in Global.party:
		Global.party.append("kate")
	if "egor" not in Global.party:
		Global.party.append("egor")
	# Подгружаем ноды персонажей чтобы PartyData подхватил новый состав
	Global.load_party_characters(false)

# ── Диалог ─────────────────────────────────────────────────────────────────────
func _launch_dialogue(p_dialogue: Array[DE]) -> void:
	var DialogueScene := load("res://scenes/prefabs/dialogue_system.tscn") as PackedScene
	if DialogueScene == null:
		push_error("BlackScene: не найден dialogue_system.tscn")
		return
	var cl := CanvasLayer.new()
	cl.layer = 20
	add_child(cl)
	var dlg = DialogueScene.instantiate()
	dlg.dialogue = p_dialogue.duplicate()
	cl.add_child(dlg)
	await cl.tree_exited


func _get_or_create_dark_layer() -> CanvasLayer:
	for child in get_children():
		if child is CanvasLayer and child.name == "DarknessLayer":
			return child
	
	var layer := CanvasLayer.new()
	layer.name = "DarknessLayer"
	layer.layer = 8
	layer.visible = true
	
	var rect := ColorRect.new()
	rect.color = Color.BLACK
	rect.anchor_right = 1.0
	rect.anchor_bottom = 1.0
	rect.modulate = Color(1, 1, 1, 0)  # Начинаем прозрачным
	
	layer.add_child(rect)
	add_child(layer)
	# Плавное появление
	var tween := create_tween()
	tween.tween_property(rect, "modulate:a", 1.0, 3.0)  # За 1 секунду до полной непрозрачности
	
	return layer
