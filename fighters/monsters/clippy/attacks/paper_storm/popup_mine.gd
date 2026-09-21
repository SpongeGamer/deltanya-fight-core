extends Pellet
# Попап-мина: появляется на месте, остаётся, потом исчезает.
# Не движется. Collision включается после fade-in.

@export var lifetime := 2.2
@export var fade_in  := 0.25
@export var fade_out := 0.3

var age := 0.0
var col: CollisionShape2D

func _ready() -> void:
	if !visible:
		return
	col = get_node_or_null("CollisionShape2D")
	if col:
		col.disabled = true   # пока не появился — безопасен
	modulate.a = 0.0

func _physics_process(delta: float) -> void:
	if !visible:
		return
	age += delta

	if age < fade_in:
		modulate.a = age / fade_in
		if col and age > fade_in * 0.8:
			col.disabled = false   # становится опасным в конце появления
	elif age < lifetime - fade_out:
		modulate.a = 1.0
	elif age < lifetime:
		modulate.a = (lifetime - age) / fade_out
	else:
		queue_free()
