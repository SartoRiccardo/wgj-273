extends Camera2D

var player
var angered_hazards = 0
var mov_target = Vector2.ZERO

func _ready():
	player = Helpers.get_first_of_group("playable")
	if player != null:
		global_position = player.global_position

func _process(delta):
	if player == null:
		player = Helpers.get_first_of_group("playable")
		return
	elif !is_instance_valid(player):
		player = null
		return
	else:
		mov_target = player.global_position
	
	global_position = Vector2(
		lerp(mov_target.x, global_position.x, pow(2, -15*delta)),
		lerp(mov_target.y, global_position.y, pow(2, -15*delta))
	)

func _on_hazard_angered(_hzd):
	angered_hazards += 1
	if angered_hazards == 1:
		$AnimationPlayer.stop(true)
		$AnimationPlayer.play("panic")

func _on_hazard_unangered(_hzd):
	angered_hazards -= 1
	if angered_hazards <= 0:
		$AnimationPlayer.stop(true)
		$AnimationPlayer.play("panic_end")
		if angered_hazards < 0:
			angered_hazards = 0
