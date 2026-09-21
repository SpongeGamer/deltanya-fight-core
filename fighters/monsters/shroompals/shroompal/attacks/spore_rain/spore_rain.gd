extends Node2D

var wave_timer : float = 0.5
var wave_index : int = 0
const MAX_WAVES := 12 #

func _physics_process(delta: float) -> void:
	if wave_index >= MAX_WAVES: 
		return
	wave_timer -= delta
	if wave_timer <= 0.0:
		_spawn_readable_wave()
		wave_index += 1
		# Фиксированный честный ритм, чтобы игрок успевал среагировать
		wave_timer = 0.7 

func _spawn_readable_wave() -> void:
	var cols := 8 # Делим арену на 8 четких дорожек[cite: 9]
	var col_w := 160.0 / cols
	
	# Выбираем случайную сторону (лево/право/центр), где БУДЕТ снаряд
	# Остальное пространство остается пустым и безопасным
	var pattern_type := wave_index % 3
	var spawn_indices := []
	
	match pattern_type:
		0: spawn_indices = [0, 1, 4, 5] # Снаряды слева и в центре
		1: spawn_indices = [2, 3, 6, 7] # Снаряды в шахматном порядке
		2: spawn_indices = [0, 1, 6, 7] # Снаряды только по краям (центр пуст)

	for c in spawn_indices:
		var p = $BaseBullet.duplicate()
		p.visible = true
		# Центрируем снаряд строго по дорожке[cite: 9]
		var x_pos = -80.0 + (c * col_w) + (col_w / 2.0)
		p.position = Vector2(x_pos, -95.0)
		
		# Скорость чуть ниже, чтобы дождь не "давил"[cite: 10]
		p.speed = 70.0 
		# Минимальное виляние, чтобы коридор не перекрывался[cite: 10]
		p.amplitude = 5.0 
		p.frequency = 1.5
		p.phase = wave_index
		add_child(p)
