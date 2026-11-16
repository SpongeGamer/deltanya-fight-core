extends Node

const KEY_ITEM = preload("res://holdables/items/mystery_key.tres")

@export var dialogue_area: NodePath

## Диалог когда боёв не было вообще
@export var dialogue_no_encounter: Array[DE]
## Диалог когда всех пощадил
@export var dialogue_all_spared: Array[DE]
## Диалог когда всех убил
@export var dialogue_all_killed: Array[DE]
## Диалог смешанный (и убивал и щадил)
@export var dialogue_mixed: Array[DE]

@export var sprite: Sprite2D
@export var shroom_sprites: Array[Sprite2D]

func _ready() -> void:
	# В разрушенной деревне жители не возвращаются после загрузки.
	if Global.get_flag("shroom_village_dissolved"):
		if is_instance_valid(sprite):
			sprite.queue_free()
		for resident in shroom_sprites:
			if is_instance_valid(resident):
				resident.queue_free()
	if Global.get_flag("village_key_given"):
		var area = get_node_or_null(dialogue_area)
		if area:
			area.set_process(false)

func start_chief_dialogue() -> void:
	var area := get_node(dialogue_area) as Area2D
	if area == null:
		printerr("shrump_chief_dialogue: dialogue_area не найден")
		return

	var chosen: Array[DE]
	if Global.shrumps_killed == 0 and Global.shrumps_spared == 0:
		chosen = dialogue_no_encounter
	elif Global.shrumps_killed == 0 and Global.shrumps_spared > 0:
		chosen = dialogue_all_spared
	elif Global.shrumps_killed >= Global.SHRUMPS_TOTAL:
		chosen = dialogue_all_killed
	else:
		chosen = dialogue_mixed  # убил часть, часть пощадил или не встретил

	# Выбранная ветка продолжает текущий разговор сразу после вопроса Яна.
	if not area.call("append_to_active_dialogue", chosen):
		area.call("restart_with_dialogue", chosen)

func give_key() -> void:
	if Global.get_flag("village_key_given"):
		return
	# Сюжетный ключ не должен пропасть при заполненном инвентаре.
	# Флаг также служит связкой ключей для двери, если свободного слота нет.
	var already_owned := Global.items.any(func(item): return item != null and item.resource_path == KEY_ITEM.resource_path)
	if not already_owned:
		Global.add_item(KEY_ITEM)
	Global.set_flag("village_key_given")
	Sounds.play("snd_item")
	var area := get_node(dialogue_area) as Area2D
	if area:
		area.has_activated_already = true
		area.set_process(false)

func dissolve(duration: float = 1.5) -> void:
	if sprite == null:
		printerr("shrump_chief_dialogue: sprite не задан")
		return
	await dissolve_sprite(sprite, duration)

func dissolve_all() -> void:
	Global.set_flag("shroom_village_dissolved")
	for s in shroom_sprites:
		if is_instance_valid(s):
			dissolve_sprite(s)

func dissolve_sprite(s: Sprite2D, duration: float = 1.5) -> void:
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://shaders/dissolve.gdshader")
	s.material = mat
	var tween := create_tween()
	tween.tween_method(
		func(v: float): mat.set_shader_parameter("dissolve_amount", v),
		0.0, 1.0, duration
	)
	await tween.finished
	s.queue_free()
