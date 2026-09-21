extends Node2D

# Пути к DialogueArea2D всех NPC у которых меняется диалог после боя
const POST_FIGHT_NPCS = [
	"NPC/Zahar/FightDialogue",
	"NPC/Anne2/FightDialogue",
	"NPC/Alina/FightDialogue",
	"NPC/Duck/FightDialogue",
	"NPC/Horse/FightDialogue",
]

func _ready() -> void:
	Global.is_dark_world = true
	Sounds.set_music("garage", 0.3)
	Global.location_name = "Бар Князя"
	Global.player_return_position = Vector2.ZERO
	if Global.get_flag("knyaz_cutscene_done"):
		_set_knyaz_shop_mode()
		_set_post_fight_dialogues()

func start_post_knyaz_cutscene(player: Node) -> void:
	if Global.get_flag("knyaz_cutscene_done"):
		if player:
			player.can_move = true
		return

	var cutscene_area = get_node_or_null("NPC/Knyaz/KnyazCutscene")
	if cutscene_area == null:
		push_error("bar.gd: нода KnyazCutscene не найдена!")
		if player:
			player.can_move = true
		return

	if player:
		player.can_move = true

	Sounds.fade_out_current(1.5)
	await get_tree().create_timer(1.5).timeout

	await cutscene_area._activate_dialogue()

	Global.set_flag("knyaz_cutscene_done")
	_set_knyaz_shop_mode()
	_set_post_fight_dialogues()

	Sounds.set_music("garage", 0.3)

func _set_knyaz_shop_mode() -> void:
	var fight_area = get_node_or_null("NPC/Knyaz/DialogueArea2D2")
	if fight_area:
		fight_area.set_deferred("monitoring", false)
		fight_area.set_deferred("monitorable", false)
		var col = fight_area.get_node_or_null("CollisionShape2D")
		if col:
			col.set_deferred("disabled", true)

	var shop_area = get_node_or_null("NPC/Knyaz/KnyazShopZone")
	if shop_area:
		shop_area.set_deferred("monitoring", true)
		shop_area.set_deferred("monitorable", true)
		var col = shop_area.get_node_or_null("CollisionShape2D")
		if col:
			col.set_deferred("disabled", false)
	else:
		push_error("bar.gd: нода KnyazShopZone не найдена!")

func _set_post_fight_dialogues() -> void:
	# Для каждого NPC: выключаем старый DialogueArea2D,
	# включаем PostFightDialogue рядом с ним (если есть)
	for path in POST_FIGHT_NPCS:
		var old_area = get_node_or_null(path)
		if old_area:
			old_area.set_deferred("monitoring", false)
			old_area.set_deferred("monitorable", false)
			var col = old_area.get_node_or_null("CollisionShape2D")
			if col:
				col.set_deferred("disabled", true)

		# PostFightDialogue — сиблинг рядом, называется PostFightDialogue
		var parent_path = path.get_base_dir()
		var new_area = get_node_or_null(parent_path + "/PostFightDialogue")
		if new_area:
			new_area.set_deferred("monitoring", true)
			new_area.set_deferred("monitorable", true)
			var col = new_area.get_node_or_null("CollisionShape2D")
			if col:
				col.set_deferred("disabled", false)

func _process(_delta: float) -> void:
	pass
