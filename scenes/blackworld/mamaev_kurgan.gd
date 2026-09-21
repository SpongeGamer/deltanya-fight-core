extends Node2D

func _ready() -> void:
	Global.is_dark_world = true
	Sounds.set_music("mk", 0.5)
	Global.location_name = "Мамаев Курган"

	if Global.get_flag("knyaz_cutscene_done"):
		_on_knyaz_defeated()
	else:
		_on_knyaz_not_yet()


func _on_knyaz_not_yet() -> void:
	var barricade := get_node_or_null("Interactable/WorkersBarricade")
	if barricade and barricade.has_method("enable"):
		barricade.enable()

	var signs := get_node_or_null("Tablichki")
	if signs:
		signs.visible = false


func _on_knyaz_defeated() -> void:
	var barricade := get_node_or_null("Interactable/WorkersBarricade")
	if barricade and barricade.has_method("disable"):
		barricade.disable()

	var signs := get_node_or_null("Tablichki")
	if signs:
		signs.visible = true


func random_npc_vanish() -> void:
	var npc := get_node_or_null("Dialogues/Dialogue2/RandomNPC")
	if npc and is_instance_valid(npc):
		Sounds.play("gaster_fade")
		var fade := get_tree().create_tween()
		fade.tween_property(npc, "modulate:a", 0.0, 1.2)
		await fade.finished
		npc.queue_free()
