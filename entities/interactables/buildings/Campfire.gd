extends "res://entities/interactables/Building.gd"

func _ready():
	if decorative:
		$AoE.queue_free()

func _decay():
	$Effect.queue_free()
	$AnimationPlayer.play("decay")
	$Sprite.set_modulate(Color(1, 1, 1, 0.5))
	delete_tooltip()
