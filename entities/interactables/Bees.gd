extends "res://entities/Interactable.gd"

export (int) var bee_amount = 10
const BEE_SCENE = preload("res://environ/Bee.tscn")

func _ready():
	for __ in bee_amount-1:
		var bee = BEE_SCENE.instance()
		$Hive.add_child(bee)
