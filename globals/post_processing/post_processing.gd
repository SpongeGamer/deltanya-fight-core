extends Node2D

signal fade_finished

# Стандартный fade — затемняет экран до чёрного
func fade_out(duration := 0.2) -> void:
	var tween := _make_tween()
	tween.tween_property($CanvasModulate, "color", Color.BLACK, duration)
	tween.finished.connect(fade_finished.emit)

# Восстанавливает экран
func fade_in(duration := 0.2) -> void:
	var tween := _make_tween()
	tween.tween_property($CanvasModulate, "color", Color.WHITE, duration)
	tween.finished.connect(fade_finished.emit)

# Вспышка в чёрный — удобно для входа в бой
func flash_to_black() -> void:
	$CanvasModulate.color = Color.WHITE
	var tween := _make_tween()
	tween.tween_property($CanvasModulate, "color", Color.BLACK, 0.45)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.finished.connect(fade_finished.emit)

# Вспышка из чёрного — удобно для выхода из боя
func flash_from_black() -> void:
	$CanvasModulate.color = Color.BLACK
	var tween := _make_tween()
	tween.tween_property($CanvasModulate, "color", Color.WHITE, 0.3)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.finished.connect(fade_finished.emit)

func _make_tween() -> Tween:
	return get_tree().create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
