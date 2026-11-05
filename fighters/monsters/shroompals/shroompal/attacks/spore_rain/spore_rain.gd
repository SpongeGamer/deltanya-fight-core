extends ShroomAttack
## СПОРОВЫЙ ДОЖДЬ
## С потолка свисают четыре гриба. Они переползают по дорожкам, дрожат
## (подсвечивая опасные колонки) и сыплют струи спор. Иногда роняют
## тяжёлую капсулу, которая лопается кольцом. В конце — ливень с одним окном.

const LANES := 8
const LANE_SETS: Array = [
	[0, 1, 4, 5], [2, 3, 6, 7], [0, 3, 4, 7], [1, 2, 5, 6], [0, 1, 6, 7], [2, 3, 4, 5],
]

var _caps: Array[Sprite2D] = []
var _columns: Array[ColorRect] = []


func get_duration() -> float:
	# Все залпы и финальный ливень должны успеть пройти по коробке.
	return 0.5 + (5 + mini(difficulty, 2)) * (0.32 + 0.42 / pace() + 0.6 + 0.35 / pace()) + 0.85 + 9 * 0.13 + 1.6 / pace() + 0.5


func _lane_x(lane: int) -> float:
	var area := soul_area()
	return area.position.x + (lane + 0.5) * area.size.x / LANES


func run() -> void:
	var rect := box_rect()
	for i in 4:
		var cap := Sprite2D.new()
		cap.texture = TEX_HANG_CAP
		cap.offset = Vector2(0, 5)
		cap.position = Vector2(_lane_x(LANE_SETS[0][i]), rect.position.y - 14.0)
		field.add_child(cap)
		_caps.append(cap)
		var column := ColorRect.new()
		column.color = Color(COL_SPOT, 0.0)
		column.size = Vector2(16, rect.size.y)
		column.mouse_filter = Control.MOUSE_FILTER_IGNORE
		field.add_child(column)
		field.move_child(column, 0)
		_columns.append(column)
		# Грибы «вырастают» из потолка.
		var tween := cap.create_tween()
		tween.tween_interval(0.08 * i)
		tween.tween_property(cap, "position:y", rect.position.y + 1.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await wait(0.5)

	var volleys := 5 + mini(difficulty, 2)
	var order := LANE_SETS.duplicate()
	order.shuffle()
	for v in volleys:
		var lanes: Array = order[v % order.size()]
		await _move_caps(lanes)
		var pod_cap := randi() % 4 if v % 2 == 1 else -1
		await _telegraph(0.42 / pace())
		await _drop_streams(pod_cap)
	await _downpour()


func _move_caps(lanes: Array) -> void:
	var shuffled := lanes.duplicate()
	for i in _caps.size():
		var cap := _caps[i]
		var tween := cap.create_tween().set_parallel(true)
		tween.tween_property(cap, "position:x", _lane_x(shuffled[i]), 0.3).set_trans(Tween.TRANS_SINE)
		# Покачивание при перемещении — гриб «семенит» по потолку.
		tween.tween_property(cap, "rotation", 0.25 * signf(_lane_x(shuffled[i]) - cap.position.x), 0.15)
		tween.chain().tween_property(cap, "rotation", 0.0, 0.15)
	await wait(0.32)


func _telegraph(duration: float) -> void:
	var rect := box_rect()
	for i in _caps.size():
		var column := _columns[i]
		column.position = Vector2(_caps[i].position.x - 8.0, rect.position.y)
		column.size.y = rect.size.y
		var tween := column.create_tween()
		tween.tween_property(column, "color:a", 0.16, duration * 0.5)
		tween.tween_property(column, "color:a", 0.06, duration * 0.5)
		var shake_tween := _caps[i].create_tween().set_loops(3)
		shake_tween.tween_property(_caps[i], "offset:x", 1.0, duration / 6.0)
		shake_tween.tween_property(_caps[i], "offset:x", -1.0, duration / 6.0)
		_caps[i].modulate = Color(1.6, 1.6, 1.6)
		_caps[i].create_tween().tween_property(_caps[i], "modulate", Color.WHITE, duration)
	sfx("snd_shroom", 0.4)
	await wait(duration)


func _drop_streams(pod_cap: int) -> void:
	var count := 5
	var speed := 88.0 * pace()
	for n in count:
		for i in _caps.size():
			var origin := _caps[i].position + Vector2(0, 9)
			if i == pod_cap:
				if n == 1:
					_drop_pod(origin)
				continue
			var p := spore(origin, Vector2(0, speed))
			p.sway_amp = 3.0
			p.sway_freq = 5.0
			p.sway_phase = n + i
			p.graze_points = 3
		if n == 0:
			for cap in _caps:
				cap.scale = Vector2(1.15, 0.8)
				cap.create_tween().tween_property(cap, "scale", Vector2.ONE, 0.2)
		await wait(0.12)
	for column in _columns:
		column.create_tween().tween_property(column, "color:a", 0.0, 0.25)
	await wait(0.35 / pace())


func _drop_pod(origin: Vector2) -> void:
	var pod := ShroomPellet.new(TEX_POD, 4.5, Color(COL_SPOT, 0.4))
	pod.position = origin
	pod.velocity = Vector2(0, 52.0 * pace())
	pod.spin = 2.0
	pod.damage = 6
	field.add_child(pod)
	var burst_y: float = clampf(soul_pos().y - 26.0, box_rect().position.y + 30.0, box_rect().end.y - 40.0)
	var travel := (burst_y - origin.y) / pod.velocity.y
	await wait(maxf(travel - 0.35, 0.1))
	if not is_instance_valid(pod):
		return
	var blink := pod.create_tween().set_loops(3)
	blink.tween_property(pod, "modulate", Color(2, 2, 2), 0.06)
	blink.tween_property(pod, "modulate", Color.WHITE, 0.06)
	await wait(0.36)
	if not is_instance_valid(pod):
		return
	var center := pod.position
	pod.queue_free()
	puff(center, COL_SPOT_LIGHT, 14, 55.0)
	sfx("snd_impact", 0.35)
	var offset := randf() * TAU
	for k in 8:
		var dir := Vector2.RIGHT.rotated(offset + TAU * k / 8.0)
		var shard := spore(center + dir * 4.0, dir * 48.0 * pace())
		shard.drag = 0.15
		shard.life = 3.0


func _downpour() -> void:
	var rect := box_rect()
	var safe_lane := randi_range(1, LANES - 3)
	var marker := ColorRect.new()
	marker.color = Color(COL_SPOT_LIGHT, 0.0)
	var lane_w := soul_area().size.x / LANES
	marker.position = Vector2(_lane_x(safe_lane) - lane_w / 2.0, rect.position.y)
	marker.size = Vector2(lane_w * 2.0, rect.size.y)
	marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	field.add_child(marker)
	field.move_child(marker, 0)
	# Грибы уползают за край, вместо них — ливень по всей ширине.
	for cap in _caps:
		cap.create_tween().tween_property(cap, "position:y", rect.position.y - 16.0, 0.3)
	var glow := marker.create_tween().set_loops(4)
	glow.tween_property(marker, "color:a", 0.18, 0.1)
	glow.tween_property(marker, "color:a", 0.07, 0.1)
	await wait(0.85)
	sfx("snd_shroom", 0.5)
	var rows := 9
	for row in rows:
		for lane in LANES:
			if lane == safe_lane or lane == safe_lane + 1:
				continue
			var p := spore(Vector2(_lane_x(lane) + randf_range(-2, 2), rect.position.y - 4.0), Vector2(0, 105.0 * pace()))
			p.graze_points = 2
		await wait(0.13)
	marker.create_tween().tween_property(marker, "color:a", 0.0, 0.4)
