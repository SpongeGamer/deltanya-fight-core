extends "res://scripts/overworld/travel_trigger.gd"

func _travel() -> void:
	if not Global.get_flag("knyaz_cutscene_done"):
		return
	if not Global.get_flag("mk_descent_done") or Global.get_flag("dialogue_in_progress"):
		return
	super._travel()
