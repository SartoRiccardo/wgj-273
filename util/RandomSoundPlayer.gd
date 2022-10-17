extends Node

var rng = RandomNumberGenerator.new()

func _ready():
	rng.randomize()

func play():
	var children = get_children()
	if children.size() == 0:
		return
	
	var success = false
	var tries = 0
	while !success and tries < 3:
		var idx = rng.randi_range(0, children.size()-1)
		var child = children[idx]
		if child.has_method("play"):
			child.play()
			success = true
		tries += 1
