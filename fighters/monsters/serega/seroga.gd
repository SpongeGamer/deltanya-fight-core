extends Monster
class_name TyomnySeroga

const ATTACK_SCENES: Array[PackedScene] = [
	preload("res://fighters/monsters/serega/attacks/scorelines/scorelines.tscn"),
	preload("res://fighters/monsters/serega/attacks/piano/piano.tscn"),
	preload("res://fighters/monsters/serega/attacks/strings/strings.tscn"),
	preload("res://fighters/monsters/serega/attacks/marks/marks.tscn"),
	preload("res://fighters/monsters/serega/attacks/keys/keys.tscn"),
	preload("res://fighters/monsters/serega/attacks/noktyurn/noktyurn.tscn"),
	preload("res://fighters/monsters/serega/attacks/shadows/shadows.tscn"),
	preload("res://fighters/monsters/serega/attacks/counterpoint/counterpoint.tscn"),
	preload("res://fighters/monsters/serega/attacks/tishina/tishina.tscn"),
	preload("res://fighters/monsters/serega/attacks/echo/echo.tscn")
]
const FINALE := preload("res://fighters/monsters/serega/attacks/finale/finale.tscn")
const ATTACK_ANIMS: Array[String] = ["attack_noktyurn", "attack_disonans", "attack_krescendo", "attack_tishina", "attack_disonans", "attack_noktyurn", "attack_krescendo", "attack_disonans", "attack_tishina", "attack_noktyurn"]
var _next_attack: int = 0
var _finale_pending: bool = false
var _finale_active: bool = false
var _finale_done: bool = false
var _mercy_after_finale: bool = false
var _pulse_tween: Tween

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
	"Сыграй со мной.\nТы все равно проиграешь.",
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
	if _finale_pending and not _finale_done:
		var final_line := DialogueText.new()
		final_line.speaker_name = "Темный Серега"
		final_line.text = "Последний аккорд."
		final_line.text_speed = 18.0
		final_line.text_sound = voice_sound
		final_line.text_volume_db = voice_volume_db
		final_line.text_volume_pitch_min = voice_pitch_min
		final_line.text_volume_pitch_max = voice_pitch_max
		var final_dialogue: Array[DE] = [final_line]
		return final_dialogue
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
	line.speaker_name          = "Темный Серега"
	line.text                  = pre_attack_lines[idx]
	line.text_speed            = 18.0
	line.text_sound            = voice_sound
	line.text_volume_db        = voice_volume_db
	line.text_volume_pitch_min = voice_pitch_min
	line.text_volume_pitch_max = voice_pitch_max

	var result: Array[DE] = [line]
	return result


# ── Атаки ─────────────────────────────────────────────────────────────────────

# A decisive ACT or lethal hit starts the last attack on the next enemy turn.
# No reward or defeat is issued until after it is survived.
func increase_mercy(p_amount: float) -> void:
	if not _finale_done and mercy_percent + p_amount >= 0.999:
		_mercy_after_finale = true
		_finale_pending = true
		var allowed: float = maxf(0.0, 0.98 - mercy_percent)
		if allowed > 0.0:
			super.increase_mercy(allowed)
		return
	super.increase_mercy(p_amount)

func take_damage(p_character: Character, p_damage: int) -> void:
	if _finale_done or dying:
		super.take_damage(p_character, p_damage)
		return
	var actual_damage: int = maxi(1, p_damage - get_defense() * 3) if p_damage > 0 else 0
	if actual_damage >= current_hp and actual_damage > 0:
		var limited_damage: int = maxi(0, current_hp - 1)
		current_hp = 1
		Global.tp += 5 * Global.tp_coefficient
		create_text(str(limited_damage), p_character.icon_color)
		_finale_pending = true
	else:
		super.take_damage(p_character, p_damage)

func start_attack() -> float:
	attacks.clear()
	var attack: Node2D
	if _finale_pending and not _finale_done:
		_finale_pending = false
		_finale_active = true
		attack = FINALE.instantiate() as Node2D
		_set_attack_anim("attack_krescendo", 1.0)
	else:
		var index: int = _next_attack % ATTACK_SCENES.size()
		_next_attack += 1
		attack = ATTACK_SCENES[index].instantiate() as Node2D
		_set_attack_anim(ATTACK_ANIMS[index], 1.0)
	attack.set("variation", 1 if _next_attack > ATTACK_SCENES.size() else 0)
	attack.set("caster", self)
	attack.position = Global.CENTER
	get_parent().add_child(attack)
	attacks.append(attack)
	return float(attack.call("get_duration"))


func attack_pulse() -> void:
	if hurting or dying:
		return
	if is_instance_valid(_pulse_tween):
		_pulse_tween.kill()
	var asp := _asp()
	asp.modulate = Color(1.35, 1.08, 1.28)
	_pulse_tween = create_tween()
	_pulse_tween.tween_property(asp, "modulate", Color.WHITE, 0.22)


func end_attack() -> void:
	super()
	if _finale_active:
		_finale_active = false
		_finale_done = true
		if _mercy_after_finale:
			_mercy_after_finale = false
			super.increase_mercy(1.0 - mercy_percent)
	if is_instance_valid(_pulse_tween):
		_pulse_tween.kill()
	_asp().modulate = Color.WHITE
	_asp().play("idle")
	_asp().speed_scale = 1.0
