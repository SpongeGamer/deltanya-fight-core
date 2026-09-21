extends Pellet
# BEAM_BULLET — вертикальный луч сканера.
# Не наносит урон сам — patrol_zone проверяет overlap с soul вручную.
# is_returning управляется снаружи.

var is_returning := false

func _physics_process(_delta: float) -> void:
	pass  # движение только через patrol_zone.gd
