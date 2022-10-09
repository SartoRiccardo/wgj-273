extends "res://entities/Interactable.gd"

export (int) var bee_amount = 10
const BEE_SCENE = preload("res://environ/Bee.tscn")

func _ready():
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	for __ in bee_amount-1:
		var bee = BEE_SCENE.instance()
		var bee_pos = Vector2(
			rng.randf_range(-10.0, 10.0),
			rng.randf_range(-10.0, 10.0)
		)
		bee.position = bee_pos
		$Hive.add_child(bee)
