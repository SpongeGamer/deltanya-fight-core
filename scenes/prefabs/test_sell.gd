extends AnimatedSprite2D

const ShopMenuScene := preload("res://ui/overworld/shop_menu.tscn")

func open_shop(shop_resource: ShopResource) -> void:
	var menu: Control = ShopMenuScene.instantiate()
	menu.open_shop(shop_resource)  # ← передаём игрока
	get_tree().current_scene.add_child(menu)
