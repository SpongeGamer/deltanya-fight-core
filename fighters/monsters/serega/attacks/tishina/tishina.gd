extends Node2D
# «Тишина» — финальная, самая сложная атака Тёмного Серёги.
#
# Механика:
#   1. Арена постепенно темнеет (CanvasModulate или ScreenFlash — см. ниже).
#   2. «Невидимые» снаряды: большую часть времени прозрачные,
#      раз в ~1.2 секунды коротко мигают (0.12 с) — предупреждая игрока.
#   3. «Призраки» — ноты, которые медленно преследуют душу,
#      видимые, но полупрозрачные и почти бесшумные.
#   4. Финальный «вскрик» — в конце все скрытые снаряды
#      мгновенно становятся видимыми и ускоряются.
#
# Примечание по затемнению: используем CanvasLayer/ColorRect overlay —
# если в вашем движке есть готовый ScreenOverlay, используйте его.
# Здесь создаём ColorRect прямо в ноде (z_index высокий, не перекрывает UI).

const CAGE_NORMAL  := Vector2(150.0, 150.0)
const CAGE_WIDE    := Vector2(175.0, 165.0)

# ── Тайминги ──────────────────────────────────────────────────────────────────
const DARKEN_DURATION:   float = 2.5   # секунд на затемнение
const DARK_ALPHA_MAX:    float = 0.72  # максимальная непрозрачность оверлея
const ATTACK_DURATION:   float = 11.0  # общая длительность атаки
const REVEAL_TIME:       float = 10.0  # момент финального вскрика

# ── Невидимые снаряды ─────────────────────────────────────────────────────────
const HIDDEN_COUNT:      int   = 14
const HIDDEN_SPAWN_INT:  float = 0.55   # интервал спавна скрытых снарядов

# ── Призраки ──────────────────────────────────────────────────────────────────
const GHOST_COUNT:       int   = 4
const GHOST_SPAWN_INT:   float = 2.0

# ── Состояние ─────────────────────────────────────────────────────────────────
var total_timer:         float = 0.0
var hidden_timer:        float = 0.3
var ghost_timer:         float = 1.0
var hidden_spawned:      int   = 0
var ghost_spawned:       int   = 0
var revealed:            bool  = false
var done:                bool  = false
var cleaned_up:          bool  = false

var soul_cage = null
var soul:      Soul = null

# Оверлей затемнения
var dark_overlay: ColorRect = null


func _ready() -> void:
	z_index = 4

	soul = get_tree().get_first_node_in_group("soul") as Soul
	if soul:
		soul_cage = soul.get_parent().get_node_or_null("SoulCage")
	if soul_cage:
		soul_cage.resize(CAGE_WIDE)

	# Создаём тёмный оверлей поверх арены (но под UI)
	dark_overlay = ColorRect.new()
	dark_overlay.color      = Color(0.0, 0.0, 0.05, 0.0)   # почти чёрный, начинаем с нуля
	dark_overlay.size       = Vector2(400.0, 300.0)
	dark_overlay.position   = Vector2(-200.0, -150.0)
	dark_overlay.z_index    = 4
	dark_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dark_overlay)


func _physics_process(delta: float) -> void:
	total_timer += delta

	# ── Затемнение ────────────────────────────────────────────────────────────
	if dark_overlay != null and is_instance_valid(dark_overlay):
		var t: float = clampf(total_timer / DARKEN_DURATION, 0.0, 1.0)
		# Убираем затемнение в конце (финальный вскрик)
		if total_timer >= REVEAL_TIME:
			var fade_t: float = clampf((total_timer - REVEAL_TIME) / 0.8, 0.0, 1.0)
			dark_overlay.color.a = lerpf(DARK_ALPHA_MAX, 0.0, fade_t)
		else:
			dark_overlay.color.a = lerpf(0.0, DARK_ALPHA_MAX, t)

	if done:
		if !cleaned_up:
			_cleanup()
		return

	# ── Финальный вскрик ──────────────────────────────────────────────────────
	if !revealed and total_timer >= REVEAL_TIME:
		revealed = true
		_do_reveal()

	if total_timer >= ATTACK_DURATION:
		done = true
		return

	# ── Спавн скрытых снарядов ────────────────────────────────────────────────
	if hidden_spawned < HIDDEN_COUNT:
		hidden_timer -= delta
		if hidden_timer <= 0.0:
			hidden_timer = HIDDEN_SPAWN_INT
			_spawn_hidden()
			hidden_spawned += 1

	# ── Спавн призраков ───────────────────────────────────────────────────────
	if ghost_spawned < GHOST_COUNT:
		ghost_timer -= delta
		if ghost_timer <= 0.0:
			ghost_timer = GHOST_SPAWN_INT
			_spawn_ghost()
			ghost_spawned += 1


# ── Скрытый снаряд ────────────────────────────────────────────────────────────
func _spawn_hidden() -> void:
	var bullet := $BaseHidden.duplicate() as TishinaHidden
	bullet.visible = true
	bullet.z_index = 5

	# Спавн у случайного края
	var side: int = randi() % 4
	match side:
		0: 
			bullet.position = Vector2(randf_range(-65.0, 65.0), -88.0)
			bullet.direction = Vector2(randf_range(-0.3, 0.3), 1.0).normalized()
		1: 
			bullet.position = Vector2(randf_range(-65.0, 65.0),  88.0)
			bullet.direction = Vector2(randf_range(-0.3, 0.3), -1.0).normalized()
		2: 
			bullet.position = Vector2(-115.0, randf_range(-55.0, 55.0))
			bullet.direction = Vector2(1.0, randf_range(-0.35, 0.35)).normalized()
		3: 
			bullet.position = Vector2( 115.0, randf_range(-55.0, 55.0))
			bullet.direction = Vector2(-1.0, randf_range(-0.35, 0.35)).normalized()

	bullet.speed = randf_range(52.0, 82.0)
	add_child(bullet)


# ── Призрак ───────────────────────────────────────────────────────────────────
func _spawn_ghost() -> void:
	if soul == null:
		return
	var ghost := $BaseGhost.duplicate() as TishinaGhost
	ghost.visible     = true
	ghost.z_index     = 5
	ghost.soul_target = soul

	# Появляется чуть поодаль от души
	var offset := Vector2(randf_range(-60.0, 60.0), randf_range(-60.0, 60.0))
	ghost.position = (soul.global_position - global_position) + offset
	add_child(ghost)


# ── Финальный вскрик: все скрытые снаряды становятся видимыми и ускоряются ───
func _do_reveal() -> void:
	for child in get_children():
		if child is TishinaHidden:
			child.reveal()


func _exit_tree() -> void:
	if cleaned_up:
		return
	_cleanup()

func _cleanup() -> void:
	cleaned_up = true
	if dark_overlay != null and is_instance_valid(dark_overlay):
		dark_overlay.queue_free()
	if soul_cage != null and is_instance_valid(soul_cage):
		soul_cage.resize(CAGE_NORMAL)
