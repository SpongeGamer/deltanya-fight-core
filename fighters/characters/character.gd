extends AbstractFighter
class_name Character

const CHECK_ACT := preload("res://fighters/characters/acts/check/check.tres")

const HP_FRACTION_DOWNED := 1.0 / 2.0
const HP_FRACTION_DOWNED_REGEN := 1.0 / 8.0
const HP_FRACTION_MIN_REVIVED := 1.0 / 6.0

enum Animations {
	IDLE, DAMAGED_IDLE, DAMAGED, DAMAGED_DAMAGED, PREP_ATTACK, PREP_ACT, PREP_ITEM, PREP_SPARE, ATTACK, ACT, USE_ITEM, SPARE, DEFEND, FAINT, REVIVE, SPECIAL_CAT
}

@export var uses_magic := false
## Может ли персонаж использовать обычные ACT-действия (как Криc в Deltarune).
## Для магических персонажей — добавляет пункт «Действия» в список заклинаний.
@export var can_act := true
@export_color_no_alpha var main_color := Color.WHITE
@export_color_no_alpha var icon_color := Color.GRAY
@export var icon: Texture2D = preload("res://ui/battle/char_menu/res/sample_char_icon.png")
@export var willNotEquip : Array[Equippable.Category]
@export var proj : Node2D
## Кадр анимации special_cat на котором запускается снаряд-кот
@export var cat_launch_frame : int = 17

var alive := true
var defending := false
var shake := 0.0
var cat_frame := 0

## The list of default spells the character can use. Only for characters with do_magic set to true.
@export var spells: Array[Spell] = []

signal act_finished
signal spell_finished
signal item_used
signal spare_finished
signal faint_finished

func _ready() -> void:
	create_shader("generic_character")
	health_changed.connect(_on_health_changed)

func _on_health_changed(new_hp: int, max_hp: int) -> void:
	if not is_instance_valid(self) or not is_inside_tree():
		return
	if not alive:
		return
	
	var current_anim = $AnimatedSprite2D.animation
	if current_anim in ["damaged", "damaged_damaged"]:
		return
	
	var health_percent = float(new_hp) / float(max_hp)
	
	if health_percent < 0.5 and alive and not defending:
		if current_anim == "idle":
			do_animation(Animations.DAMAGED_IDLE)
	elif current_anim == "damaged_idle" and alive:
		do_animation(Animations.IDLE)

func create_shader(shaderName : String) -> void:
	super.create_shader(shaderName)
	do_animation(Animations.IDLE)

func swap_armor(p_id: int, p_armor: Equippable) -> void:
	if armors.size() < 2:
		armors.resize(2)
	armors[p_id] = p_armor

func shake_sprite(p_amount: float) -> void:
	shake = p_amount

func do_animation(p_animation: Animations) -> Signal:
	# Мёртвый персонаж не меняет анимацию — только FAINT и REVIVE разрешены
	if not alive and p_animation != Animations.FAINT and p_animation != Animations.REVIVE:
		return faint_finished  # возвращаем любой сигнал чтобы await не сломался
	
	if p_animation == Animations.IDLE and alive and not defending:
		var health_percent = float(current_hp) / float(get_max_hp())
		if health_percent < 0.5:
			p_animation = Animations.DAMAGED_IDLE
	
	return _play_animation(p_animation)
	
# Добавляем виртуальную функцию для переопределения в дочерних классах
func _play_animation(p_animation: Animations) -> Signal:
	# Будет переопределено в anne.gd и других
	return get_tree().create_timer(0.1).timeout

func _process(p_delta: float) -> void:
	if shake > 0.0:
		shake = lerpf(shake, 0.0, 1.0 - pow(0.1, p_delta))
		sprite.position = Vector2(randf_range(-shake, shake), randf_range(-shake, shake))
		if shake <= 0.1:
			shake = 0.0
			sprite.position = Vector2.ZERO

func get_acts(p_monster: Monster) -> Array[Act]:
	var acts: Array[Act] = []
	acts.append(CHECK_ACT)
	var monster_acts := p_monster.get_acts()
	acts.append_array(monster_acts)
	return acts

func get_spells() -> Array[Spell]:
	return spells if !spells.is_empty() else [Spell.new()]

func has_act_actions(p_monster: Monster) -> bool:
	return get_acts(p_monster).size() > 0

func has_magic() -> bool:
	return uses_magic and spells.size() > 0

func prep_attack() -> void:
	do_animation(Animations.PREP_ATTACK)

func prep_act() -> void:
	do_animation(Animations.PREP_ACT)

func prep_item() -> void:
	do_animation(Animations.PREP_ITEM)

func prep_spare() -> void:
	do_animation(Animations.PREP_SPARE)

func do_attack(p_monster: Monster, p_damage: int) -> void:
	if p_monster and !p_monster.dying:
		p_monster.take_damage(self, p_damage)
		p_monster.damage_or_die_animation()
		Sounds.play("snd_laz_c")
	await do_animation(Animations.ATTACK)
	do_animation(Animations.IDLE)
	
func do_cat_attack(p_monster: Monster, p_damage: int) -> void:
	if not is_instance_valid(self) or not is_inside_tree():
		return
	
	var sprite := $AnimatedSprite2D
	if not is_instance_valid(sprite):
		return
	
	sprite.play("special_cat")

	while sprite.is_playing() and sprite.frame < cat_launch_frame:
		await sprite.frame_changed
		if not is_instance_valid(self):
			return

	if not is_instance_valid(p_monster):
		do_animation(Animations.IDLE)
		return
	
	# Используем существующий proj
	if not is_instance_valid(proj):
		print("ERROR: proj is null!")
		do_animation(Animations.IDLE)
		return
	
	# Убеждаемся, что proj не имеет старых подключений
	if proj.hit_target.is_connected(_on_hit_target):
		proj.hit_target.disconnect(_on_hit_target)
	
	# Подключаем сигнал
	proj.hit_target.connect(_on_hit_target.bind(p_monster, p_damage, sprite))
	
	# Запускаем снаряд
	proj.init(p_monster)
	proj.global_position = global_position
	proj.visible = true
	
	# Добавляем на сцену если ещё не добавлен
	if not proj.is_inside_tree():
		var battle = get_tree().get_first_node_in_group("battle")
		(battle if battle else get_parent()).add_child(proj)

## Второй проджектайл — для анимированной палки (или любого другого снаряда).
## Задаётся в дочерней сцене через @export var proj_stick.
## Анимация запускается через "act", снаряд летит на кадре 17 (как у кота — подстрой под свою анимацию).
@export var proj_stick : Node2D
## Кадр анимации act на котором запускается снаряд-палка
@export var stick_launch_frame : int = 5

func do_stick_attack(p_monster: Monster, p_damage: int) -> void:
	if not is_instance_valid(self) or not is_inside_tree():
		return

	var sprite := $AnimatedSprite2D
	if not is_instance_valid(sprite):
		return

	sprite.play("attack")

	# Ждём нужного кадра перед броском — подстрой число под анимацию палки
	while sprite.is_playing() and sprite.frame < stick_launch_frame:
		await sprite.frame_changed
		if not is_instance_valid(self):
			return

	if not is_instance_valid(p_monster):
		do_animation(Animations.IDLE)
		return

	if not is_instance_valid(proj_stick):
		push_error("proj_stick is null — назначь его в инспекторе сцены")
		do_animation(Animations.IDLE)
		return

	if proj_stick.hit_target.is_connected(_on_stick_hit_target):
		proj_stick.hit_target.disconnect(_on_stick_hit_target)

	proj_stick.hit_target.connect(_on_stick_hit_target.bind(p_monster, p_damage, sprite))

	proj_stick.global_position = global_position
	proj_stick.visible = true

	if not proj_stick.is_inside_tree():
		var battle = get_tree().get_first_node_in_group("battle")
		(battle if battle else get_parent()).add_child(proj_stick)

	proj_stick.init(p_monster)


func _on_stick_hit_target(p_monster: Monster, p_damage: int, p_sprite: AnimatedSprite2D) -> void:
	if not is_instance_valid(self):
		return

	if is_instance_valid(proj_stick) and proj_stick.hit_target.is_connected(_on_stick_hit_target):
		proj_stick.hit_target.disconnect(_on_stick_hit_target)

	if is_instance_valid(p_monster) and not p_monster.dying:
		p_monster.take_damage(self, p_damage)
		p_monster.damage_or_die_animation()
		Sounds.play("snd_laz_c")

	if is_instance_valid(proj_stick):
		proj_stick.visible = false

	if is_instance_valid(p_sprite) and p_sprite.is_playing():
		await p_sprite.animation_finished

	if is_instance_valid(self):
		do_animation(Animations.IDLE)

func _on_hit_target(p_monster: Monster, p_damage: int, p_sprite: AnimatedSprite2D) -> void:
	if not is_instance_valid(self):
		return
	
	# Отключаем сигнал чтобы не сработал дважды
	if is_instance_valid(proj) and proj.hit_target.is_connected(_on_hit_target):
		proj.hit_target.disconnect(_on_hit_target)
	
	# Наносим урон
	if is_instance_valid(p_monster) and not p_monster.dying:
		p_monster.take_damage(self, p_damage)
		p_monster.damage_or_die_animation()
		Sounds.play("snd_laz_c")
	
	# Прячем снаряд
	if is_instance_valid(proj):
		proj.visible = false
	
	# Ждём конца анимации
	if is_instance_valid(p_sprite) and p_sprite.is_playing():
		await p_sprite.animation_finished
	
	if is_instance_valid(self):
		do_animation(Animations.IDLE)

func use_item(p_character: Character, p_item: int) -> void:
	await do_animation(Animations.USE_ITEM)
	var item := Global.items[p_item]
	if item == null:
		Global.display_text.emit(title + " пытается использовать уже использованный предмет", true)
		await Global.text_finished
		item_used.emit()
		return
	
	var predicate = item.usePredicate
	if predicate:
		predicate.item = item
		await predicate.use_item(self, p_character)
	
	if item.usePredicate and item.usePredicate.remove_after_use:
		Global.delete_item(p_item)
	
	do_animation(Animations.IDLE)
	item_used.emit()

func get_value_from_stat(stat: Stats) -> int:
	var final_value = base_fighter_stats.get(stat, FALLBACK_STATS.get(stat))
	if weapon:
		final_value += weapon.fighter_stat_modifiers.get(stat, 0)
	for armor in armors:
		if armor:
			final_value += armor.fighter_stat_modifiers.get(stat, 0)
	return final_value

func do_spare(p_monster: Monster) -> void:
	do_animation(Animations.SPARE)
	if p_monster == null:
		do_animation(Animations.IDLE)
		spare_finished.emit()
		return
	if p_monster.mercy_percent >= 0.999:
		p_monster.spare()
		await get_tree().create_timer(0.01).timeout
		Global.display_text.emit("  * " + title + " пощадил " + p_monster.title + "!", true)
		await Global.text_finished
		Sounds.play("snd_spare")
	else:
		await get_tree().create_timer(0.01).timeout
		Global.display_text.emit("  * " + title + " пытался пощадить " + p_monster.title + ", но не смог...", true)
		await Global.text_finished
	do_animation(Animations.IDLE)
	spare_finished.emit()

func defend() -> void:
	defending = true
	do_animation(Animations.DEFEND)
	
func end_defend() -> void:
	defending = false
	# После защиты возвращаем нужную анимацию
	var health_percent = float(current_hp) / float(get_max_hp())
	if health_percent < 0.5 and alive:
		do_animation(Animations.DAMAGED_IDLE)
	else:
		do_animation(Animations.IDLE)

func faint() -> void:
	alive = false
	current_hp = round(-1 * HP_FRACTION_DOWNED * get_max_hp())
	await do_animation(Animations.FAINT)
	faint_finished.emit()

func revive() -> void:
	if current_hp < get_value_from_stat(Stats.MAX_HP) * HP_FRACTION_MIN_REVIVED:
		current_hp = ceili(get_max_hp() * HP_FRACTION_MIN_REVIVED)
	alive = true
	do_animation(Animations.REVIVE)
	await $AnimatedSprite2D.animation_finished
	# После возрождения проверяем здоровье
	var health_percent = float(current_hp) / float(get_max_hp())
	if health_percent < 0.5:
		do_animation(Animations.DAMAGED_IDLE)
	else:
		do_animation(Animations.IDLE)
	faint_finished.emit()  # Добавляем этот сигнал

func hurt(p_damage: int) -> void:
	shake_sprite(4.0)
	p_damage = int(maxi(1, p_damage - 3 * get_defense()) * (1.0 if !defending else 2.0 / 3.0))
	current_hp -= p_damage
	create_text(str(p_damage), Color.WHITE)
	Sounds.play("snd_hurt1")
	
	if current_hp > 0:
		_play_hurt_animation()
	else:
		faint() 

func _play_hurt_animation() -> void:
	var health_percent = float(current_hp) / float(get_max_hp())
	
	# Выбираем анимацию в зависимости от здоровья
	if health_percent < 0.5:
		# Если здоровье уже низкое, используем damaged_damaged
		do_animation(Animations.DAMAGED_DAMAGED)
	else:
		# Иначе обычный damaged
		do_animation(Animations.DAMAGED)
	
	# Ждём окончания анимации урона и возвращаемся в idle/damaged_idle
	await $AnimatedSprite2D.animation_finished
	_check_and_set_idle_animation()
	
func _check_and_set_idle_animation() -> void:
	if not alive:
		return
	return_to_idle()

# Публичный метод — возвращает в idle или damaged_idle в зависимости от HP.
# Использовать везде вместо do_animation(IDLE) напрямую.
func return_to_idle() -> void:
	if not alive:
		return
	var health_percent = float(current_hp) / float(get_max_hp())
	if health_percent < 0.5:
		do_animation(Animations.DAMAGED_IDLE)
	else:
		do_animation(Animations.IDLE)

func heal(p_amount: int, can_revive: bool = true) -> void:
	current_hp += p_amount
	Sounds.play("snd_power")
	if !alive and current_hp >= 0:
		if can_revive:
			revive()
		else:
			current_hp = min(current_hp, -1)  # не даём подняться выше -1
			return
	if current_hp >= get_max_hp():
		current_hp = get_max_hp()
		create_text("MAX", Global.GREEN)
	else:
		create_text(str(p_amount), Global.GREEN)


func do_act(p_monster: Monster, p_act: int) -> void:
	if p_monster == null:
		do_animation(Animations.ACT)
		do_animation(Animations.IDLE)
		act_finished.emit()
		return
	
	var acts := get_acts(p_monster)
	await acts[p_act].do_act(self, p_monster)
	await do_animation(Animations.ACT)
	do_animation(Animations.IDLE)
	act_finished.emit()

func do_spell(p_entity: Node2D, p_spell: Spell) -> void:
	if p_entity == null:
		await do_animation(Animations.ACT)
		do_animation(Animations.IDLE)
		act_finished.emit()
		return
	
	p_spell.do_spell(self, p_entity)

func set_selected(p_selected: bool) -> void:
	if !mat:
		return
	mat.set_shader_parameter("flash", float(p_selected))
