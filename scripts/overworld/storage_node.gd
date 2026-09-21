extends Node2D

signal storage_closed

const StorageMenuScene := preload("res://ui/overworld/storage_menu.tscn")

func _ready() -> void:
	var anim := get_node_or_null("AnimatedSprite2D")
	if anim and anim is AnimatedSprite2D:
		(anim as AnimatedSprite2D).play("idle")


func open_storage() -> void:
	var anim := get_node_or_null("AnimatedSprite2D")
	if anim and anim is AnimatedSprite2D:
		(anim as AnimatedSprite2D).play("open")

	var cl := CanvasLayer.new()
	cl.layer = 20
	get_tree().current_scene.add_child(cl)

	var menu := StorageMenuScene.instantiate()
	cl.add_child(menu)
	menu.closed.connect(func():
		# Возвращаем анимацию сундука обратно в idle
		var a := get_node_or_null("AnimatedSprite2D")
		if a and a is AnimatedSprite2D:
			(a as AnimatedSprite2D).play("idle")
		storage_closed.emit()
		cl.queue_free()
	)
