extends "res://fighters/monsters/serega/attacks/common/serega_phrases.gd"

func get_duration() -> float:
	return 15.0

func run() -> void:
	await wait(0.7)
	var edge: int = -1
	var gap: int = -1
	var directions: Array[Vector2] = [Vector2.DOWN, Vector2.LEFT, Vector2.UP, Vector2.RIGHT]
	for wave in 4:
		edge = next_edge(edge)
		gap = next_gap(gap)
		var direction: Vector2 = directions[edge]
		var tangent: Vector2 = direction.orthogonal()
		var notes: Array[Node2D] = []
		for i in 11:
			if i >= gap and i < gap + 3:
				continue
			var is_shard: bool = i % 2 == 0
			var origin: Vector2 = -direction * 92.0 + tangent * (-65.0 + float(i) * 13.0)
			var n = shot(origin, direction * 72.0, PINK if is_shard else VIOLET, 14, 1 if is_shard else 0, 4.0)
			n.life = 4.0
			notes.append(n)
		beat()
		await wait(0.85)
		for n in notes:
			if is_instance_valid(n):
				n.set("held", true)
				burst(n.position, PALE)
		await wait(0.65)
		for n in notes:
			if is_instance_valid(n):
				if int(n.get("visual")) == 1:
					var sign_side: float = -1.0 if n.position.dot(tangent) < 0.0 else 1.0
					n.set("velocity", direction * 45.0 + tangent * sign_side * 70.0)
				else:
					n.set("velocity", -n.get("velocity") * 1.35)
				n.set("held", false)
		beat()
		await wait(1.35)
