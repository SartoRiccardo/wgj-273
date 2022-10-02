extends "res://entities/Hazard.gd"

export (int) var speed = 75

func _process(delta):
	var cur_state = state
	match state:
		Enums.HazardState.IDLE:
			process_idle(delta)
		Enums.HazardState.ANGERED:
			process_angered(delta)
		Enums.HazardState.STUNNED:
			process_stunned(delta)
	
	if cur_state == state:
		state_is_new = false

func process_idle(delta):
	wander(delta)
	update_sight(delta)
	check_sight()

func process_angered(delta):
	if following == null:
		change_state(Enums.HazardState.IDLE)
		lose_sight_player()
		return
	
	if check_player_distance():
		return
	global_position += global_position.direction_to(following.global_position) * speed * delta

func process_stunned(_delta):
	check_player_distance()
