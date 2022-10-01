extends "res://entities/Hazard.gd"

var max_raycast_angle = 45
var min_raycast_angle = -45
var raycast_rotate_speed = 90*3
var raycast_angle = 0

var speed = 75

var following = null

func _process(delta):
	if following == null:
		process_idle(delta)
	else:
		process_aggro(delta)

func process_idle(delta):
	$Sight.rotation_degrees += raycast_rotate_speed * delta
	if $Sight.rotation_degrees > max_raycast_angle:
		$Sight.rotation_degrees -= (max_raycast_angle-min_raycast_angle)
		
	if $Sight.is_colliding():
		var collider = $Sight.get_collider()
		if collider.get_parent().is_in_group("playable"):
			following = collider.get_parent()

func process_aggro(delta):
	if global_position.distance_to(following.global_position) > distance_to_forget:
		following = null
		return
	
	global_position += global_position.direction_to(following.global_position) * speed * delta

func process_stunned(delta):
	pass
