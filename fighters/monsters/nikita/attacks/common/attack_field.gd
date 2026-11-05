extends RefCounted
## Слой снарядов обрезается по внутренней границе стандартной боевой рамки.
static func make(owner: Node) -> Node2D:
	var clip := Control.new()
	clip.position = Vector2(-71, -71)
	clip.size = Vector2(142, 142)
	clip.clip_contents = true
	clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	owner.add_child(clip)
	var field := Node2D.new()
	field.position = -clip.position
	clip.add_child(field)
	return field
