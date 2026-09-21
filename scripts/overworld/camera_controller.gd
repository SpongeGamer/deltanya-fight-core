class_name CameraController
extends Camera2D

## Синглтон-ссылка — CameraController.instance
static var instance: Camera2D

# ─── Следование ───────────────────────────────────────────
## Нода за которой следует камера (обычно игрок)
var follow: Node2D = null
## Смещение от цели (немного вверх — как в Deltarune)
var follow_offset: Vector2 = Vector2(0, -16)
## Скорость lerp при следовании
var follow_speed: float = 0.12

# ─── Статичная цель (пан к точке) ─────────────────────────
var target_pos: Vector2 = Vector2.ZERO
var _use_target: bool = false

# ─── Лимиты комнаты ───────────────────────────────────────
## Установи из кода комнаты: [Vector2 min, Vector2 max]
## Пример: CameraController.instance.set_room_limits(Vector2(-500,-300), Vector2(500,300))
var _limit_min: Vector2 = Vector2(-INF, -INF)
var _limit_max: Vector2 = Vector2(INF, INF)
var _limits_enabled: bool = false

# ─── Статичный режим ──────────────────────────────────────
## Если true — камера игнорирует start_follow() и остаётся на месте.
## Удобно для сцен с фиксированным видом (например, бар, таверна).
@export var static_camera: bool = false

# ─── Shake ────────────────────────────────────────────────
var shake_time: float = 0.0
var shake_intensity: float = 2.0
## Вспомогательный контейнер — CanvasLayer/Control для смещения без сдвига камеры
## Если не нужен, оставь null
@export var shake_container: Control = null

# ─── Приватное ────────────────────────────────────────────
var _pan_tween: Tween = null


func _enter_tree() -> void:
	instance = self
	# Отключаем встроенные лимиты Godot — управляем вручную
	limit_left   = -10_000_000
	limit_right  =  10_000_000
	limit_top    = -10_000_000
	limit_bottom =  10_000_000


func _process(delta: float) -> void:
	_do_shake(delta)


func _physics_process(_delta: float) -> void:
	_update_position()
	if _limits_enabled:
		global_position = Vector2(
			clamp(global_position.x, _limit_min.x, _limit_max.x),
			clamp(global_position.y, _limit_min.y, _limit_max.y)
		)


# ═══════════════════════════════════════════════════════════
#  ПУБЛИЧНОЕ API
# ═══════════════════════════════════════════════════════════

## Начать следование за нодой (обычно вызывается при спавне игрока)
func start_follow(target: Node2D, offset: Vector2 = Vector2(0, -16)) -> void:
	if static_camera:
		return
	follow = target
	follow_offset = offset
	_use_target = false
	# Сразу ставим в позицию чтобы не было прыжка
	if target:
		global_position = target.global_position + follow_offset


## Остановить следование и зафиксировать камеру в текущей позиции
func stop_follow() -> void:
	follow = null
	_use_target = false


## Мгновенно перенести камеру в позицию
func snap_to(pos: Vector2) -> void:
	follow = null
	_use_target = false
	global_position = pos


## Плавный пан к точке (awaitable)
## Пример: await CameraController.instance.pan_to(Vector2(100, 50), 1.0)
func pan_to(pos: Vector2, duration: float = 1.0, ease_type: Tween.EaseType = Tween.EASE_IN_OUT) -> void:
	follow = null
	_use_target = false
	if _pan_tween:
		_pan_tween.kill()
	_pan_tween = create_tween()
	_pan_tween.set_ease(ease_type)
	_pan_tween.set_trans(Tween.TRANS_SINE)
	_pan_tween.tween_property(self, "global_position", pos, duration)
	await _pan_tween.finished


## Плавный пан к ноде, затем начать следовать за ней (awaitable)
func pan_to_node(target: Node2D, duration: float = 1.0, then_follow: bool = true) -> void:
	follow = null
	_use_target = false
	if _pan_tween:
		_pan_tween.kill()
	var dest := target.global_position + follow_offset
	_pan_tween = create_tween()
	_pan_tween.set_ease(Tween.EASE_IN_OUT)
	_pan_tween.set_trans(Tween.TRANS_SINE)
	_pan_tween.tween_property(self, "global_position", dest, duration)
	await _pan_tween.finished
	if then_follow:
		follow = target


## Тряска камеры
## Пример: CameraController.instance.shake(15.0, 3.0)
func shake(time: float = 5.0, intensity: float = 2.0) -> void:
	shake_time = time
	shake_intensity = intensity


## Лимиты комнаты (в мировых координатах)
func set_room_limits(min_pos: Vector2, max_pos: Vector2) -> void:
	_limit_min = min_pos
	_limit_max = max_pos
	_limits_enabled = true


## Отключить лимиты (например для кат-сцен)
func clear_room_limits() -> void:
	_limits_enabled = false


# ═══════════════════════════════════════════════════════════
#  ПРИВАТНОЕ
# ═══════════════════════════════════════════════════════════

func _update_position() -> void:
	if follow != null and is_instance_valid(follow):
		var dest := follow.global_position + follow_offset
		global_position = global_position.lerp(dest, follow_speed * 60.0 * get_physics_process_delta_time())
	elif _use_target:
		global_position = global_position.lerp(target_pos, follow_speed * 60.0 * get_physics_process_delta_time())


func _do_shake(delta: float) -> void:
	if shake_time > 0.0:
		shake_time -= delta * 60.0
		var offset := Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		).round()
		# Если есть shake_container — смещаем его (UI не дёргается)
		# Если нет — двигаем саму камеру поверх follow
		if shake_container != null:
			shake_container.position = offset
	else:
		shake_time = 0.0
		if shake_container != null:
			shake_container.position = Vector2.ZERO
