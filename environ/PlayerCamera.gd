extends Camera2D

var player


func _ready():
	player = $"/root/Helpers".get_first_of_group("playable")
	if player != null:
		global_position = player.global_position


func _process(delta):
	if player == null:
		player = $"/root/Helpers".get_first_of_group("playable")
		return
	
	global_position = Vector2(
		lerp(player.global_position.x, global_position.x, pow(2, -15*delta)),
		lerp(player.global_position.y, global_position.y, pow(2, -15*delta))
	)
