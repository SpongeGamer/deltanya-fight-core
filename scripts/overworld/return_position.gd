extends Node

# Вешай на дочернюю ноду игрока в каждой локации.
# Восстанавливает позицию после боя или загрузки сохранения.

func _ready() -> void:
	if Global.player_return_position != Vector2.ZERO:
		get_parent().global_position = Global.player_return_position
		Global.player_return_position = Vector2.ZERO
