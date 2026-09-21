extends SoulMove

@export var gravity_strength : float = 320.0  # Ускорение (0.2 пикс/кадр^2 * 30^2)
@export var jump_impulse : float = 180.0      # Сила прыжка (6 пикс/кадр * 30)
@export var jump_cutoff : float = 30.0        # Минимальный прыжок при отпускании (1 пикс/кадр * 30)
@export var max_fall_speed : float = 240.0    # Лимит скорости падения (8 пикс/кадр * 30)

var current_fall_speed : float = 0.0
var gravity := Vector2(0, 1)
var jump_action : String = "up" # Экшен для прыжка, меняется от направления гравитации

func start() -> void:
	soul.motion_mode = CharacterBody2D.MOTION_MODE_GROUNDED
	set_gravity_direction(Util.Direction.NORTH)
	# Базовая скорость speed = 4.0 * 30.0 (120) уже идеально унаследована из SoulMove!

func physics_tick(delta : float) -> void:
	if !soul.active:
		return

	# 1. Получаем горизонтальную скорость (вдоль поверхности) из родительского класса
	# Благодаря твоей фильтрации осей в getInput(), инпут по оси гравитации тут уже равен 0.
	var input := getInput()
	if normalized_movement:
		input = input.normalized()
	
	var horizontal_velocity := apply_speed(input)

	# 2. Проверяем столкновения по ходу гравитации (благодаря soul.up_direction это работает из коробки)
	if soul.is_on_floor():
		# На полу сбрасываем скорость падения
		current_fall_speed = max(0.0, current_fall_speed)
	elif soul.is_on_ceiling():
		# Ударились головой о потолок — прерываем полет вверх
		current_fall_speed = max(0.0, current_fall_speed)

	# 3. Применяем гравитацию, если мы в воздухе
	if not soul.is_on_floor():
		current_fall_speed += gravity_strength * delta
		current_fall_speed = min(current_fall_speed, max_fall_speed)

	# 4. Прыжок (срабатывает только на полу)
	if Input.is_action_just_pressed(jump_action) and soul.is_on_floor():
		current_fall_speed = -jump_impulse

	# 5. Прерывание прыжка (Cutoff) — дает ту самую "тяжесть" и контроль высоты, как в Undertale
	if Input.is_action_just_released(jump_action) and current_fall_speed < -jump_cutoff:
		current_fall_speed = -jump_cutoff

	# 6. Собираем финальный вектор скорости персонажа
	# Складываем движение по плоскости коробки и движение по оси гравитации
	soul.velocity = horizontal_velocity + (gravity * current_fall_speed)
	
	# 7. Двигаем душу (вместо super.physics_tick, чтобы обойти сброс velocity)
	soul.move_and_slide()

func set_gravity_direction(dir : Util.Direction, multiplier : float = 1.0) -> void:
	# Сохраняем твою рабочую логику переключения осей движения
	var dir_to_axis := {
		Util.Direction.NORTH: MoveAxis.X,
		Util.Direction.SOUTH: MoveAxis.X,
		Util.Direction.EAST: MoveAxis.Y,
		Util.Direction.WEST: MoveAxis.Y
	}
	set_axis(dir_to_axis.get(dir, MoveAxis.X))
	
	# Твой расчет вектора гравитации и вращения визуала
	gravity = Vector2(1, 0).rotated(deg_to_rad(Util.ROTATION_DEGREES_FROM_DIR.get(dir))) * multiplier
	soul.up_direction = -gravity
	soul.visually_rotate(Util.ROTATION_DEGREES_FROM_DIR.get(dir) - 90)
	
	# Динамически переназначаем кнопку прыжка в зависимости от вектора гравитации.
	# Кнопка прыжка всегда противоположна направлению падения!
	match dir:
		Util.Direction.NORTH: jump_action = "up"     # Обычный пол снизу -> прыгаем вверх
		Util.Direction.SOUTH: jump_action = "down"   # Пол на потолке -> прыгаем вниз
		Util.Direction.EAST: jump_action = "left"    # Пол справа -> прыгаем влево
		Util.Direction.WEST: jump_action = "right"   # Пол слева -> прыгаем вправо
