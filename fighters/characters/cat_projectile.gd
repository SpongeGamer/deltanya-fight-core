extends Node2D

signal hit_target

var target : Node2D = null
var speed  := 400.0
var _is_moving := false

# Запоминаем точку, где снаряд «отдыхает» (например, 0,0 или за экраном)
@onready var spawn_pos := global_position 

func _ready() -> void:
	# При запуске игры сразу выключаем его
	_stop_and_reset()

func init(p_target: Node2D) -> void:
	# Если нужно, чтобы снаряд вылетал из позиции игрока, 
	# можно добавить сюда: global_position = p_target_owner.global_position
	target = p_target
	visible = true
	set_physics_process(true) # Включаем расчеты
	$AnimatedSprite2D.play("default")
	_is_moving = true

func _physics_process(delta: float) -> void:
	if not _is_moving:
		return
		
	if not is_instance_valid(target):
		hit_target.emit()
		_stop_and_reset()
		return
	
	var dir := (target.global_position - global_position).normalized()
	global_position += dir * speed * delta
	
	if global_position.distance_to(target.global_position) < 20.0:
		hit_target.emit()
		_stop_and_reset()

# Новая вспомогательная функция для «выключения»
func _stop_and_reset() -> void:
	_is_moving = false
	visible = false
	set_physics_process(false) # Полностью останавливаем код, чтобы не жрал ресурсы
	global_position = spawn_pos # Телепортируем «домой»
