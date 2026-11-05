extends GenericPellet
## Цветные снаряды перепроверяют душу, пока она находится внутри.
## Сигнал body_entered сохраняется для обычного первого попадания.
func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if not visible or is_queued_for_deletion():
		return
	for body in get_overlapping_bodies():
		if body is Soul:
			_on_body_entered(body)
