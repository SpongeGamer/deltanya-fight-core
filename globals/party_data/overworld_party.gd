extends Node

const PLAYER_SCENE := "res://scenes/prefabs/player.tscn"

const COMPANION_SCENES := {
	"kate":   "res://scenes/prefabs/kate_body.tscn",
	"egor":   "res://scenes/prefabs/egor_body.tscn",
	"nikita": "res://scenes/prefabs/nikita_body.tscn",
}

var companions: Dictionary = {}


## Если игрока нет в текущей сцене — спавним его.
## Возвращает ноду игрока (существующую или только что созданную).
func spawn_player_if_needed() -> Node2D:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		return player

	var scene: PackedScene = load(PLAYER_SCENE)
	if not scene:
		push_error("OverworldParty: не найдена сцена игрока: " + PLAYER_SCENE)
		return null

	player = scene.instantiate()
	get_tree().current_scene.add_child(player)
	return player


func spawn_companions() -> void:
	# Убиваем старых заспавненных компаньонов
	for key in companions:
		if is_instance_valid(companions[key]):
			companions[key].queue_free()
	companions.clear()

	var player = get_tree().get_first_node_in_group("player")
	if not player:
		push_error("OverworldParty: spawn_companions — игрок не найден!")
		return

	for i in range(1, Global.party.size()):
		var key: String = Global.party[i]

		# Удаляем хардкоженную ноду из сцены если есть
		var existing := get_tree().get_nodes_in_group(key + "_body")
		for old in existing:
			old.queue_free()

		if not COMPANION_SCENES.has(key):
			continue

		var scene: PackedScene = load(COMPANION_SCENES[key])
		if not scene:
			push_error("OverworldParty: не найдена сцена для " + key)
			continue

		var companion: Node2D = scene.instantiate()
		companion.global_position = player.global_position + Vector2(i * 20, 0)
		get_tree().current_scene.add_child(companion)
		companions[key] = companion

		if companion.has_method("start_following"):
			companion.start_following()


func get_companion(key: String) -> Node2D:
	return companions.get(key, null)
