extends Node2D

# Настройки для "CAPTCHA" атаки
const SYMBOLS := ["8","B","d","6","G","9","0","W","@","R","g","3","E","y","4","A","q","2","Z","5"]
const COLS     := 7      # Уменьшил количество столбцов (было 9), чтобы было просторнее
const ROWS     := 4
const CELL_W   := 22.0   # Немного увеличил шаг, чтобы сетка не была слишком плотной
const CELL_H   := 14.0
const ORIGIN   := Vector2(-60.0, -74.0)

const SPAWN_DELAY  := 0.01
const PREVIEW_DUR  := 1.5    # "Думает" дольше (было 1.8)
const COL_STAGGER  := 0.11   # Медленнее падает ряд за рядом
const DROP_SPEED   := 120.0  # Чуть медленнее падение
const MAX_LOOPS    := 3      # Количество повторений атаки

var _grid      : Array = []
var _empty_cols: Array = []
var _queue     : Array = []

var _phase        := 0
var _spawn_timer := 0.0
var _phase_timer := 0.0
var _blink_t      := 0.0
var _loops_done   := 0

func _ready() -> void:
	_start_attack_loop()

func _start_attack_loop() -> void:
	# Очистка старых данных
	_grid.clear()
	_queue.clear()
	
	# Выбираем 3–4 пустых столбца
	var all_cols := range(COLS)
	all_cols.shuffle()
	var empty_count := 3 + randi() % 2 
	_empty_cols = all_cols.slice(0, empty_count)

	for r in ROWS:
		var row_arr := []
		row_arr.resize(COLS)
		row_arr.fill(null)
		_grid.append(row_arr)

	for c in COLS:
		if c in _empty_cols: continue
		for r in ROWS:
			_queue.append(Vector2i(c, r))
	
	_phase = 0
	_spawn_timer = 0.0

func _physics_process(delta: float) -> void:
	match _phase:
		0: # Фаза набора
			_spawn_timer -= delta
			if _spawn_timer <= 0.0:
				if _queue.is_empty():
					_phase = 1
					_phase_timer = PREVIEW_DUR
				else:
					_spawn_timer = SPAWN_DELAY
					var cell := _queue.pop_front() as Vector2i
					_spawn_symbol(cell.x, cell.y)

		1: # Фаза ожидания и мигания
			_phase_timer -= delta
			_blink_t += delta * 5.0
			var alpha := 0.6 + sin(_blink_t) * 0.4
			_set_grid_alpha(alpha)
			
			if _phase_timer <= 0.0:
				_phase = 2
				_phase_timer = 0.0
				_set_grid_alpha(1.0)

		2: # Фаза падения
			_phase_timer += delta
			var all_dropped := true
			
			for c in COLS:
				if c in _empty_cols: continue
				var t := c * COL_STAGGER
				if _phase_timer >= t:
					for r in ROWS:
						var p = _grid[r][c]
						if is_instance_valid(p):
							p.dropping = true
							# Если хоть один символ еще на экране (не удален пулей/выходом за экран)
							if p.global_position.y < 200: 
								all_dropped = false
			
			# Когда всё упало за пределы экрана
			if _phase_timer > 2.0: # Запас времени на пролет всех букв
				_prepare_next_loop()

func _prepare_next_loop() -> void:
	_loops_done += 1
	
	# Удаляем старые ноды перед новым циклом
	for r in _grid:
		for p in r:
			if is_instance_valid(p): p.queue_free()

	if _loops_done < MAX_LOOPS:
		_phase = 4 # Пауза между циклами
		get_tree().create_timer(0.3).timeout.connect(_start_attack_loop)
	else:
		# Конец всей атаки
		queue_free() 

func _set_grid_alpha(a: float) -> void:
	for r in _grid:
		for p in r:
			if is_instance_valid(p): p.modulate.a = a

func _spawn_symbol(col: int, row: int) -> void:
	var world_pos := ORIGIN + Vector2(col * CELL_W, row * CELL_H)
	var p := $BaseBullet.duplicate()
	p.visible = true
	p.label = SYMBOLS[randi() % SYMBOLS.size()]
	p.position = world_pos
	p.dropping = false
	p.drop_speed = DROP_SPEED + randf_range(-5.0, 5.0)
	add_child(p)
	_grid[row][col] = p
