extends ShroomAttack
## ЦВЕТЕНИЕ
## 1) В углах коробки набухают дождевики. Каждый целится (пунктир к душе)
##    и выплёвывает веер спор.
## 2) В центре распускается большой гриб-цветок: лепестки вращаются,
##    из него закручивается спираль спор, затем она меняет направление.
## 3) Финальный «пых» — медленное кольцо спор.

var _petals: _Petals


func get_duration() -> float:
	return 0.3 + 0.45 + (6 + mini(difficulty, 2)) * 0.62 / pace() + 0.5 + 0.35 + 0.9 + 0.5 + 3.2 + 0.3 + 0.35 + 1.7 / pace() + 0.5


func run() -> void:
	await wait(0.3)
	await _corner_phase()
	await wait(0.35)
	await _flower_phase()


# ── Фаза 1: дождевики в углах ──────────────────────────────────────────────────

func _corner_phase() -> void:
	var a := soul_area().grow(-6.0)
	var corners := [a.position, Vector2(a.end.x, a.position.y), a.end, Vector2(a.position.x, a.end.y)]
	var puffballs: Array[ShroomPellet] = []
	for c in corners:
		var pb := ShroomPellet.new(TEX_PUFFBALL, 6.0, Color(COL_SPOT, 0.3))
		pb.fade_in = 0.0
		pb.life = 99.0
		pb.bounds = 9999.0
		pb.damage = 5
		pb.position = c
		pb.scale = Vector2.ZERO
		field.add_child(pb)
		pb.create_tween().tween_property(pb, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		puffballs.append(pb)
	await wait(0.45)
	var shots := 6 + mini(difficulty, 2)
	var interval := 0.62 / pace()
	for s in shots:
		var pb := puffballs[s % 4]
		_aim_and_fire(pb, interval * 1.3)
		await wait(interval)
	await wait(0.5)
	for pb in puffballs:
		if is_instance_valid(pb):
			puff(pb.position, COL_SPOT_LIGHT, 8, 40.0)
			pb.vanish(0.2)


func _aim_and_fire(pb: ShroomPellet, charge: float) -> void:
	var aim := _AimLine.new()
	aim.from = pb.position
	field.add_child(aim)
	var tween := pb.create_tween()
	tween.tween_property(pb, "scale", Vector2(1.35, 1.35), charge).set_trans(Tween.TRANS_SINE)
	var t := 0.0
	while t < charge:
		t += get_physics_process_delta_time()
		aim.to = soul_pos()
		aim.progress = t / charge
		await get_tree().physics_frame
		if not is_inside_tree() or not is_instance_valid(pb):
			return
	var dir := (aim.to - pb.position).normalized()
	aim.queue_free()
	pb.scale = Vector2(0.8, 0.8)
	pb.create_tween().tween_property(pb, "scale", Vector2.ONE, 0.25)
	puff(pb.position + dir * 6.0, COL_SPOT_LIGHT, 6, 35.0)
	sfx("snd_shroom", 0.35)
	for k in [-2, -1, 0, 1, 2]:
		var p := spore(pb.position + dir * 6.0, dir.rotated(k * 0.24) * 78.0 * pace())
		p.graze_points = 4


# ── Фаза 2: гриб-цветок в центре ───────────────────────────────────────────────

func _flower_phase() -> void:
	var c := box_rect().get_center()
	# Предупреждение: мигающий круг там, где вырастет цветок.
	var warn := _DangerCircle.new()
	warn.position = c
	warn.radius = 16.0
	field.add_child(warn)
	await wait(0.9)
	warn.queue_free()

	_petals = _Petals.new()
	_petals.position = c
	field.add_child(_petals)
	var core := ShroomPellet.new(TEX_PUFFBALL, 8.0, Color(COL_SPOT, 0.5))
	core.fade_in = 0.0
	core.life = 99.0
	core.bounds = 9999.0
	core.damage = 6
	core.position = c
	core.scale = Vector2.ZERO
	field.add_child(core)
	core.create_tween().tween_property(core, "scale", Vector2(1.4, 1.4), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	puff(c, COL_SPOT_LIGHT, 18, 70.0)
	shake(3.0, 2.0)
	sfx("snd_impact", 0.45)
	await wait(0.5)

	var arms := 3
	var interval := 0.15 / pace()
	var omega := deg_to_rad(100.0) * pace()
	var angle := randf() * TAU
	var shots := int(3.2 / interval)
	for s in shots:
		if s == shots / 2:
			# Спираль разворачивается — короткая пауза-подсказка.
			omega = -omega
			_petals.spin = signf(omega) * 2.5
			await wait(0.3)
		angle += omega * interval
		for k in arms:
			var dir := Vector2.RIGHT.rotated(angle + TAU * k / arms)
			var p := spore(c + dir * 10.0, dir * 60.0 * pace(), false)
			p.graze_points = 2
		if difficulty > 0 and s % 12 == 6:
			for k in 10:
				var d := Vector2.RIGHT.rotated(angle * 0.5 + TAU * k / 10.0)
				var pod := ShroomPellet.new(TEX_POD, 4.0)
				pod.position = c + d * 10.0
				pod.velocity = d * 38.0
				pod.spin = 3.0
				field.add_child(pod)
		core.scale = Vector2(1.5, 1.3) if s % 2 == 0 else Vector2(1.4, 1.4)
		await wait(interval)

	# Финал: цветок лопается.
	if is_instance_valid(core):
		var tween := core.create_tween()
		tween.tween_property(core, "scale", Vector2(1.9, 1.9), 0.35)
		await tween.finished
		if not is_inside_tree():
			return
		puff(c, COL_SPOT_LIGHT, 24, 90.0)
		sfx("snd_impact", 0.5)
		shake(3.0, 2.5)
		core.queue_free()
		_petals.queue_free()
		var offset := randf() * TAU
		for k in 12:
			var d := Vector2.RIGHT.rotated(offset + TAU * k / 12.0)
			var p := spore(c + d * 8.0, d * 40.0)
			p.drag = 0.05


class _AimLine extends Node2D:
	var from := Vector2.ZERO
	var to := Vector2.ZERO
	var progress := 0.0

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var length := from.distance_to(to)
		if length < 1.0:
			return
		var dir := (to - from) / length
		var dots := int(length / 5.0)
		for i in dots:
			var p := from + dir * (i * 5.0 + 6.0)
			var a := (0.15 + 0.5 * progress) * (1.0 - float(i) / maxf(dots, 1))
			draw_rect(Rect2(p.round(), Vector2(1, 1)), Color(ShroomAttack.COL_SPOT_LIGHT, a))


class _DangerCircle extends Node2D:
	var radius := 16.0
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var a := 0.35 + 0.35 * sin(_t * 24.0)
		draw_circle(Vector2.ZERO, radius * minf(_t * 3.0, 1.0), Color(ShroomAttack.COL_SPOT, a * 0.25))
		draw_arc(Vector2.ZERO, radius, 0, TAU, 24, Color(ShroomAttack.COL_SPOT_LIGHT, a), 1.0)


class _Petals extends Node2D:
	var spin := 2.5
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		rotation += spin * delta * 0.4
		queue_redraw()

	func _draw() -> void:
		var grow := minf(_t * 3.0, 1.0)
		for i in 6:
			var dir := Vector2.RIGHT.rotated(TAU * i / 6.0)
			var tip := dir * (22.0 + 2.0 * sin(_t * 6.0 + i)) * grow
			var side := dir.orthogonal() * 6.0 * grow
			var petal := PackedVector2Array([dir * 8.0, dir * 14.0 * grow + side, tip, dir * 14.0 * grow - side])
			draw_colored_polygon(petal, Color(ShroomAttack.COL_CAP, 0.7))
			draw_polyline(petal + PackedVector2Array([petal[0]]), Color(ShroomAttack.COL_SPOT, 0.35), 1.0)
			draw_rect(Rect2((tip * 0.8).round(), Vector2(1, 1)), ShroomAttack.COL_SPOT_LIGHT)
