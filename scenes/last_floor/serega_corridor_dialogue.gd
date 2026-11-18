extends "res://scripts/overworld/dialogue_area_2d.gd"

# Только повороты: позиции персонажей и текст диалога не меняются.
var _watching := false
var _last_index := -1
var _paused_followers: Array[Companion] = []

func _process(delta: float) -> void:
	super._process(delta)
	if is_instance_valid(_active_dialogue_system):
		if not _watching:
			_watching = true
			for key in ["kate", "egor", "nikita"]:
				var member := OverworldParty.get_companion(key) as Companion
				if is_instance_valid(member) and member.following:
					_paused_followers.append(member)
					member.stop_following()
		var index: int = _active_dialogue_system.current_dialogue_item
		if index != _last_index and index >= 0 and index < _active_dialogue_system.dialogue.size():
			_last_index = index
			var entry: DE = _active_dialogue_system.dialogue[index]
			if entry is DialogueText:
				_turn_group(entry.speaker_name)
	elif _watching:
		_watching = false
		_last_index = -1
		for member in _paused_followers:
			if is_instance_valid(member):
				member.start_following()
		_paused_followers.clear()

func _turn_group(speaker: String) -> void:
	var people: Array[Node2D] = []
	if is_instance_valid(player_node):
		people.append(player_node)
	for member in _paused_followers:
		if is_instance_valid(member):
			people.append(member)
	var key_by_name := {"Катя": "kate", "Егор": "egor", "Никита": "nikita"}
	var actor: Node2D = player_node if speaker == "" else null
	if key_by_name.has(speaker):
		actor = OverworldParty.get_companion(key_by_name[speaker]) as Node2D
	if not is_instance_valid(actor):
		return
	var center := Vector2.ZERO
	var count: int = 0
	for person in people:
		if person != actor:
			_face(person, actor.global_position - person.global_position)
			center += person.global_position
			count += 1
	if count > 0:
		_face(actor, center / float(count) - actor.global_position)

func _face(person, direction: Vector2) -> void:
	if direction.length_squared() < 1.0:
		return
	person.last_direction = direction.normalized()
	person.call("_play_idle_animation")
