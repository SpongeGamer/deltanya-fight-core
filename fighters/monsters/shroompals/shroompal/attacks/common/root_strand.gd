extends Node2D
class_name RootStrand
## Светящийся корень грибницы: пунктир-предупреждение → рост от стены →
## удержание → увядание (может рассыпать споры из почек).

signal withered(bud_points: PackedVector2Array)

enum State { TELEGRAPH, GROWING, HOLD, WITHER }

var points := PackedVector2Array()
var state := State.TELEGRAPH
var grown := 0.0          # сколько точек пути уже выросло
var grow_speed := 120.0   # точек пути в секунду
var alpha := 1.0
var hitbox: ShroomPellet
var twigs: Array = []     # [индекс точки, направление, длина]

var _time := 0.0
var _segments := 0


static func make_path(from: Vector2, to: Vector2, wobble := 6.0, steps := 28) -> PackedVector2Array:
	var path := PackedVector2Array()
	var side := (to - from).normalized().orthogonal()
	var phase := randf() * TAU
	var freq := randf_range(1.2, 2.2)
	for i in steps + 1:
		var t := float(i) / steps
		# Концы закреплены, середина гуляет синусом + лёгкий шум.
		var envelope := sin(t * PI)
		var bend := sin(t * PI * freq + phase) * wobble * envelope
		path.append(from.lerp(to, t) + side * (bend + randf_range(-0.6, 0.6) * envelope))
	return path


func setup(path: PackedVector2Array) -> void:
	points = path
	hitbox = ShroomPellet.new(null, 0.0)
	hitbox.fade_in = 0.0
	hitbox.life = 999.0
	hitbox.bounds = 9999.0
	hitbox.damage = 9
	hitbox.graze_points = 4
	add_child(hitbox)
	for i in range(3, points.size() - 3, 4):
		var dir := (points[i + 1] - points[i]).normalized().orthogonal() * (1.0 if randi() % 2 else -1.0)
		twigs.append([i, dir.rotated(randf_range(-0.5, 0.5)), randf_range(3.0, 6.0)])


func grow() -> void:
	state = State.GROWING


func wither() -> void:
	if state == State.WITHER:
		return
	state = State.WITHER
	hitbox.harmful = false
	var buds := PackedVector2Array()
	for twig in twigs:
		buds.append(points[twig[0]] + twig[1] * twig[2])
	withered.emit(buds)
	var tween := create_tween()
	tween.tween_property(self, "alpha", 0.0, 0.45)
	tween.tween_callback(queue_free)


func _physics_process(delta: float) -> void:
	_time += delta
	if state == State.GROWING:
		grown = minf(grown + grow_speed * delta, points.size() - 1)
		var target := int(grown)
		while _segments < target:
			var shape := CollisionShape2D.new()
			var seg := SegmentShape2D.new()
			seg.a = points[_segments]
			seg.b = points[_segments + 1]
			shape.shape = seg
			hitbox.add_child(shape)
			_segments += 1
		if _segments >= points.size() - 1:
			state = State.HOLD
	queue_redraw()


func _draw() -> void:
	match state:
		State.TELEGRAPH:
			var blink := 0.35 + 0.35 * sin(_time * 22.0)
			for i in range(0, points.size(), 2):
				draw_rect(Rect2(points[i].round() - Vector2(1, 1), Vector2(2, 2)), Color(ShroomAttack.COL_SPOT, blink))
		_:
			var count := int(grown) + 1
			if state != State.GROWING:
				count = points.size()
			if count < 2:
				return
			var visible_points := points.slice(0, count)
			if state == State.GROWING and count < points.size():
				visible_points.append(points[count - 1].lerp(points[count], grown - floorf(grown)))
			var pulse := 0.8 + 0.2 * sin(_time * 9.0)
			draw_polyline(visible_points, Color(ShroomAttack.COL_SPOT, 0.22 * alpha), 7.0)
			draw_polyline(visible_points, Color(ShroomAttack.COL_OUTLINE, alpha), 4.0)
			draw_polyline(visible_points, Color(ShroomAttack.COL_SPOT, pulse * alpha), 2.0)
			for twig in twigs:
				if twig[0] < count:
					var base: Vector2 = points[twig[0]]
					var tip: Vector2 = base + twig[1] * twig[2]
					draw_line(base, tip, Color(ShroomAttack.COL_SPOT, 0.7 * alpha), 1.0)
					draw_rect(Rect2(tip.round() - Vector2(1, 1), Vector2(2, 2)), Color(ShroomAttack.COL_SPOT_LIGHT, alpha))
			# Светящийся кончик растущего корня
			if state == State.GROWING:
				var tip_point := visible_points[visible_points.size() - 1]
				draw_circle(tip_point, 3.0, Color(ShroomAttack.COL_SPOT_LIGHT, 0.9))
