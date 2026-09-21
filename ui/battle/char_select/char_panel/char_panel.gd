extends SelectPanel
class_name CharPanel

var char_id := 0
var current_hp := 1.0
var max_hp := 1.0

func set_current_hp(p_current_hp: int, p_max_hp: int = 0) -> void:
	current_hp = p_current_hp
	if p_max_hp > 0:
		max_hp = p_max_hp
	$HPFG.scale.x = current_hp / max_hp

func set_max_hp(p_max_hp: int) -> void:
	max_hp = p_max_hp
	$HPFG.scale.x = current_hp / max_hp

func set_from_character(p_character: Character) -> void:
	set_title(p_character.title)
	set_current_hp(p_character.current_hp, p_character.get_max_hp())
	set_max_hp(p_character.get_max_hp())
	char_id = Global.characters.find(p_character)
	p_character.health_changed.connect(_on_health_changed)

func _on_health_changed(new_hp: int, max_hp: int) -> void:
	set_current_hp(new_hp, max_hp)
