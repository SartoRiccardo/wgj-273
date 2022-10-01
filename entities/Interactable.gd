extends Node2D

var rng = RandomNumberGenerator.new()

export (Enums.Item) var item
export (int) var amount_min = 1
export (int) var amount_max = 1
export (float) var time = 1.0
export (bool) var die_on_pickup = true

func _ready():
	rng.randomize()

func pickup():
	var amount_picked = rng.randi_range(amount_min, amount_max)
	if die_on_pickup:
		queue_free()
	return amount_picked

func is_pickuppable(inventory):
	return true

func consume(inventory):
	pass
