extends Area2D

# Путь к спрайту — замени на свой
@export var sprite_texture: Texture2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var anim: AnimationPlayer = $AnimationPlayer

var player_inside := false
var activated := false

func _ready() -> void:
	if sprite_texture:
		sprite.texture = sprite_texture

func _process(_delta: float) -> void:
	if player_inside and Input.is_action_just_pressed("interact"):
		_activate()

func _activate() -> void:
	if activated:
		return
	activated = true

	# Играем анимацию активации если есть
	if anim.has_animation("activate"):
		anim.play("activate")

	# Получаем игрока
	var player = get_tree().get_first_node_in_group("player")
	var player_pos = player.global_position
	var scene_path := get_tree().current_scene.scene_file_path

	# Сохраняем
	Global.save_game(scene_path, player_pos)

	# Показываем текст
	Global.display_text.emit("  * Игра сохранена.", true)
	await Global.text_finished

	activated = false

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_inside = true


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_inside = false
