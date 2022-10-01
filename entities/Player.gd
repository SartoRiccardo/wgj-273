extends KinematicBody2D

export (int) var MAX_SPEED = 200
export (int) var ACCELERATION = 500
export (int) var DECELERATION = 750

var pressed_actions = []
var mov_vector = Vector2.ZERO
var velocity = mov_vector
var speed = 0

func _ready():
	pass

func _process(delta):
	handle_inputs()
	mov_vector = Vector2.ZERO
	for i in range(pressed_actions.size()-1, -1, -1):
		var evt = pressed_actions[i]
		if (evt == "move_down" or evt == "move_up") and mov_vector.y == 0:
			mov_vector.y = Vector2.UP.y if evt == "move_up" else Vector2.DOWN.y
		if (evt == "move_left" or evt == "move_right") and mov_vector.x == 0:
			mov_vector.x = Vector2.LEFT.x if evt == "move_left" else Vector2.RIGHT.x
	mov_vector = mov_vector.normalized()
	update_sprite()
	
	if mov_vector != Vector2.ZERO:
		speed = clamp(speed + ACCELERATION * delta, 0, MAX_SPEED)
	else:
		speed = lerp(0, speed, pow(2, -5*delta))
	velocity = velocity.linear_interpolate(mov_vector*speed, 1/3.0)
	
	velocity = move_and_slide(velocity)
	
	# ------
	
#	var console = $"/root/Helpers".get_first_of_group("console")
#	if console:
#		console.set_text(String(mov_vector))
#		console.add_text("\n" + String(mov_vector == Vector2.ZERO))
#		console.add_text("\n" + String(speed))
#		console.add_text("\n" + String(velocity))
	
	# -----
	

func handle_inputs():
	var movements = ["move_down", "move_up", "move_left", "move_right"]
	
	for evt in movements:
		if Input.is_action_just_pressed(evt):
			pressed_actions.erase(evt)
			pressed_actions.append(evt)
		if Input.is_action_just_released(evt):
			pressed_actions.erase(evt)

func update_sprite():
	if pressed_actions.size() == 0:
		$AnimatedSprite.stop()
		$AnimatedSprite.set_frame(0)
		return
	
	var direction = pressed_actions[pressed_actions.size()-1]
	var flip_h = false
	var anim_name = "walk_down"
	match (direction):
		"move_up":
			anim_name = "walk_up"
		"move_left":
			anim_name = "walk_right"
			flip_h = true
		"move_right":
			anim_name = "walk_right"
	
	if $AnimatedSprite.get_animation() != anim_name:
		$AnimatedSprite.set_animation(anim_name)
	if $AnimatedSprite.is_flipped_h() != flip_h:
		$AnimatedSprite.set_flip_h(flip_h)
	
	if mov_vector == Vector2.ZERO:
		$AnimatedSprite.stop()
		$AnimatedSprite.set_frame(0)
	else:
		$AnimatedSprite.play()
	
