extends "res://fighters/monsters/serega/attacks/common/serega_attack.gd"

const FORMATION := preload("res://fighters/monsters/serega/attacks/common/serega_formation.gd")
const CUE := preload("res://fighters/monsters/serega/attacks/common/serega_cue.gd")

func phrase(kind: int, side: int, gap: int, speed: float, tint: Color, edge: int = -1, tilt: float = 0.0, turn: float = 0.0) -> void:
	var formation = FORMATION.new()
	formation.kind = kind
	formation.side = side
	formation.gap = clampi(gap, 0, 8)
	formation.speed = speed
	formation.color = tint
	formation.entry_edge = edge
	formation.lean = tilt
	formation.turn_amount = turn
	field.add_child(formation)

func cue(side: int, kind: int) -> void:
	var mark = CUE.new()
	mark.side = side
	mark.kind = kind
	if kind == 1 and is_instance_valid(caster):
		var source: AnimatedSprite2D = caster.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
		if source and source.sprite_frames and source.sprite_frames.has_animation(source.animation):
			mark.portrait = source.sprite_frames.get_frame_texture(source.animation, source.frame)
	over.add_child(mark)

# Avoid the same entrance twice; keep each opening large enough for the soul.
func next_edge(previous: int = -1) -> int:
	if previous < 0:
		return randi_range(0, 3)
	var pick: int = randi_range(0, 2)
	return pick + 1 if pick >= previous else pick

func next_gap(previous: int = -1) -> int:
	if previous < 0:
		return randi_range(2, 6)
	var step: int = [-2, -1, 1, 2][randi_range(0, 3)]
	var result: int = clampi(previous + step, 1, 7)
	if result == previous:
		result = previous - 1 if previous > 4 else previous + 1
	return result

func cue_edge(edge: int, kind: int) -> void:
	var mark = CUE.new()
	mark.side = 1
	mark.kind = kind
	var angles: Array[float] = [-PI / 2.0, 0.0, PI / 2.0, PI]
	mark.rotation = angles[edge % 4]
	if kind == 1 and is_instance_valid(caster):
		var source: AnimatedSprite2D = caster.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
		if source and source.sprite_frames and source.sprite_frames.has_animation(source.animation):
			mark.portrait = source.sprite_frames.get_frame_texture(source.animation, source.frame)
	over.add_child(mark)

func aimed_note(origin: Vector2, speed: float = 100.0) -> void:
	var direction: Vector2 = (soul_pos() - origin).normalized()
	if direction.length_squared() < 0.1:
		direction = Vector2.DOWN
	var note = shot(origin, direction * speed, PALE, 14, 1, 3.5)
	note.spin = 3.0
