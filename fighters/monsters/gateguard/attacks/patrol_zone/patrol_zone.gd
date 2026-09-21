extends Node2D
# PATROL ZONE — один снаряд медленно ищет игрока, заряжается (мигает), рывок, отдых, повтор.
# Игрок должен двигаться ПОСЛЕ мигания — снаряд фиксирует позицию в момент рывка.
# Если двигаешься слишком рано — перетрекается. Слишком поздно — попадание.

enum State { ENTER, TRACK, CHARGE, DASH, REST }

const BULLET_HW   : float = 7.0
const TRACK_SPEED : float = 38.0    # медленный трекинг — видно куда летит
const DASH_SPEED  : float = 310.0   # рывок быстрый но короткий
const DASH_TIME   : float = 0.20    # 0.2с рывок = ~62px
const TRACK_TIME  : float = 1.5     # 1.5с слежки
const CHARGE_TIME : float = 0.50    # 0.5с мигания-предупреждения
const REST_TIME   : float = 0.55    # пауза после рывка
const TOTAL_DASHES: int   = 6

var _bullet      : Node2D  = null
var _soul        : Node2D  = null
var _state       : State   = State.ENTER
var _timer       : float   = 0.5
var _dash_dir    : Vector2 = Vector2.ZERO
var _dashes_done : int     = 0


func _ready() -> void:
	await get_tree().process_frame
	_soul = get_tree().get_first_node_in_group("soul")

	_bullet         = $BaseBullet.duplicate()
	_bullet.visible = true

	# Уменьшаем коллизию — оригинальная 19x142 занимает всю арену
	var shape := RectangleShape2D.new()
	shape.size = Vector2(BULLET_HW * 2.0, BULLET_HW * 2.0)
	_bullet.get_node("CollisionShape2D").shape = shape

	# Сбрасываем масштаб спрайта под квадратный снаряд
	var spr := _bullet.get_node_or_null("Sprite")
	if spr:
		spr.scale = Vector2(0.18, 0.18)

	_bullet.position  = _random_edge()
	_bullet.modulate.a = 0.0
	add_child(_bullet)


func _physics_process(delta: float) -> void:
	if _bullet == null or not is_instance_valid(_bullet):
		return

	var sp : Vector2 = _soul.global_position \
		if (is_instance_valid(_soul) and _soul) else Vector2.ZERO

	_timer -= delta

	match _state:

		State.ENTER:
			_bullet.modulate.a = move_toward(_bullet.modulate.a, 1.0, delta * 3.0)
			if _timer <= 0.0:
				_to(State.TRACK, TRACK_TIME)

		State.TRACK:
			# Медленно тянется к игроку
			var d := sp - _bullet.position
			if d.length() > 2.0:
				_bullet.position += d.normalized() * TRACK_SPEED * delta

			# Краснеет по мере приближения к рывку
			var frac := clampf(1.0 - _timer / TRACK_TIME, 0.0, 1.0)
			_bullet.modulate = Color(1.0 + frac, 1.0 - frac * 0.8, 1.0 - frac * 0.8, 1.0)

			if _timer <= 0.0:
				# Фиксируем направление к игроку прямо сейчас
				_dash_dir = (sp - _bullet.position).normalized()
				_to(State.CHARGE, CHARGE_TIME)

		State.CHARGE:
			# Быстрое мигание — уходи с текущей позиции
			_bullet.modulate.a = 1.0 if fmod(_timer, 0.1) > 0.05 else 0.15
			if _timer <= 0.0:
				_bullet.modulate = Color.WHITE
				_to(State.DASH, DASH_TIME)

		State.DASH:
			_bullet.position += _dash_dir * DASH_SPEED * delta
			if _timer <= 0.0:
				_dashes_done += 1
				if _dashes_done >= TOTAL_DASHES:
					_bullet.queue_free()
					_bullet = null
				else:
					_to(State.REST, REST_TIME)

		State.REST:
			_bullet.modulate.a = move_toward(_bullet.modulate.a, 0.35, delta * 3.0)
			if _timer <= 0.0:
				_bullet.modulate = Color.WHITE
				_to(State.TRACK, TRACK_TIME)


func _to(s: State, t: float) -> void:
	_state = s
	_timer = t


func _random_edge() -> Vector2:
	match randi() % 4:
		0: return Vector2(-68.0, randf_range(-55.0, 55.0))
		1: return Vector2( 68.0, randf_range(-55.0, 55.0))
		2: return Vector2(randf_range(-68.0, 68.0), -68.0)
		_: return Vector2(randf_range(-68.0, 68.0),  68.0)
