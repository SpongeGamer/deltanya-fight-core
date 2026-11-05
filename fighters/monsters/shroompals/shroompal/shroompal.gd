extends Monster
class_name ShroomPal
## Шрумп — грибной кот. Шесть атак, первый круг идёт в фиксированном
## порядке (знакомство), дальше — перемешанно и чуть сложнее.
## Перед атакой фраза-подсказка намекает, что будет дальше.

const ATTACK_SCENES: Array[PackedScene] = [
	preload("res://fighters/monsters/shroompals/shroompal/attacks/spore_rain/spore_rain.tscn"),
	preload("res://fighters/monsters/shroompals/shroompal/attacks/mycelium_web/mycelium_web.tscn"),
	preload("res://fighters/monsters/shroompals/shroompal/attacks/round_dance/round_dance.tscn"),
	preload("res://fighters/monsters/shroompals/shroompal/attacks/cap_hop/cap_hop.tscn"),
	preload("res://fighters/monsters/shroompals/shroompal/attacks/purr_waves/purr_waves.tscn"),
	preload("res://fighters/monsters/shroompals/shroompal/attacks/bloom/bloom.tscn"),
]

const HINTS: Array[String] = [
	"  * С потолка капает что-то светящееся.",
	"  * Под полом что-то шевелится. Грибница?",
	"  * Где-то рядом топочут маленькие лапки.",
	"  * Земля под ногами вот-вот прорастёт.\n  * Душа вдруг стала тяжелее.",
	"  * Шрумп мурлычет.\n  * Голубое — замри. Оранжевое — двигайся.",
	"  * Шляпа Шрумпа набухает. Скоро цветение.",
]

const BASE_SCALE := Vector2(0.2, 0.2)

var _queue: Array[int] = []
var _cycle := 0
var _breath := 0.0


func _ready() -> void:
	super()
	_refill_queue()


func _refill_queue(last := -1) -> void:
	_queue.clear()
	for i in ATTACK_SCENES.size():
		_queue.append(i)
	if _cycle > 0:
		_queue.shuffle()
		if _queue[0] == last:
			_queue.append(_queue.pop_front())


func do_animation(p_animation: Animations) -> Signal:
	match p_animation:
		Animations.HURT:
			$AnimationPlayer.play("hurt")
		Animations.SPARE:
			$AnimationPlayer.play("spare")
		Animations.FAINT:
			$AnimationPlayer.play("die")
	return $AnimationPlayer.animation_finished


func _physics_process(delta: float) -> void:
	if shake > 0.0 or hurting or dying or $AnimationPlayer.is_playing():
		return
	# Дыхание: шляпа чуть приседает и распрямляется.
	_breath += delta * (5.0 if not attacks.is_empty() else 2.4)
	var s := sin(_breath)
	sprite.scale = BASE_SCALE * Vector2(1.0 + 0.025 * s, 1.0 - 0.03 * s)
	sprite.position.y = 1.5 * s


func start_attack() -> float:
	attacks.clear()
	if _queue.is_empty():
		_cycle += 1
		_refill_queue()
	var index: int = _queue.pop_front()
	var attack: ShroomAttack = ATTACK_SCENES[index].instantiate()
	attack.difficulty = mini(_cycle, 2)
	attack.calm = mercy_percent
	attack.position = Global.CENTER
	get_parent().add_child(attack)
	attacks.append(attack)
	if _queue.is_empty():
		_cycle += 1
		_refill_queue(index)
	_cast_flash()
	return attack.get_duration()


func _cast_flash() -> void:
	var tween := create_tween()
	sprite.modulate = Color(1.5, 2.0, 2.0)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.5)


func end_attack() -> void:
	super()
	sprite.modulate = Color.WHITE


func get_idle_line() -> String:
	if mercy_percent >= 0.6 and randf() < 0.4:
		return "  * Шрумп довольно жмурится."
	var next := _queue[0] if not _queue.is_empty() else -1
	if next >= 0 and randf() < 0.65:
		return HINTS[next]
	var line := super()
	return line if line.begins_with(" ") else "  * " + line
