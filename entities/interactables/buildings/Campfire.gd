extends "res://entities/interactables/Building.gd"

func _decay():
	$Effect.queue_free()
	$Sprite.set_modulate(Color(1, 1, 1, 0.5))
	delete_tooltip()
