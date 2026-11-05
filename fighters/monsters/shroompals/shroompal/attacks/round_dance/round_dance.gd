extends ShroomAttack
## ХОРОВОД
## Маленькие котогрибы окружают душу и водят хоровод, сужая круг.
## В кольце есть просвет — нужно выскользнуть, пока он не закрылся.
## В конце круга котята подпрыгивают и разбрасывают споры наружу.

const SLOTS := 12
const START_RADIUS := 92.0
const END_RADIUS := 11.0


class Dancer:
	var node: ShroomPellet
	var angle := 0.0


func get_duration() -> float:
	return 0.25 + (3.0 + 2.6 + 2.6) / pace() + 3 * (0.22 + 0.25) + 1.0


func run() -> void:
	await wait(0.25)
	var rounds := 3
	for r in rounds:
		var direction := 1.0 if r % 2 == 0 else -1.0
		var gap := 3 if r == 0 else 2
		var duration := (3.0 if r == 0 else 2.6) / pace()
		var center := soul_pos().clamp(soul_area().grow(-30.0).position, soul_area().grow(-30.0).end)
		if r == rounds - 1 and difficulty > 0:
			# Двойной хоровод: внешний круг крутится навстречу.
			_dance(center, START_RADIUS + 40.0, 36.0, -direction, 2, duration, 16, false)
		await _dance(center, START_RADIUS, END_RADIUS, direction, gap, duration, SLOTS, true)
		await wait(0.25)


func _dance(center: Vector2, from_r: float, to_r: float, direction: float, gap: int,
		duration: float, slots: int, scatter: bool) -> void:
	var gap_start := randi() % slots
	var base_angle := randf() * TAU
	var speed := (0.85 + 0.15 * difficulty) * direction
	var dancers: Array[Dancer] = []

	# Пунктирный круг показывает, где пройдёт хоровод, и где будет просвет.
	var guide := _Guide.new()
	guide.center = center
	guide.radius = from_r
	guide.gap_from = base_angle + TAU * (gap_start - 0.5) / slots
	guide.gap_to = guide.gap_from + TAU * gap / slots
	field.add_child(guide)

	for i in slots:
		var slot := (gap_start + gap + i) % slots
		if i >= slots - gap:
			break
		var cat := ShroomPellet.new(null, 5.0)
		cat.fade_in = 0.25
		cat.life = 999.0
		cat.bounds = 9999.0
		cat.damage = 5
		var sprite := Sprite2D.new()
		sprite.texture = TEX_MINI_CAT
		sprite.hframes = 2
		sprite.frame = i % 2
		sprite.offset = Vector2(0, -3)
		cat.add_child(sprite)
		cat.sprite = sprite
		field.add_child(cat)
		var dancer := Dancer.new()
		dancer.node = cat
		dancer.angle = base_angle + TAU * slot / slots
		dancers.append(dancer)

	sfx("snd_shroom", 0.45)
	var t := 0.0
	var step_timer := 0.0
	while t < duration:
		var delta := get_physics_process_delta_time()
		t += delta
		step_timer += delta
		var k := t / duration
		var radius := lerpf(from_r, to_r, k * k * (3.0 - 2.0 * k))
		var spin := speed * delta
		guide.radius = radius
		guide.gap_from += spin
		guide.gap_to += spin
		var hop := step_timer >= 0.16
		if hop:
			step_timer = 0.0
		for d in dancers:
			if not is_instance_valid(d.node):
				continue
			d.angle += spin
			var pos := center + Vector2.RIGHT.rotated(d.angle) * radius
			d.node.position = pos
			if hop:
				d.node.sprite.frame = 1 - d.node.sprite.frame
			# Котята смотрят по ходу движения и подпрыгивают в такт.
			d.node.sprite.flip_h = (Vector2.RIGHT.rotated(d.angle).orthogonal() * direction).x < 0.0
			d.node.sprite.position.y = -absf(sin(t * 12.0 + d.angle)) * 2.0
		await get_tree().physics_frame
		if not is_inside_tree():
			return
	guide.queue_free()

	# Финальный прыжок и споры наружу (через одного котёнка).
	for i in dancers.size():
		var d := dancers[i]
		if not is_instance_valid(d.node):
			continue
		var tween := d.node.create_tween()
		tween.tween_property(d.node.sprite, "position:y", -7.0, 0.12).set_ease(Tween.EASE_OUT)
		tween.tween_property(d.node.sprite, "position:y", 0.0, 0.1).set_ease(Tween.EASE_IN)
	await wait(0.22)
	sfx("snd_impact", 0.3)
	for i in dancers.size():
		var d := dancers[i]
		if not is_instance_valid(d.node):
			continue
		var pos := d.node.position
		puff(pos, COL_SPOT_LIGHT, 6, 30.0)
		d.node.vanish(0.15)
		if scatter and i % 2 == 0:
			var out := (pos - center).normalized()
			if out == Vector2.ZERO:
				out = Vector2.RIGHT.rotated(d.angle)
			var p := spore(pos, out * 46.0 * pace())
			p.drag = 0.1
			p.life = 3.0


class _Guide extends Node2D:
	var center := Vector2.ZERO
	var radius := 60.0
	var gap_from := 0.0
	var gap_to := 1.0
	var _time := 0.0

	func _process(delta: float) -> void:
		_time += delta
		queue_redraw()

	func _draw() -> void:
		var dots := 40
		var alpha := 0.18 + 0.1 * sin(_time * 10.0)
		for i in dots:
			var a := TAU * i / dots
			var pos := center + Vector2.RIGHT.rotated(a) * radius
			draw_rect(Rect2(pos.round(), Vector2(1, 1)), Color(ShroomAttack.COL_SPOT, alpha))
		# Подсветка просвета — куда бежать.
		draw_arc(center, radius, gap_from, gap_to, 12, Color(ShroomAttack.COL_SPOT_LIGHT, alpha + 0.25), 2.0)
