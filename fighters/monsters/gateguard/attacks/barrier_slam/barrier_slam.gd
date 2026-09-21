extends Node2D
# BARRIER SLAM
# Три "призрачных" барьера появляются сверху — один мигает и исчезает (безопасная зона).
# Игрок видит где укрыться и ДОЛЖЕН туда переместиться.
# Безопасная зона меняется каждую волну → нельзя стоять на месте.

const ZONE_XS      : Array[float] = [-50.0, 0.0, 50.0]
const BARRIER_HW   : float = 24.0
const BARRIER_HH   : float = 5.0
const ORIG_W       : float = 85.0
const ORIG_SCALE_X : float = 0.55921

const MAX_WAVES    : int   = 8
const WARN_TIME    : float = 0.7   # время пока виден "призрак" безопасной зоны

var wave_timer  : float = 0.3
var wave_index  : int   = 0

func _physics_process(delta: float) -> void:
	if wave_index >= MAX_WAVES:
		return
	wave_timer -= delta
	if wave_timer > 0.0:
		return
	wave_timer = WARN_TIME + 1.4   # предупреждение + время падения
	wave_index += 1
	_do_wave()

func _do_wave() -> void:
	var safe_idx : int   = randi() % ZONE_XS.size()
	var spd      : float = 52.0 + wave_index * 5.0

	var ghosts : Array[Node2D] = []

	# Показываем все три барьера полупрозрачно
	for i in ZONE_XS.size():
		var g : Node2D = $BaseBullet.duplicate()
		g.visible  = true
		g.position = Vector2(ZONE_XS[i], -82.0)
		g.modulate.a = 0.35
		var col := g.get_node_or_null("CollisionShape2D")
		if col:
			col.disabled = true   # призрак не бьёт
		_resize(g)
		add_child(g)
		ghosts.append(g)

	# Запускаем таймер предупреждения
	_warn_then_drop(ghosts, safe_idx, spd)

func _warn_then_drop(ghosts: Array[Node2D], safe_idx: int, spd: float) -> void:
	var t : float = 0.0
	var blink_rate : float = 0.1

	# Мигаем безопасный барьер пока идёт предупреждение
	while t < WARN_TIME:
		await get_tree().process_frame
		t += get_process_delta_time()
		if is_instance_valid(ghosts[safe_idx]):
			ghosts[safe_idx].modulate.a = 0.8 if fmod(t, blink_rate * 2) < blink_rate else 0.1

	# Убираем безопасную зону — остаются только опасные
	if is_instance_valid(ghosts[safe_idx]):
		ghosts[safe_idx].queue_free()

	# Опасные барьеры становятся твёрдыми и падают
	for i in ghosts.size():
		if i == safe_idx or not is_instance_valid(ghosts[i]):
			continue
		ghosts[i].modulate.a = 1.0
		var col := ghosts[i].get_node_or_null("CollisionShape2D")
		if col:
			col.disabled = false
		ghosts[i].vel = Vector2(0.0, spd)

func _resize(b: Node2D) -> void:
	var shape := RectangleShape2D.new()
	shape.size = Vector2(BARRIER_HW * 2.0, BARRIER_HH * 2.0)
	var col := b.get_node_or_null("CollisionShape2D")
	if col:
		col.shape = shape
	var spr := b.get_node_or_null("Sprite")
	if spr:
		spr.scale.x = ORIG_SCALE_X * (BARRIER_HW * 2.0 / ORIG_W)
