extends Node2D

const MAIN_MENU_SCENE := "res://scenes/menus/title_screen/title_screen.tscn"

var _cursor_on_continue := true

func _ready() -> void:
	$Continue.grab_focus()
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
	Sounds.fade_out_current(0.3)
	if Global.load_game():
		SceneTransition.travel(Global.return_scene_path, Global.player_spawn_point)
	else:
		SceneTransition.travel(MAIN_MENU_SCENE, "", Global.is_dark_world, false)

func _on_surrender_pressed() -> void:
	Sounds.play("snd_select")
	await Sounds.fade_out_current(0.3)
	SceneTransition.travel(MAIN_MENU_SCENE, "", Global.is_dark_world, false)
