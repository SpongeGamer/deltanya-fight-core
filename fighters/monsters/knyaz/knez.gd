extends Monster
class_name Knyaz

const BALLADA    := preload("res://fighters/monsters/knyaz/attacks/ballada/ballada.tscn")
const PLYASKA    := preload("res://fighters/monsters/knyaz/attacks/plyaska/plyaska.tscn")
const MARIONETTE := preload("res://fighters/monsters/knyaz/attacks/marionette/marionette.tscn")
const MONOLOG    := preload("res://fighters/monsters/knyaz/attacks/monolog/monolog.tscn")

var attack_index: int = 0

@export var voice_sound: AudioStream = null
@export var voice_volume_db: int = 8
@export var voice_pitch_min: float = 0.9
@export var voice_pitch_max: float = 0.9

@export_multiline var pre_attack_lines: PackedStringArray = [
	"Добро пожаловать на представление.\nБилеты уже куплены. Выхода нет.",
	"А теперь — попляшем!\nРаз-два-три... раз-два-смерть!",
	"Послушай внимательно...\nЭто последнее что ты услышишь.",
	"Какой восхитительный зритель.\nЖаль, что спектакль короткий.",
	"Ты борешься с судьбой?\nОчаровательно. Продолжай.",
	"Жил-был один храбрец.\nИ кончил он плохо.",
	"В сказках всегда побеждает добро.\nНо это не добрая сказка.",
	"Нити такие тонкие.\nТы их не замечал всю жизнь.",
	"Аплодисменты, прошу.\nДля тебя это последний акт.",
	"В этом лесу Я хозяин!"
]

var _last_line_index: int = -1


# ── Хелпер ────────────────────────────────────────────────────────────────────

func _asp() -> AnimatedSprite2D:
	return $AnimatedSprite2D


# ── Анимации ──────────────────────────────────────────────────────────────────

func do_animation(p_animation: Animations) -> Signal:
	var asp := _asp()
	var anim_name := ""
	match p_animation:
		Animations.HURT:  anim_name = "damaged"
		Animations.FAINT: anim_name = "faint"
	if not anim_name.is_empty() and asp.sprite_frames.has_animation(anim_name):
		asp.play(anim_name)
		return asp.animation_finished
	return super.do_animation(p_animation)


func _set_attack_anim(anim_name: String, speed: float = 1.0) -> void:
	var asp := _asp()
	asp.speed_scale = speed
	if asp.sprite_frames.has_animation(anim_name):
		asp.play(anim_name)


# ── Диалог перед атакой ───────────────────────────────────────────────────────

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

	var line := DialogueText.new()
	line.speaker_name          = "Князь"
	line.text                  = pre_attack_lines[idx]
	line.text_speed            = 16.0
	line.text_sound            = voice_sound
	line.text_volume_db        = voice_volume_db
	line.text_volume_pitch_min = voice_pitch_min
	line.text_volume_pitch_max = voice_pitch_max
	line.speaker_img = preload("res://fighters/monsters/knyaz/res/portrait.png")

	var result: Array[DE] = [line]
	return result


# ── Атаки ─────────────────────────────────────────────────────────────────────

func start_attack() -> float:
	attacks.clear()

	match attack_index:
		0:
			_set_attack_anim("attack_ballada")
			instantiate_attack(BALLADA)
			attack_index = 1
			return 7.0
		1:
			_set_attack_anim("attack_plyaska", 1.2)
			instantiate_attack(PLYASKA)
			attack_index = 2
			return 8.0
		2:
			_set_attack_anim("attack_marionette", 0.8)
			instantiate_attack(MARIONETTE)
			attack_index = 3
			return 9.0
		3:
			_set_attack_anim("attack_monolog", 1.5)
			instantiate_attack(MONOLOG)
			attack_index = 0
			return 13.0

	return 7.0


func end_attack() -> void:
	super()
	_asp().play("idle")
	_asp().speed_scale = 1.0
