extends Node2D

var rng = RandomNumberGenerator.new()

export (Resource) var interactable_data

func _ready():
	rng.randomize()

func pickup():
	var amount_picked = rng.randi_range(interactable_data.amount_min, interactable_data.amount_max)
	if interactable_data.die_on_pickup:
		queue_free()
	return amount_picked

func is_pickuppable(inventory):
	for requirement in interactable_data.requirements:
		if inventory.get_amount(requirement.item) < requirement.amount:
			return false
	return true

func consume(inventory):
	for requirement in interactable_data.requirements:
		inventory.remove(requirement.item, requirement.amount)
