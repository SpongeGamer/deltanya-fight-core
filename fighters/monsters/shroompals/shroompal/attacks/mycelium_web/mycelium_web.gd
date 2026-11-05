extends ShroomAttack
## ГРИБНИЦА
## Из стен прорастают светящиеся корни. Сначала — пунктир-предупреждение,
## потом корень стремительно растёт от стены. Увядая, корни рассыпают споры
## из почек. Финал — сеть из корней с узкими клетками.

const WAVE_GAP := 0.25


func get_duration() -> float:
	return 0.35 + 5 * (0.3 + 0.2 + (0.7 + 0.6 + WAVE_GAP) / pace()) + 0.5 / pace() + 0.6


func run() -> void:
	await wait(0.35)
	var waves: Array[Callable] = [_wave_rake, _wave_cross, _wave_diagonals, _wave_rake_vertical, _wave_net]
	if difficulty > 0:
		waves = [_wave_cross, _wave_diagonals, _wave_rake_vertical, _wave_rake, _wave_net]
	for i in waves.size():
		var strands: Array[RootStrand] = waves[i].call()
		var releases_spores := i < waves.size() - 1
		await _play_wave(strands, releases_spores, i == waves.size() - 1)
		await wait(WAVE_GAP / pace())


func _play_wave(strands: Array[RootStrand], spores_on_wither: bool, is_final: bool) -> void:
	var telegraph := 0.7 / pace()
	await wait(telegraph)
	sfx("snd_impact", 0.3)
	shake(2.0, 1.0)
	for strand in strands:
		strand.grow()
		puff(strand.points[0], COL_SPOT, 6, 30.0)
	await wait(0.3)
	await wait((1.1 if is_final else 0.6) / pace())
	for strand in strands:
		if is_instance_valid(strand):
			if spores_on_wither:
				strand.withered.connect(_release_spores)
			strand.wither()
	await wait(0.2)


func _release_spores(buds: PackedVector2Array) -> void:
	var every := 2 if difficulty == 0 else 1
	for i in range(0, buds.size(), every):
		var bud := buds[i]
		var away := (bud - soul_pos()).normalized()
		var dir := Vector2.UP.rotated(randf_range(-0.6, 0.6))
		if away.dot(dir) < 0.0:
			dir = -dir
		var p := spore(bud, dir * randf_range(20.0, 30.0) * pace())
		p.drag = 0.3
		p.life = 2.2
		p.sway_amp = 2.0
		p.graze_points = 3


func _strand(from: Vector2, to: Vector2, wobble := 6.0) -> RootStrand:
	var strand := RootStrand.new()
	strand.grow_speed = 95.0 * pace()
	strand.setup(RootStrand.make_path(from, to, wobble))
	field.add_child(strand)
	return strand


## Точка «спасения» рядом с душой, но не на ней — заставляет сместиться.
func _offset_from_soul(min_dist := 24.0) -> Vector2:
	var area := soul_area().grow(-14.0)
	var p := soul_pos()
	var shift := Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized() * min_dist
	return (p + shift).clamp(area.position, area.end)


# Три горизонтальных корня; один проходит точно через душу.
func _wave_rake() -> Array[RootStrand]:
	var r := box_rect()
	var y0 := clampf(soul_pos().y, r.position.y + 50.0, r.end.y - 50.0)
	var result: Array[RootStrand] = []
	for k in [-1, 0, 1]:
		var y: float = y0 + 44.0 * k
		var from_left: bool = (k + 1) % 2 == 0
		var a := Vector2(r.position.x - 4.0, y)
		var b := Vector2(r.end.x + 4.0, y)
		result.append(_strand(a if from_left else b, b if from_left else a, 5.0))
	return result


func _wave_rake_vertical() -> Array[RootStrand]:
	var r := box_rect()
	var x0 := clampf(soul_pos().x, r.position.x + 50.0, r.end.x - 50.0)
	var result: Array[RootStrand] = []
	for k in [-1, 0, 1]:
		var x: float = x0 + 44.0 * k
		var from_top: bool = k != 0
		var a := Vector2(x, r.position.y - 4.0)
		var b := Vector2(x, r.end.y + 4.0)
		result.append(_strand(a if from_top else b, b if from_top else a, 6.0))
	return result


# Крест через точку рядом с душой.
func _wave_cross() -> Array[RootStrand]:
	var r := box_rect()
	var c := _offset_from_soul(10.0)
	return [
		_strand(Vector2(r.position.x - 4.0, c.y), Vector2(r.end.x + 4.0, c.y), 4.0),
		_strand(Vector2(c.x, r.end.y + 4.0), Vector2(c.x, r.position.y - 4.0), 4.0),
	]


func _wave_diagonals() -> Array[RootStrand]:
	var r := box_rect().grow(4.0)
	return [
		_strand(r.position, r.end, 8.0),
		_strand(Vector2(r.end.x, r.position.y), Vector2(r.position.x, r.end.y), 8.0),
	]


# Сеть 3×3 линии: клетки около 36 px, безопасна середина каждой клетки.
func _wave_net() -> Array[RootStrand]:
	var r := box_rect()
	var step := r.size.x / 4.0
	var jitter := randf_range(-6.0, 6.0)
	var result: Array[RootStrand] = []
	for k in 3:
		var x := r.position.x + step * (k + 1) + jitter
		var y := r.position.y + step * (k + 1) - jitter
		result.append(_strand(Vector2(x, r.position.y - 4.0), Vector2(x, r.end.y + 4.0), 3.0))
		result.append(_strand(Vector2(r.end.x + 4.0, y), Vector2(r.position.x - 4.0, y), 3.0))
	return result
