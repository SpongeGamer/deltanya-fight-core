extends "res://scripts/overworld/dialogue_area_2d.gd"

# В бар можно попасть и до разговора у нижней баррикады.
@export var dialogue_before_nikita_leaves: Array[DE]

func _ready() -> void:
	super._ready()
	if not Global.get_flag("mk_nikita_left") and not dialogue_before_nikita_leaves.is_empty():
		dialogue = dialogue_before_nikita_leaves.duplicate()
