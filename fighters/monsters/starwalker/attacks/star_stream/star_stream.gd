extends StarwalkerAttack
## Возвращение исходного плотного потока справа налево.
## Скорости, разброс и частота сохранены из старого StarDrift.

var _streaming := false
var _elapsed := 0.0
var _spawn_timer := 0.0

func get_duration() -> float:
	return 8.4 + (0.85 if chicken_reaction else 0.0)

func run() -> void:
	# Предупреждаем о направлении до начала атаки.
	for y in [-30.0, -15.0, 0.0, 15.0, 30.0]:
		warn_line(Vector2(70, y), Vector2(38, y), 0.65)
	await wait(0.65)
	pulse()
	Sounds.play("snd_power", 0.3)
	_streaming = true

func _physics_process(delta: float) -> void:
	if not _streaming:
		return
	_elapsed += delta
	if _elapsed >= 5.5:
		_streaming = false
		return
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_timer = randf_range(0.08, 0.16)
		var direction := Vector2(-1.0, randf_range(-0.15, 0.15)).normalized()
		var shot := shoot(Vector2(80.0, randf_range(-30.0, 30.0)), direction * randf_range(80.0, 120.0))
		# Как в исходной сцене: прямоугольный хитбокс 13×14.
		var collision := shot.get_child(0) as CollisionShape2D
		var shape := RectangleShape2D.new()
		shape.size = Vector2(13, 14)
		collision.shape = shape
		collision.position = Vector2(0.5, 0.0)
