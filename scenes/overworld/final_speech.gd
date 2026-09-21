extends Node2D

@export var dialogue : Array[DE] = []

func _ready() -> void:
	Global.is_dark_world = false
	Sounds.set_music("home", 0.0)
	Global.location_name = "Финальный диалог"
	await get_tree().create_timer(5.0).timeout
	call_deferred("_launch")

func _launch() -> void:
	if dialogue.is_empty():
		push_warning("final_speech: dialogue не задан в инспекторе")
		return
	var cl := CanvasLayer.new()
	cl.layer = 10
	add_child(cl)
	var dlg = load("res://scenes/prefabs/dialogue_system.tscn").instantiate()
	dlg.dialogue = dialogue
	dlg.caller   = self
	cl.add_child(dlg)
