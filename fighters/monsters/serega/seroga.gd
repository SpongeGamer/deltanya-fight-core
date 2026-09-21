extends Monster
class_name TyomnySeroga

const NOKTYURN   := preload("res://fighters/monsters/serega/attacks/noktyurn/noktyurn.tscn")
const DISONANS   := preload("res://fighters/monsters/serega/attacks/disonans/disonans.tscn")
const KRESCENDO  := preload("res://fighters/monsters/serega/attacks/krescendo/krescendo.tscn")
const TISHINA    := preload("res://fighters/monsters/serega/attacks/tishina/tishina.tscn")

var attack_index: int = 0

@export var voice_sound: AudioStream = null
@export var voice_volume_db: int = 6
@export var voice_pitch_min: float = 0.85
@export var voice_pitch_max: float = 1.0

@export_multiline var pre_attack_lines: PackedStringArray = [
	"Ты думал, я устал?\nЯ просто менял тональность.",
	"Эта мелодия...\nОна никогда не заканчивается.",
	"Слышишь тишину?\nВот моя любимая нота.",
	"Каждая фальшивая нота —\nэто маленькая смерть.",
	"Музыка — это боль.\nА боль — это я.",
	"Сыграй со мной.\nТы всё равно проиграешь.",
	"Я написал эту песню\nпока ты спал.",
	"Финальный аккорд\nбудет твоим.",
	"Устал?\nЯ только начинаю.",
	"Тишина — это тоже музыка.\nСамая громкая."
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
	line.speaker_name          = "Тёмный Серёга"
	line.text                  = pre_attack_lines[idx]
	line.text_speed            = 18.0
	line.text_sound            = voice_sound
	line.text_volume_db        = voice_volume_db
	line.text_volume_pitch_min = voice_pitch_min
	line.text_volume_pitch_max = voice_pitch_max

	var result: Array[DE] = [line]
	return result


# ── Атаки ─────────────────────────────────────────────────────────────────────

func start_attack() -> float:
	attacks.clear()

	match attack_index:
		0:
			_set_attack_anim("attack_noktyurn", 1.0)
			instantiate_attack(NOKTYURN)
			attack_index = 1
			return 9.0
		1:
			_set_attack_anim("attack_disonans", 1.1)
			instantiate_attack(DISONANS)
			attack_index = 2
			return 10.0
		2:
			_set_attack_anim("attack_krescendo", 1.3)
			instantiate_attack(KRESCENDO)
			attack_index = 3
			return 11.0
		3:
			_set_attack_anim("attack_tishina", 0.7)
			instantiate_attack(TISHINA)
			attack_index = 0
			return 14.0

	return 9.0


func end_attack() -> void:
	super()
	_asp().play("idle")
	_asp().speed_scale = 1.0
