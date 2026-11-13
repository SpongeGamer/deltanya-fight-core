extends Node2D

const MAIN_MENU_SCENE := "res://scenes/menus/title_screen/title_screen.tscn"

var _cursor_on_continue := true

func _ready() -> void:
	$Continue.grab_focus()
	PostProcessing.fade_in(0.4)          # ← добавить: убираем чёрный CanvasModulate после боя
	await Sounds.fade_out_current(0.2)
	Sounds.set_music("game_over_short", 0.8, false)
	_update_heart()

func _update_heart() -> void:
	if _cursor_on_continue:
		$Heart.position = Vector2(
			$Continue.position.x - 20,
			$Continue.position.y + $Continue.size.y * 0.5
		)
	else:
		$Heart.position = Vector2(
			$Surrender.position.x - 20,
			$Surrender.position.y + $Surrender.size.y * 0.5
		)

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.is_pressed():
		return
	if event.is_action("left") or event.is_action("right"):
		_cursor_on_continue = not _cursor_on_continue
		Sounds.play("snd_menumove")
		_update_heart()
		if _cursor_on_continue:
			$Continue.grab_focus()
		else:
			$Surrender.grab_focus()
	elif event.is_action("confirm") or event.is_action("ui_accept"):
		if _cursor_on_continue:
			_on_continue_pressed()
		else:
			_on_surrender_pressed()

func _on_continue_focus_entered() -> void:
	_cursor_on_continue = true
	Sounds.play("snd_menumove")
	_update_heart()

func _on_surrender_focus_entered() -> void:
	_cursor_on_continue = false
	Sounds.play("snd_menumove")
	_update_heart()

func _on_continue_pressed() -> void:
	Sounds.play("snd_select")
	await Sounds.fade_out_current(0.3)
	if Global.load_game():
		SceneTransition.travel(Global.return_scene_path, "", Global.is_dark_world)
	else:
		_retry_fight()

func _retry_fight() -> void:
	if Global.battle_origin_scene == "" or Global.battle_monster_paths.is_empty():
		SceneTransition.travel(MAIN_MENU_SCENE, "", Global.is_dark_world, false)
		return
	# Полный ХП, как при первом входе в бой
	for key in Global.party:
		if PartyData.equipment.has(key):
			PartyData.equipment[key]["hp"] = -1
	Global.monsters.clear()
	for p in Global.battle_monster_paths:
		Global.monsters.append(load(p).instantiate())
	Global.load_party_characters()
	Global.battle_standalone = true
	SceneTransition.travel("res://scenes/battle/battle.tscn", "", Global.is_dark_world)	

func _on_surrender_pressed() -> void:
	Sounds.play("snd_select")
	await Sounds.fade_out_current(0.3)
	SceneTransition.travel(MAIN_MENU_SCENE, "", Global.is_dark_world, false)
