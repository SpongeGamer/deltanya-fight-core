extends Node2D

enum CONTEXT {
	BATTLE, CHAR_MENU, MONSTER_SELECT, CHAR_SELECT, ITEM_SELECT, ACT_SELECT, MAGIC_SELECT, ACTION, WON
}

class Action:
	var what: int
	var to_monster: Monster
	var to_character: int
	var specific: int
	## индекс предмета внутри списка $ItemSelect (для show_item), отличается от specific
	var item_ui_id: int = -1
	## true когда магический персонаж выбрал «Действия» вместо заклинания
	var uses_acts: bool = false

@onready var menus: Dictionary[CONTEXT, SelectMenu] = {
	CONTEXT.MONSTER_SELECT: $MonsterSelect,
	CONTEXT.CHAR_SELECT: $CharSelect,
	CONTEXT.ITEM_SELECT: $ItemSelect,
	CONTEXT.ACT_SELECT: $ActSelect,
	CONTEXT.MAGIC_SELECT: $MagicSelect
}

var context := CONTEXT.BATTLE:
	set(p_context):
		if CONTEXT.MONSTER_SELECT <= context and context <= CONTEXT.MAGIC_SELECT:
			menus[context].focused = false
		match context:
			CONTEXT.CHAR_MENU:
				char_menus[current_char].focused = false
			CONTEXT.ACTION:
				for character: Character in Global.characters:
					if character.alive and !character.defending:
						character.return_to_idle()
		context = p_context
		match context:
			CONTEXT.BATTLE:
				get_parent().start_attack()
			CONTEXT.CHAR_MENU:
				char_menus[current_char].activate()
				Global.characters[current_char].return_to_idle()
			CONTEXT.ACT_SELECT:
				$ActSelect.clear_items()
				var target_monster = actions[current_char].to_monster
				if target_monster:
					var acts := Global.characters[current_char].get_acts(target_monster)
					for act: Act in acts:
						$ActSelect.add_item(act.title)
			CONTEXT.MAGIC_SELECT:
				$MagicSelect.clear_items()
				# Первым пунктом — «Действия», только если персонаж может делать ACT
				if Global.characters[current_char].can_act:
					$MagicSelect.add_item("Действия", "Действия персонажа", 0.0)
				for spell: Spell in Global.characters[current_char].get_spells():
					$MagicSelect.add_item(spell.title, spell.description, spell.tp_percent_cost)
			CONTEXT.ACTION:
				$TextBox.hide_text()
				for char_menu: CharMenu in char_menus:
					if char_menu.selected_item != Global.DEFEND:
						char_menu.deconfirm_action()
				current_char = -1
				do_next_action()
		if CONTEXT.MONSTER_SELECT <= context and context <= CONTEXT.MAGIC_SELECT:
			menus[context].visible = true
			menus[context].selected_coords = Vector2.ZERO
			menus[context].focused = true

var char_menus: Array[CharMenu] = []
var current_char := 0
var actions: Array[Action] = []
var continue_battle := true
var battle_item_map: Array[int] = []

func _ready() -> void:
	for character: Character in Global.characters:
		var char_menu := preload("res://ui/battle/char_menu/char_menu.tscn").instantiate()
		char_menu.set_from_character(character)
		$Characters.add_child(char_menu)
		char_menus.append(char_menu)
		actions.append(Action.new())
	for i in Global.items.size():
		var item: Item = Global.items[i]
		if item != null and item.inventory_tab == Item.InventoryTab.ITEMS:
			$ItemSelect.add_item(item.name, item.short_description)
			battle_item_map.append(i)
	context = CONTEXT.CHAR_MENU

func _unhandled_key_input(event: InputEvent) -> void:
	if (Global.displaying_text and $TextBox.require_input) or context == CONTEXT.BATTLE or context == CONTEXT.ACTION or !continue_battle:
		return
	if (event.is_action("confirm") or event.is_action("cancel")) and event.is_pressed():
		if event.is_action("cancel"):
			undo_input()
			return
		
		Sounds.play("snd_select")
		
		if CONTEXT.MONSTER_SELECT <= context:
			if context == CONTEXT.MONSTER_SELECT:
				actions[current_char].to_monster = menus[context].get_current_monster()
			elif context == CONTEXT.CHAR_SELECT:
				actions[current_char].to_character = menus[context].get_current_id()
			elif context == CONTEXT.ITEM_SELECT:
				var ui_id := menus[context].get_current_id()
				actions[current_char].specific = battle_item_map[ui_id] if ui_id < battle_item_map.size() else ui_id
				actions[current_char].item_ui_id = ui_id
			elif context == CONTEXT.ACT_SELECT:
				actions[current_char].specific = menus[context].get_current_id()
			# MAGIC_SELECT обрабатывается ниже вручную, чтобы отделить «Действия» от заклинаний
		
		match context:
			CONTEXT.CHAR_MENU:
				queue_character_action()
				return
			CONTEXT.MONSTER_SELECT:
				if actions[current_char].what == Global.ACT:
					# Идём в ACT_SELECT если: персонаж не маг ИЛИ маг выбрал «Действия»
					if !char_menus[current_char].uses_magic or actions[current_char].uses_acts:
						context = CONTEXT.ACT_SELECT
						return
					else:
						next_char()
						return
				if actions[current_char].what == Global.SPARE:
					Global.characters[current_char].prep_spare()
					next_char()
					return
				Global.characters[current_char].prep_attack()
				next_char()
				return
			CONTEXT.CHAR_SELECT:
				if actions[current_char].what != Global.ACT or !char_menus[current_char].uses_magic:
					Global.characters[current_char].prep_item()
				next_char()
				return
			CONTEXT.ACT_SELECT:
				Global.characters[current_char].prep_act()
				next_char()
				return
			CONTEXT.MAGIC_SELECT:
				var magic_id := menus[CONTEXT.MAGIC_SELECT].get_current_id()
				var has_act_item := Global.characters[current_char].can_act
				
				if has_act_item and magic_id == 0:
					# Выбрано «Действия» — переходим к выбору монстра как обычный ACT
					actions[current_char].uses_acts = true
					context = CONTEXT.MONSTER_SELECT
					return
				
				# Заклинание: если «Действия» есть — смещение на 1, иначе 0
				var spell_idx := magic_id - (1 if has_act_item else 0)
				var spells := Global.characters[current_char].get_spells()
				var spell := spells[spell_idx]
				var tp_cost := Global.tp_percent_to_absolute(spell.tp_percent_cost)
				
				if tp_cost > Global.tp:
					return
				
				actions[current_char].uses_acts = false
				actions[current_char].specific = spell_idx
				Global.tp -= tp_cost
				context = CONTEXT.CHAR_SELECT if spell.target == 0 else CONTEXT.MONSTER_SELECT
				Global.characters[current_char].prep_act()
				return
			CONTEXT.ITEM_SELECT:
				$ItemSelect.show_item(actions[current_char].item_ui_id, false)
				context = CONTEXT.CHAR_SELECT
				return

func undo_input() -> void:
	match context:
		CONTEXT.CHAR_MENU:
			if current_char == 0:
				return
			for i in range(current_char - 1, -1, -1):
				if Global.characters[i].alive:
					char_menus[current_char].deactivate()
					current_char = i
					break
				if i == 0:
					return
			if actions[current_char].what == Global.ITEM:
				$ItemSelect.show_item(actions[current_char].item_ui_id, true)
			elif actions[current_char].what == Global.ACT:
				if Global.characters[current_char].uses_magic and !actions[current_char].uses_acts:
					# Возвращаем TP только если был выбран spell, не «Действия»
					var has_act_item := Global.characters[current_char].can_act
					var magic_id := menus[CONTEXT.MAGIC_SELECT].get_current_id()
					var spell_idx := magic_id - (1 if has_act_item else 0)
					var spells := Global.characters[current_char].get_spells()
					if spell_idx >= 0 and spell_idx < spells.size():
						var spell := spells[spell_idx]
						var tp_cost := Global.tp_percent_to_absolute(spell.tp_percent_cost)
						Global.tp += tp_cost
			elif actions[current_char].what == Global.DEFEND:
				Global.tp -= 40
			char_menus[current_char].activate()
			char_menus[current_char].deconfirm_action()
			Global.characters[current_char].return_to_idle()
			return
		CONTEXT.CHAR_SELECT, CONTEXT.MONSTER_SELECT:
			if actions[current_char].what == Global.ITEM:
				$ItemSelect.show_item(actions[current_char].item_ui_id, true)
				context = CONTEXT.CHAR_MENU
				return
			if actions[current_char].what == Global.ACT and char_menus[current_char].uses_magic:
				if actions[current_char].uses_acts:
					# Возвращаемся в MAGIC_SELECT без возврата TP (его не тратили)
					actions[current_char].uses_acts = false
					context = CONTEXT.MAGIC_SELECT
				else:
					# Возвращаем TP за заклинание
					var has_act_item := Global.characters[current_char].can_act
					var magic_id := menus[CONTEXT.MAGIC_SELECT].get_current_id()
					var spell_idx := magic_id - (1 if has_act_item else 0)
					var spells := Global.characters[current_char].get_spells()
					if spell_idx >= 0 and spell_idx < spells.size():
						var spell := spells[spell_idx]
						var tp_cost := Global.tp_percent_to_absolute(spell.tp_percent_cost)
						Global.tp += tp_cost
					context = CONTEXT.MAGIC_SELECT
				return
		CONTEXT.ACT_SELECT:
			context = CONTEXT.MONSTER_SELECT
			return
	if (CONTEXT.MONSTER_SELECT <= context and context <= CONTEXT.ITEM_SELECT) or context == CONTEXT.MAGIC_SELECT:
		context = CONTEXT.CHAR_MENU

func queue_character_action() -> void:
	match char_menus[current_char].selected_item:
		Global.FIGHT:
			actions[current_char].what = Global.FIGHT
			context = CONTEXT.MONSTER_SELECT
		Global.ACT:
			actions[current_char].what = Global.ACT
			actions[current_char].uses_acts = false  # сбрасываем флаг при новом выборе
			if !char_menus[current_char].uses_magic:
				context = CONTEXT.MONSTER_SELECT
			else:
				context = CONTEXT.MAGIC_SELECT
		Global.ITEM:
			if $ItemSelect.has_items:
				actions[current_char].what = Global.ITEM
				context = CONTEXT.ITEM_SELECT
		Global.SPARE:
			actions[current_char].what = Global.SPARE
			context = CONTEXT.MONSTER_SELECT
		Global.DEFEND:
			actions[current_char].what = Global.DEFEND
			Global.characters[current_char].defend()
			Global.tp += 40 * Global.tp_coefficient
			next_char()

func start_turn() -> void:
	for character: Character in Global.characters:
		if !character.alive:
			continue
		if character.defending and character.alive:
			character.return_to_idle()
			character.defending = false
	for char_menu: CharMenu in char_menus:
		char_menu.deconfirm_action()
	var i := 0
	while i < Global.items.size():
		if Global.items[i] == null:
			Global.items.remove_at(i)
		else:
			i += 1
	$ItemSelect.clear_items()
	battle_item_map.clear()
	for idx in Global.items.size():
		var item: Item = Global.items[idx]
		if item != null and item.inventory_tab == Item.InventoryTab.ITEMS:
			$ItemSelect.add_item(item.name, item.short_description)
			battle_item_map.append(idx)
	next_char()

func next_char() -> void:
	if context == CONTEXT.ACTION:
		for character: Character in Global.characters:
			if !character.alive:
				character.heal(ceili(character.get_max_hp() * character.HP_FRACTION_DOWNED_REGEN), false)
	
	var next_character := current_char + 1
	var valid_char := false
	while next_character < char_menus.size():
		if Global.characters[next_character].alive:
			valid_char = true
			break
		next_character += 1
	
	if !valid_char:
		char_menus[current_char].confirm_action(actions[current_char].what)
		char_menus[current_char].deactivate()
		context = CONTEXT.ACTION
	else:
		if current_char != -1:
			char_menus[current_char].deactivate()
			char_menus[current_char].confirm_action(actions[current_char].what)
		current_char = next_character
		context = CONTEXT.CHAR_MENU

func do_next_action() -> void:
	if !continue_battle:
		return
	if current_char == -1:
		var fighting_characters := PackedInt32Array()
		for i: int in actions.size():
			var action := actions[i]
			if action.what == Global.FIGHT and Global.characters[i].alive:
				fighting_characters.append(i)
				$AttackTiming.set_as_attacking(i, true)
			else:
				$AttackTiming.set_as_attacking(i, false)
		current_char = 0
		if !fighting_characters.is_empty():
			$AttackTiming.focused = true
		else:
			do_next_action()
		return
	if current_char >= char_menus.size():
		current_char = 0
		context = CONTEXT.BATTLE
		return
	if !Global.characters[current_char].alive:
		current_char += 1
		do_next_action()
		return
	
	var action := actions[current_char]
	var does_magic := Global.characters[current_char].uses_magic
	
	var target_monster = action.to_monster
	if target_monster == null or target_monster not in Global.monsters:
		for monster in Global.monsters:
			if monster != null:
				target_monster = monster
				break
	
	if target_monster == null:
		current_char += 1
		do_next_action()
		return
	
	match action.what:
		Global.ACT:
			# Используем do_act если: персонаж не маг ИЛИ маг выбрал «Действия»
			if !does_magic or action.uses_acts:
				Global.characters[current_char].do_act(
					target_monster, action.specific
				)
				await Global.characters[current_char].act_finished
			else:
				var spell := Global.characters[current_char].get_spells()[action.specific]
				var entity: Node2D
				if spell.target == 0:
					entity = Global.characters[action.to_character]
				else:
					entity = target_monster
				Global.characters[current_char].do_spell(
					entity, spell
				)
				await Global.characters[current_char].spell_finished
		Global.ITEM:
			Global.characters[current_char].use_item(
				Global.characters[action.to_character], action.specific
			)
			await Global.characters[current_char].item_used
		Global.SPARE:
			Global.characters[current_char].do_spare(
				target_monster
			)
			await Global.characters[current_char].spare_finished
	current_char += 1
	do_next_action()

func do_attack(p_char_id: int, p_damage: int) -> void:
	var monster = actions[p_char_id].to_monster
	if monster == null or monster not in Global.monsters:
		for m in Global.monsters:
			if m != null:
				monster = m
				break
	
	if monster == null:
		do_next_action()
		return
	
	var character := Global.characters[p_char_id]
	character.do_attack(monster, p_damage)
