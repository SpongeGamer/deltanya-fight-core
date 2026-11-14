extends "res://fighters/monsters/knyaz/attacks/common/knyaz_stage.gd"

const LINES: Array[float] = [-60.0, -30.0, 0.0, 30.0, 60.0]
var original_soul_type: SoulType
var changed_soul := false

func get_duration() -> float:
	return 12.5

func _ready() -> void:
	super._ready()
	if not is_instance_valid(soul) or not is_instance_valid(cage):
		return
	cage.resize(Vector2(280, 150))
	original_soul_type = soul.current_soul_type
	soul.assign_heart_properties(SoulType.PURPLE)
	changed_soul = true
	for beh in soul.behaviors:
		if beh.get("xClamp") != null:
			beh.xClamp = 135.0
	if soul.active:
		for beh in soul.behaviors:
			beh.turn_start()
	run()

func run() -> void:
	await pause_for(0.8)
	for wave in 7:
		var left := (wave + variation) % 2 == 0
		var index := (wave + variation) % 5
		var lane_a := index
		var lane_b := (index + 2) % 5
		var lanes := [lane_a, lane_b]
		if wave % 2 == 1:
			lanes.append((index + 4) % 5)
		await pause_for(0.3)
		for lane in lanes:
			_spawn_note(left, LINES[lane])
		await pause_for(0.85)

func _spawn_note(left: bool, y: float) -> void:
	var bullet := $BaseBullet.duplicate() as StringBullet
	bullet.visible = true
	bullet.position = Vector2(-150.0 if left else 150.0, y)
	bullet.dir = 1.0 if left else -1.0
	bullet.speed = 150.0
	var image := bullet.get_node("Sprite") as Sprite2D
	image.texture = preload("res://fighters/monsters/knyaz/attacks/ballada/res/note_theater.png")
	image.scale = Vector2(1.6, 1.6)
	var hitbox := bullet.get_node("CollisionShape2D") as CollisionShape2D
	hitbox.scale = Vector2(1.25, 1.25)
	image.modulate = Color.WHITE
	field.add_child(bullet)

func _exit_tree() -> void:
	if changed_soul and is_instance_valid(soul) and soul.is_inside_tree():
		if soul.active:
			for beh in soul.behaviors:
				beh.turn_end()
		if original_soul_type:
			soul.assign_heart_properties(original_soul_type)
	if is_instance_valid(cage) and cage.is_inside_tree():
		cage.resize(Vector2(150, 150))
