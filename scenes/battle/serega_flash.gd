extends CanvasLayer

## Белый засвет поверх боя: CanvasModulate для этого не годится,
## он не может осветлить картинку сильнее оригинала.
func flash(duration: float = 2.5) -> void:
	layer = 90
	var rect := ColorRect.new()
	rect.color = Color(1, 1, 1, 0)
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# ADD смешивает белый поверх картинки, давая пересвет.
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	rect.material = mat
	add_child(rect)

	var tween := create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(rect, "color:a", 1.0, duration * 0.45)
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(rect, "color:a", 0.86, duration * 0.2)
	tween.tween_interval(0.3)
	await tween.finished
