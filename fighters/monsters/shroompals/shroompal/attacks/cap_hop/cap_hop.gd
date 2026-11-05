extends ShroomAttack
## ГРИБНАЯ ПОЛЯНА (синяя душа)
## Коробка становится широкой и низкой, душа тяжелеет. По поляне ползут
## грибы разной высоты (перепрыгнуть), сверху свисают длинные грибы
## (не прыгать!), из земли выстреливают грибы-хлопушки (отбежать),
## а прыгучая шляпка скачет навстречу (пробежать под ней или перепрыгнуть).

const BOX := Vector2(204.0, 100.0)


func get_duration() -> float:
	return 10.2


func run() -> void:
	set_soul_type(SoulType.BLUE)
	resize_box(BOX, 0.4)
	await wait(0.55)
	_spawn_grass()
	var speed := 82.0 * pace()
	# [время, тип, параметр]
	var plan := [
		[0.0, "walk", 14.0], [0.9, "walk", 24.0], [1.75, "hang", 0.0],
		[2.45, "walk", 14.0], [2.68, "walk", 14.0], [3.5, "pop", 0.0],
		[4.25, "bounce", 0.0], [5.3, "hang", 0.0], [5.95, "walk", 20.0],
		[6.4, "pop", 0.0], [6.9, "walk", 16.0],
	]
	if difficulty > 0:
		plan.append([7.25, "hang", 0.0])
	var elapsed := 0.0
	for entry in plan:
		var at: float = entry[0] / pace()
		if at > elapsed:
			await wait(at - elapsed)
			elapsed = at
		match entry[1]:
			"walk": _walker(entry[2], speed)
			"hang": _hanger(speed)
			"pop": _popper()
			"bounce": _bouncer(speed * 0.9)


func _floor_y() -> float:
	return box_rect().end.y


func _walker(h: float, speed: float) -> void:
	var r := box_rect()
	var s := StalkShroom.new()
	s.height = h
	s.position = Vector2(r.end.x + 12.0, r.end.y)
	s.velocity = Vector2(-speed, 0)
	field.add_child(s)
	_free_later(s, (r.size.x + 30.0) / speed)


func _hanger(speed: float) -> void:
	var r := box_rect()
	var s := StalkShroom.new()
	# Между шляпкой и полом остаётся 24 px — стоя на полу, душа проходит.
	s.height = r.size.y - 24.0 - 6.0
	s.scale.y = -1.0
	s.position = Vector2(r.end.x + 12.0, r.position.y)
	s.velocity = Vector2(-speed, 0)
	s.modulate = Color(0.85, 0.95, 1.15)
	field.add_child(s)
	_free_later(s, (r.size.x + 30.0) / speed)


func _popper() -> void:
	var r := box_rect()
	var x := clampf(soul_pos().x, r.position.x + 14.0, r.end.x - 14.0)
	var warn := _GroundWarning.new()
	warn.position = Vector2(x, r.end.y)
	field.add_child(warn)
	sfx("snd_shroom", 0.35)
	await wait(0.6 / pace())
	if not is_inside_tree():
		return
	warn.queue_free()
	var s := StalkShroom.new()
	s.position = Vector2(x, r.end.y)
	field.add_child(s)
	puff(s.position + Vector2(0, -2), COL_BODY_LIGHT, 10, 50.0)
	shake(2.0, 1.5)
	sfx("snd_impact", 0.35)
	var tween := s.create_tween()
	tween.tween_property(s, "height", 44.0, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(0.55)
	tween.tween_property(s, "height", 0.0, 0.25).set_ease(Tween.EASE_IN)
	tween.tween_callback(s.queue_free)


func _bouncer(speed: float) -> void:
	var r := box_rect()
	var cap := ShroomPellet.new(TEX_CAP_TOP, 0.0, Color(COL_SPOT, 0.35))
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(14, 6)
	shape.shape = rect
	cap.add_child(shape)
	cap.fade_in = 0.0
	cap.life = 99.0
	cap.bounds = 9999.0
	cap.damage = 9
	cap.position = Vector2(r.end.x + 10.0, r.end.y - 4.0)
	field.add_child(cap)
	var floor_y := r.end.y - 4.0
	var hop_height := 52.0
	var hop_time := 0.62
	var t := 0.0
	var x := cap.position.x
	while is_instance_valid(cap) and x > r.position.x - 14.0:
		var delta := get_physics_process_delta_time()
		t += delta
		x -= speed * delta
		var phase := fmod(t, hop_time) / hop_time
		cap.position = Vector2(x, floor_y - 4.0 * hop_height * phase * (1.0 - phase))
		# Сплющивание при приземлении
		var squash := 1.0 - 0.3 * maxf(0.0, 1.0 - phase * 8.0)
		cap.sprite.scale = Vector2(2.0 - squash, squash)
		if phase < 0.05 and t > 0.1:
			puff(Vector2(x, r.end.y), COL_SPOT, 2, 20.0)
		await get_tree().physics_frame
		if not is_inside_tree():
			return
	if is_instance_valid(cap):
		cap.queue_free()


func _free_later(node: Node, seconds: float) -> void:
	await wait(seconds)
	if is_instance_valid(node):
		node.queue_free()


func _spawn_grass() -> void:
	# Декоративные травинки-грибочки на полу (без урона).
	var r := box_rect()
	var deco := _Grass.new()
	deco.rect = r
	field.add_child(deco)
	field.move_child(deco, 2)


class _GroundWarning extends Node2D:
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var a := 0.45 + 0.4 * sin(_t * 30.0)
		draw_rect(Rect2(-8, -2, 16, 2), Color(ShroomAttack.COL_SPOT, a))
		for i in 4:
			var x := -6.0 + i * 4.0
			var y := -3.0 - fmod(_t * 30.0 + i * 3.0, 10.0)
			draw_rect(Rect2(x, y, 1, 1), Color(ShroomAttack.COL_SPOT_LIGHT, a))


class _Grass extends Node2D:
	var rect := Rect2()

	func _draw() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = 7
		var x := rect.position.x + 3.0
		while x < rect.end.x - 3.0:
			var h := rng.randi_range(1, 4)
			draw_rect(Rect2(x, rect.end.y - h, 1, h), Color(ShroomAttack.COL_SPOT, 0.25))
			if rng.randf() < 0.15:
				draw_rect(Rect2(x - 1, rect.end.y - h - 2, 3, 2), Color(ShroomAttack.COL_SPOT, 0.4))
			x += rng.randi_range(3, 7)
