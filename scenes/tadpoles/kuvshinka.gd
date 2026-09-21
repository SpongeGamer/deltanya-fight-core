extends Area2D

signal placed(kuvshinka_id: int)

@export var kuvshinka_id : int     = 0
@export var water_slot   : NodePath
@export var float_speed  : float   = 55.0

enum State { IDLE, CARRIED, FLOATING, PLACED }
var state : State = State.IDLE

var _player        : Node2D          = null
var _player_nearby : bool            = false
var _in_water_slot : bool            = false
var _target_pos    : Vector2         = Vector2.ZERO
var _carried_spr   : AnimatedSprite2D = null   # храним ссылку при подборе


func _ready() -> void:
	add_to_group("kuvshinki")
	$AnimatedSprite2D.play("idle")

	# body_entered/body_exited уже подключены в .tscn — не переподключаем
	# Подключаемся к зоне воды
	var slot := get_node_or_null(water_slot) as Area2D
	if slot:
		if not slot.body_entered.is_connected(_on_water_entered):
			slot.body_entered.connect(_on_water_entered)
		if not slot.body_exited.is_connected(_on_water_exited):
			slot.body_exited.connect(_on_water_exited)
	else:
		push_warning("Kuvshinka %d: water_slot не задан или не найден" % kuvshinka_id)


func _physics_process(delta: float) -> void:
	if state != State.FLOATING:
		return
	global_position = global_position.move_toward(_target_pos, float_speed * delta)
	if global_position.distance_to(_target_pos) < 1.5:
		global_position = _target_pos
		state = State.PLACED
		$AnimatedSprite2D.play("float")
		placed.emit(kuvshinka_id)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact"):
		return
	match state:
		State.IDLE:
			if _player_nearby and not _anyone_carrying():
				_pick_up()
		State.CARRIED:
			if _in_water_slot:
				_place()


func _pick_up() -> void:
	state = State.CARRIED
	Sounds.play("snd_shroom")
	_carried_spr = $AnimatedSprite2D   # запоминаем до reparent
	_carried_spr.reparent(_player)
	_carried_spr.position = Vector2(0, -36)
	_carried_spr.play("idle")
	$CollisionShape2D.disabled = true


func _place() -> void:
	var room := _find_room()
	if room == null:
		push_warning("kuvshinka: kuvshinki_room не найдена")
		return

	_target_pos = room.request_slot()
	Sounds.play("snd_shroom")
	state = State.FLOATING

	# Возвращаем спрайт с игрока обратно
	if is_instance_valid(_carried_spr):
		_carried_spr.reparent(self)
		_carried_spr.position = Vector2.ZERO
	_carried_spr = null

	global_position = room.get_water_spawn()


func bloom() -> void:
	if state == State.PLACED:
		$AnimatedSprite2D.play("bloom")


func _anyone_carrying() -> bool:
	for k in get_tree().get_nodes_in_group("kuvshinki"):
		if k != self and k.state == State.CARRIED:
			return true
	return false


func _find_room() -> Node:
	var node := get_parent()
	while node != null:
		if node.has_method("request_slot"):
			return node
		node = node.get_parent()
	return null


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player        = body
		_player_nearby = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_nearby = false

func _on_water_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_in_water_slot = true

func _on_water_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_in_water_slot = false
