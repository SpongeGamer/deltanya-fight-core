extends Node2D

@onready var soul_cage: StaticBody2D = $SoulCage

var in_attack := false
var turn_timer := 0.0

var total_money := 0
var total_xp := 0
var money_multiplier := 0.0
var _is_ending := false

func _ready() -> void:
	for item in Global.items:
		if item == null or item.usePredicate == null:
			continue
		if item.usePredicate.item == null:
			item.usePredicate.item = item
	set_positions($Characters, Global.characters, Vector2(108.0, 0.0))
	set_positions($Monsters, Global.monsters, Vector2(640.0 - 108.0, 0.0))
	Global.display_text.emit(Global.get_opening_line(), false)
	Global.monster_killed.connect(monster_killed)
	if Global.monster_spared.is_connected(monster_spared):
		Global.monster_spared.disconnect(monster_spared)
	Global.monster_spared.connect(monster_spared)
	
	if not Global.battle_in_progress:
		print("Warning: Battle started without Global.battle_in_progress flag!")
		Global.battle_in_progress = true
	
	for monster: Monster in Global.monsters:
		total_money += monster.money_dropped
		total_xp += monster.xp_bled
		money_multiplier += monster.get_value_from_stat(AbstractFighter.Stats.MONEY_MULTIPLIER)
	
	for player: Character in Global.characters:
		money_multiplier += player.get_value_from_stat(AbstractFighter.Stats.MONEY_MULTIPLIER)
	
	Global.tp = 0.0
	
	Sounds.play("snd_impact", 0.7)
	Sounds.play("snd_weaponpull", 0.8)
	var music := "battle"
	for monster: Monster in Global.monsters:
		if monster != null and monster.battle_music != "":
			music = monster.battle_music
			break
	Sounds.set_music(music, 0.7)

func _process(p_delta: float) -> void:
	if in_attack:
		turn_timer -= p_delta
		if turn_timer <= 0.0:
			in_attack = false
			end_attack()

func set_positions(p_parent: Node, p_nodes: Array, p_offset := Vector2.ZERO):
	var size := p_nodes.size()
	for i in size:
		var node: Node2D = p_nodes[i]
		# Персонажи уже в дереве (Global) — reparent; монстры ещё нигде — add_child
		if node.get_parent() != null:
			node.reparent(p_parent)
		else:
			p_parent.add_child(node)

	if size == 1:
		p_nodes[0].position = Vector2(0.0, Global.CENTER.y) + p_offset
	elif size == 2:
		p_nodes[0].position = Vector2(0.0, Global.CENTER.y - 48.0) + p_offset
		p_nodes[1].position = Vector2(0.0, Global.CENTER.y + 96.0 - 48.0) + p_offset
	else:
		for i in size:
			p_nodes[i].position.x = 0.0
			p_nodes[i].position.y = Global.CENTER.y - 96.0 + 2.0 * 96.0 * i / (size - 1)
			p_nodes[i].position += p_offset

func start_attack() -> void:
	play_heart_animation()
	$Soul.position = ($Characters.get_child(0) as Character).position
	$Soul.visible = true
	var tween := get_tree().create_tween()
	tween.tween_property($Soul, "position", Global.CENTER, 0.25)
	$SoulCage.expand()
	await $SoulCage.finished_animation
	$Soul.active = true
	
	var alive_monsters: Array[Monster] = []
	for monster: Monster in Global.monsters:
		if monster != null:
			alive_monsters.append(monster)
	if alive_monsters.is_empty():
		return
	var monster: Monster = alive_monsters.pick_random()

	# Диалог перед атакой
	var pre_dialogue := monster.get_pre_attack_dialogue()
	if not pre_dialogue.is_empty():
		await _show_battle_dialogue(pre_dialogue)

	turn_timer = monster.start_attack()
	in_attack = true

func end_attack(p_continue_battle := true) -> void:
	for monster: Monster in Global.monsters:
		if monster != null:
			monster.end_attack()
			
	for character: Character in Global.characters:
		if character != null and character.defending:
			character.end_defend()
	
	$Soul.active = false
	var tween := get_tree().create_tween()
	tween.tween_property($Soul, "position", ($Characters.get_child(0) as Character).position, 0.25)
	tween.finished.connect(play_heart_animation)
	$SoulCage.contract()
	await $SoulCage.finished_animation

	if p_continue_battle:
		var still_alive := Global.characters.any(func(c): return c.alive)
		if not still_alive:
			return
		$BottomPanel.current_char = -1
		for char_menu: CharMenu in $BottomPanel.char_menus:
			char_menu.selected_item = 0
		$BottomPanel.start_turn()
		Global.display_text.emit(Global.get_idle_line(), false)

func play_heart_animation() -> void:
	$Soul.visible = false

func hurt(p_damage: int) -> void:
	if _is_ending:
		return
	var alive_characters: Array[Character] = []
	for character: Character in Global.characters:
		if character.alive:
			alive_characters.append(character)
	if alive_characters.is_empty():
		return
	var character: Character = alive_characters.pick_random()
	character.hurt(p_damage)

	# Проверяем живых ПОСЛЕ удара
	var still_alive := Global.characters.any(func(c): return c.alive)
	if not still_alive and not _is_ending:
		_is_ending = true
		await get_tree().create_timer(1.2).timeout
		Global.battle_in_progress = false
		Sounds.fade_out_current(0.35)
		PostProcessing.fade_out()
		await PostProcessing.fade_finished
		queue_free()
		Sounds.play("snd_rudebuster_swing", 0.6)
		get_tree().change_scene_to_file(
			"res://scenes/menus/lost_screen/lost_screen.tscn")

func monster_killed(p_monster: Monster, p_context: Global.DefeatContext) -> void:
	# Отслеживаем исход для Шрумпов
	if p_monster.is_in_group("shrump"):
		Global.shrumps_killed += 1

	if p_context != Global.DefeatContext.SNOWGRAVED:
		total_xp -= p_monster.xp_bled
	
	var monsters_dead := true
	for monster: Monster in Global.monsters:
		if monster != null:
			monsters_dead = false
			break
	if monsters_dead and not _is_ending:
		_is_ending = true
		$BottomPanel.continue_battle = false
		$BottomPanel/AttackTiming.focused = false
		for character: Character in Global.characters:
			character.do_animation(Character.Animations.IDLE)
		var money := (total_money * Global.chapter / 4) * money_multiplier
		Global.gold += money
		Global.last_defeated_monster = p_monster.name.to_lower()
		Global.display_text.emit("  * Вы победили!\n[color=#000]-[/color]Получено %d опыта и %d рублей." % [total_xp, money], true)
		await Global.text_finished
		Sounds.fade_out_current(0.35)
		PostProcessing.fade_out()
		await PostProcessing.fade_finished
		queue_free()

func monster_spared(p_monster: Monster) -> void:
	if p_monster.is_in_group("shrump"):
		Global.shrumps_spared += 1

func _show_battle_dialogue(lines: Array[DE]) -> void:
	var canvas_layer := CanvasLayer.new()
	canvas_layer.layer = 10
	add_child(canvas_layer)

	var ds := preload("res://scenes/prefabs/dialogue_system.tscn").instantiate()
	canvas_layer.add_child(ds)
	ds.dialogue = lines
	ds.next_item = true
	await ds.tree_exited

	canvas_layer.queue_free()
