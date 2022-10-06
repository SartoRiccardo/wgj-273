extends Camera2D

var player
var angered_hazards = 0
export (Color) var bg_color = Color.darkcyan

func _ready():
	VisualServer.set_default_clear_color(bg_color)
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

func _on_hazard_angered():
	angered_hazards += 1
	if angered_hazards == 1:
		$AnimationPlayer.stop(true)
		$AnimationPlayer.play("panic")

func _on_hazard_unangered():
	angered_hazards -= 1
	if angered_hazards == 0:
		angered_hazards = 0
		$AnimationPlayer.stop(true)
		$AnimationPlayer.play("panic_end")
		if angered_hazards < 0:
			angered_hazards = 0
