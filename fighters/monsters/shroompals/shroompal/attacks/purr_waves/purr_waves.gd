extends ShroomAttack
## МУРЛЫКАНЬЕ
## Над коробкой проявляется призрачный Шрумп и мурлычет волнами.
## Голубая волна — замри, оранжевая — двигайся, споровая — ищи просвет.
## Перед каждой волной Шрумп вспыхивает её цветом.

enum Kind { STAND, MOVE, SPORES }

var _ghost: Sprite2D
var _mouth := Vector2.ZERO


func get_duration() -> float:
	# Последняя волна должна успеть пересечь всю арену.
	return 0.6 + (7.72 + (0.42 if difficulty > 0 else 0.0)) / pace() + (11 if difficulty > 0 else 10) * 0.18 + 2.7 / pace() + 0.3


func run() -> void:
	var r := box_rect()
	_mouth = Vector2(0, r.position.y - 22.0)
	_ghost = Sprite2D.new()
	_ghost.texture = TEX_SHROOMPAL
	_ghost.scale = Vector2(0.125, 0.125)
	_ghost.position = Vector2(0, r.position.y - 36.0)
	_ghost.modulate = Color(0.7, 1.0, 1.0, 0.0)
	_ghost.material = ShroomPellet.additive()
	over.add_child(_ghost)
	_ghost.create_tween().tween_property(_ghost, "modulate:a", 0.75, 0.5)
	await wait(0.6)

	var plan := [
		[Kind.STAND, 0.0], [Kind.MOVE, 1.25], [Kind.SPORES, 1.15],
		[Kind.STAND, 0.85], [Kind.STAND, 0.55], [Kind.MOVE, 1.0],
		[Kind.SPORES, 0.9], [Kind.SPORES, 0.6],
		[Kind.STAND, 1.0], [Kind.MOVE, 0.42],
	]
	if difficulty > 0:
		plan.append([Kind.STAND, 0.42])
	for entry in plan:
		if entry[1] > 0.0:
			await wait(entry[1] / pace())
		await _purr(entry[0])
	await wait(1.6)
	if is_instance_valid(_ghost):
		_ghost.create_tween().tween_property(_ghost, "modulate:a", 0.0, 0.4)


func _color_of(kind: Kind) -> Color:
	match kind:
		Kind.STAND: return COL_STAND
		Kind.MOVE: return COL_MOVE
	return COL_SPOT


func _purr(kind: Kind) -> void:
	var color := _color_of(kind)
	# Предупреждение: призрак вспыхивает цветом волны и раздувается.
	var tween := _ghost.create_tween().set_parallel(true)
	_ghost.modulate = Color(color.r * 1.4, color.g * 1.4, color.b * 1.4, 0.95)
	tween.tween_property(_ghost, "scale", Vector2(0.14, 0.115), 0.12)
	tween.chain().tween_property(_ghost, "scale", Vector2(0.125, 0.125), 0.2)
	tween.tween_property(_ghost, "modulate", Color(0.7, 1.0, 1.0, 0.75), 0.6)
	await wait(0.18)
	sfx("snd_shroom", 0.35)
	var ring := PurrRing.new()
	ring.kind = kind
	ring.color = color
	ring.center = _mouth
	ring.speed = (60.0 if kind == Kind.SPORES else 78.0) * pace()
	ring.attack = self
	field.add_child(ring)
	ring.build()


class PurrRing extends Node2D:
	const ARC_FROM := 0.12
	const ARC_TO := PI - 0.12
	const COUNT := 38

	var kind := 0
	var color := Color.WHITE
	var center := Vector2.ZERO
	var radius := 4.0
	var speed := 70.0
	var attack: ShroomAttack
	var pellets: Array[ShroomPellet] = []
	var angles: Array[float] = []
	var _t := 0.0

	func build() -> void:
		var gap_at := -1
		if kind == Kind.SPORES:
			# Просвет направлен примерно туда, где сейчас душа (±), чтобы
			# пришлось подстраиваться, но не стоять на месте.
			var to_soul := (attack.soul_pos() - center).angle() + randf_range(-0.5, 0.5)
			gap_at = int(clampf(remap(to_soul, ARC_FROM, ARC_TO, 0, COUNT - 1), 3, COUNT - 4))
		for i in COUNT:
			if gap_at >= 0 and absi(i - gap_at) <= 2:
				continue
			var p: ShroomPellet
			if kind == Kind.SPORES:
				p = ShroomPellet.new(ShroomAttack.TEX_SPORE, 3.0, ShroomAttack.COL_GLOW)
			else:
				p = ShroomPellet.new(null, 3.5)
				p.hit_rule = Pellet.HitRule.BLUE_STAND if kind == Kind.STAND else Pellet.HitRule.ORANGE_MOVE
			p.fade_in = 0.0
			p.life = 99.0
			p.bounds = 9999.0
			p.damage = 8
			add_child(p)
			pellets.append(p)
			angles.append(lerpf(ARC_FROM, ARC_TO, float(i) / (COUNT - 1)))
		_place()

	func _physics_process(delta: float) -> void:
		_t += delta
		radius += speed * delta
		_place()
		queue_redraw()
		if radius > 260.0:
			queue_free()

	func _place() -> void:
		for i in pellets.size():
			if is_instance_valid(pellets[i]):
				pellets[i].position = center + Vector2.RIGHT.rotated(angles[i]) * radius

	func _draw() -> void:
		if kind == Kind.SPORES:
			return
		var flicker := 0.85 + 0.15 * sin(_t * 30.0)
		draw_arc(center, radius, ARC_FROM, ARC_TO, 64, Color(color, 0.25), 9.0)
		draw_arc(center, radius, ARC_FROM, ARC_TO, 64, Color(color, flicker), 3.0)
		draw_arc(center, radius - 1.0, ARC_FROM, ARC_TO, 64, Color(1, 1, 1, 0.55 * flicker), 1.0)
