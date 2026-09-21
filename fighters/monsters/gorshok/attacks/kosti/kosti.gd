extends Node2D

const CAGE_SIZE := Vector2(160.0, 180.0)
const AX: float = 70.0  # Ширина
const AY: float = 70.0  # Высота

const BONE_SPEED := 130.0 # Скорость костей 

var phase: int      = 1
var spawned: int    = 0
var timer: float    = 0.5

var _base_bone: Area2D

func _ready() -> void:
	_base_bone = $BaseBone
	_base_bone.visible = false

	var soul := get_tree().get_first_node_in_group("soul") as Soul
	if soul:
		soul.assign_heart_properties(SoulType.BLUE)

	var cage := get_tree().get_first_node_in_group("cage")
	if cage and cage.has_method("resize"):
		cage.resize(CAGE_SIZE)

func _physics_process(delta: float) -> void:
	timer -= delta
	if timer > 0.0:
		return

	# Все кости в скакалке Санса обычно идут справа налево (dir = -1)
	var dir := -1.0

	if phase == 1:
		# ФАЗА 1: Классическая скакалка (одиночные нижние кости в одном ритме)
		# Игрок просто прыгает на месте как через скакалку
		_spawn_floor_bone(24.0, dir) # Высота кости 24 пикселя
		
		spawned += 1
		timer = 0.55 # Интервал между прыжками
		
		if spawned >= 6: # После 6 прыжков переходим к усложнению
			phase = 2
			spawned = 0
			timer = 1.0 # Небольшая пауза перед второй фазой
			
	elif phase == 2:
		# ФАЗА 2: Продвинутая скакалка (Паттерн Санса)
		# Здесь мы жестко прописываем последовательность, чтобы создать ритм
		match spawned:
			0, 1: 
				# Две быстрые мелкие кости под ноги
				_spawn_floor_bone(18.0, dir)
				timer = 0.35
			2: 
				# Высокая кость (нужно зажать прыжок повыше)
				_spawn_floor_bone(35.0, dir)
				timer = 0.6
			3: 
				# Кость сверху («потолочная»), под ней нужно просто пройти, не прыгая
				_spawn_ceiling_bone(40.0, dir)
				timer = 0.5
			4: 
				# Коридор: кость снизу и сверху одновременно! 
				# Нужно сделать очень короткий, аккуратный прыжок ( cutoff )
				_spawn_floor_bone(20.0, dir)
				_spawn_ceiling_bone(40.0, dir)
				timer = 0.7
			5: 
				# Финальный двойной аккорд (две кости подряд)
				_spawn_floor_bone(24.0, dir)
				timer = 0.25
			6:
				_spawn_floor_bone(24.0, dir)
				timer = 1.0
			_:
				phase = 3 # Конец атаки

		spawned += 1

func _make_bone(x: float, y: float, vel: Vector2, hw: float, hh: float) -> void:
	var bone: BoneBullet = _base_bone.duplicate()
	bone.visible  = true
	bone.position = Vector2(x, y)
	add_child(bone)
	bone.setup(vel, hw, hh)

# Функция спавна кости ИДЕАЛЬНО из пола
func _spawn_floor_bone(height: float, dir: float) -> void:
	var hh := height / 2.0
	# Так как центр кости в (0,0), чтобы её низ касался пола (AY),
	# её позиция Y должна быть: Пол минус половина высоты кости.
	var y := AY - hh
	var start_x := AX + 15.0 if dir < 0 else -AX - 15.0
	
	_make_bone(start_x, y, Vector2(BONE_SPEED * dir, 0.0), 6.0, hh)

# Функция спавна кости ИДЕАЛЬНО из потолка
func _spawn_ceiling_bone(height: float, dir: float) -> void:
	var hh := height / 2.0
	# Чтобы верх кости касался потолка (-AY),
	# позиция Y должна быть: Потолок плюс половина высоты кости.
	var y := -AY + hh
	var start_x := AX + 15.0 if dir < 0 else -AX - 15.0
	
	_make_bone(start_x, y, Vector2(BONE_SPEED * dir, 0.0), 6.0, hh)

func _exit_tree() -> void:
	var soul := get_tree().get_first_node_in_group("soul") as Soul
	if soul:
		soul.assign_heart_properties(SoulType.RED)
	var cage := get_tree().get_first_node_in_group("cage")
	if cage and cage.has_method("reset_size"):
		cage.reset_size()
