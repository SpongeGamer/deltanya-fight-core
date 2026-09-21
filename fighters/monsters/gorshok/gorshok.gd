extends Monster
class_name Gorshok

const RICOCHET       := preload("res://fighters/monsters/gorshok/attacks/ricochet/ricochet.tscn")
const DEAD_ANARCHIST := preload("res://fighters/monsters/gorshok/attacks/dead_anarchist/dead_anarchist.tscn")
const COTYOL := preload("res://fighters/monsters/gorshok/attacks/kotyol/kotyol.tscn")
const KOSTI := preload("res://fighters/monsters/gorshok/attacks/kosti/kosti.tscn")

var attack_index: int = 0

@export var voice_sound: AudioStream = null
@export var voice_volume_db: int     = 6
@export var voice_pitch_min: float   = 0.8
@export var voice_pitch_max: float   = 1.1

@export_multiline var pre_attack_lines: PackedStringArray = [
	"Слышишь этот ритм?\nДля тебя он последний.",
	"Мертвые не врут.\nЯ проверял.",
	"РАЗ-ДВА-ТРИ-УМРИ!",
	"Концерт начинается.\nВыжившие не предусмотрены.",
	"Я жив покуда, Я верю в чудо.\nНо должен будешь ты умереть!"
]

var _last_line_index: int = -1


func _asp() -> AnimatedSprite2D:
	return $Sprite


func do_animation(p_animation: Animations) -> Signal:
	var asp := _asp()
	var anim := ""
	match p_animation:
		Animations.HURT:  anim = "hurt"
		Animations.SPARE: anim = "spare"
		Animations.FAINT: anim = "die"
	if not anim.is_empty() and asp.sprite_frames != null \
			and asp.sprite_frames.has_animation(anim):
		asp.play(anim)
		return asp.animation_finished
	return super.do_animation(p_animation)


func _set_attack_anim(anim: String, speed: float = 1.0) -> void:
	var asp := _asp()
	asp.speed_scale = speed
	if asp.sprite_frames != null and asp.sprite_frames.has_animation(anim):
		asp.play(anim)


func get_pre_attack_dialogue() -> Array[DE]:
	if pre_attack_lines.is_empty():
		return []

	var idx := _last_line_index
	if pre_attack_lines.size() > 1:
		while idx == _last_line_index:
			idx = randi() % pre_attack_lines.size()
	else:
		idx = 0
	_last_line_index = idx

	var line          := DialogueText.new()
	line.speaker_name  = "Горшок"
	line.text          = pre_attack_lines[idx]
	line.text_speed    = 16.0
	line.text_sound    = voice_sound
	line.text_volume_db        = voice_volume_db
	line.text_volume_pitch_min = voice_pitch_min
	line.text_volume_pitch_max = voice_pitch_max
	# line.speaker_img = preload("res://fighters/monsters/gorshok/res/portrait.png")

	var result: Array[DE] = [line]
	return result


func start_attack() -> float:
	attacks.clear()

	match attack_index:
		0:
			_set_attack_anim("attack_kosti")
			instantiate_attack(KOSTI)
			attack_index = 1
			return 10.0
		
		1:
			_set_attack_anim("attack_cotyol")
			instantiate_attack(COTYOL)
			attack_index = 2
			return 10.0
		2:
			_set_attack_anim("attack_dead_anarchist", 0.7)
			instantiate_attack(DEAD_ANARCHIST)
			attack_index = 3
			return 10.0
		3:
			_set_attack_anim("attack_ricochet")
			instantiate_attack(RICOCHET)
			attack_index = 0
			return 6.0


	return 6.0


func end_attack() -> void:
	super()
	if _asp().sprite_frames != null:
		_asp().play("idle")
	_asp().speed_scale = 1.0
