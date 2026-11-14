extends AbstractFighter
class_name Monster

enum Animations {
	HURT, SPARE, FAINT
}

@export_multiline var description := ""
@export var acts: Array[Act] = []

@export var xp_bled := 10
@export var money_dropped := 5
@export var battle_music := "battle"

@export var idle_lines: PackedStringArray
@export_multiline var opening_line_singular := "  * Враг приближается."
@export_multiline var opening_line_plural := "  * Несколько врагов приближаются."


var hurting := false
var dying := false
var mercy_percent := 0.0
var shake := 0.0

var attacks: Array[Node2D] = []

signal mercy_changed(p_new_mercy: float)
signal exit_finished
signal attack_finished
signal spare_visual_finished

var spare_visual_complete := false
var _spare_started := false

func _ready() -> void:
	create_shader("generic_monster")

func _process(p_delta: float) -> void:
	if shake > 0.0:
		shake = lerpf(shake, 0.0, 1.0 - pow(0.1, p_delta))
		sprite.position = Vector2(randf_range(-shake, shake), randf_range(-shake, shake))
		if shake <= 0.1:
			shake = 0.0
			sprite.position = Vector2.ZERO

func shake_sprite(amount: float) -> void:
	shake = amount

func do_animation(_p_animation: Animations) -> Signal:
	return get_tree().create_timer(0.1).timeout

func get_opening_line() -> String:
	for monster: Monster in Global.monsters:
		if monster == null or monster == self:
			continue
		return opening_line_plural
	return opening_line_singular

func get_idle_line() -> String:
	if idle_lines.is_empty():
		return "  * Продолжай сражаться!"
	return idle_lines[randi_range(0, idle_lines.size() - 1)]

func set_selected(p_selected: bool) -> void:
	if !mat:
		return
	mat.set_shader_parameter("flash", float(p_selected))

func damage_or_die_animation() -> void:
	if !dying:
		hurting = true
		await do_animation(Animations.HURT)
		hurting = false
	else:
		await do_animation(Animations.HURT)
		shake = 0.0
		await do_animation(Animations.FAINT)
		exit_finished.emit()
		queue_free()

func take_damage(p_character: Character, p_damage: int) -> void:
	var actual_damage := 0
	if p_damage > 0:
		actual_damage = maxi(1, p_damage - get_defense() * 3)
	current_hp -= actual_damage
	Global.tp += 5 * Global.tp_coefficient
	create_text(str(actual_damage) if p_damage > 0 else "МИМО", p_character.icon_color)
	if current_hp <= 0:
		dying = true
		Global.delete_monster(self, Global.DefeatContext.FLEE)

func increase_mercy(p_amount: float) -> void:
	p_amount = minf(p_amount, 1.0 - mercy_percent)
	mercy_percent = minf(1.0, mercy_percent + p_amount)
	create_text("+" + str(int(100.0 * p_amount)) + "%", Global.YELLOW)
	mercy_changed.emit(mercy_percent)

func spare() -> void:
	if _spare_started:
		return
	_spare_started = true
	shake = 0.0
	set_physics_process(false)
	Sounds.play("snd_spare")
	_show_spare_label()

	var effect := preload("res://fighters/monsters/effects/spare_fragments.gd").new()
	add_child(effect)
	if is_instance_valid(sprite) and effect.setup(sprite):
		sprite.visible = false
	else:
		effect.queue_free()
		# Safe fallback for monsters without a standard Sprite2D.
		if is_instance_valid(sprite):
			var fade := create_tween()
			fade.tween_property(sprite, "modulate:a", 0.0, 1.2)

	await get_tree().create_timer(1.55).timeout
	spare_visual_complete = true
	spare_visual_finished.emit()

func finish_spare() -> void:
	Global.delete_monster(self, Global.DefeatContext.SPARED)
	exit_finished.emit()
	queue_free()

func _show_spare_label() -> void:
	var label := Label.new()
	label.text = "ПОЩАДА"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size = Vector2(120, 24)
	label.position = Vector2(-60, -65)
	if is_instance_valid(sprite):
		var rect := Rect2()
		if sprite is Sprite2D:
			rect = sprite.get_rect()
		elif sprite is AnimatedSprite2D:
			var animated := sprite as AnimatedSprite2D
			if animated.sprite_frames and animated.sprite_frames.has_animation(animated.animation):
				var frame := animated.sprite_frames.get_frame_texture(animated.animation, animated.frame)
				if frame:
					var origin := animated.offset
					if animated.centered:
						origin -= frame.get_size() * 0.5
					rect = Rect2(origin, frame.get_size())
		if rect.size != Vector2.ZERO:
			var top_left: Vector2 = to_local(sprite.to_global(rect.position))
			var top_right: Vector2 = to_local(sprite.to_global(rect.position + Vector2(rect.size.x, 0)))
			label.position.y = minf(top_left.y, top_right.y) - 26.0
	label.z_index = 20
	var settings := LabelSettings.new()
	settings.font = preload("res://fonts/8bitoperator Cyrillic Extension.ttf")
	settings.font_size = 16
	settings.font_color = Global.YELLOW
	settings.outline_size = 2
	settings.outline_color = Color.BLACK
	label.label_settings = settings
	add_child(label)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 10.0, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.4).set_delay(0.9)

func get_pre_attack_dialogue() -> Array[DE]:
	return []

func start_attack() -> float:
	return 0.1

func end_attack() -> void:
	for attack: Node2D in attacks:
		if attack != null:
			attack.queue_free()
	attacks.clear()

func instantiate_attack(scene: PackedScene) -> void:
	var attack := scene.instantiate()
	get_parent().add_child(attack)
	attack.position = Global.CENTER
	attacks.append(attack)

func get_acts() -> Array[Act]:
	return acts
