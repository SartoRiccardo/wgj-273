extends KinematicBody2D

export (int) var MAX_SPEED = 200
export (int) var ACCELERATION = 500
export (int) var DECELERATION = 750

enum State { NORMAL, PICKUP, SWIM, HURT, DEAD }

var state = State.NORMAL
var pressed_actions = []
var mov_vector = Vector2.ZERO
var velocity = mov_vector
var speed = 0.0
var interacting_with = null
var lives = 5

func _ready():
	$ActionTimer.connect("timeout", self, "_on_action_timeout")

func _process(delta):
	handle_movement_inputs()
	
	match state:
		State.NORMAL:
			process_normal(delta)
		State.PICKUP:
			process_pickup(delta)
	
	if $HurtBox.get_overlapping_areas().size() > 0:
		if $Invulnerability.time_left == 0:
			lives -= 1
			$Invulnerability.start()
	
func change_state(new_state):
	state = new_state

func process_pickup(delta):
	if Input.is_action_just_released("do_action") or interacting_with == null:
		interacting_with = null
		$ActionTimer.stop()
		change_state(State.NORMAL)
		return

func process_normal(delta):
	if Input.is_action_pressed("do_action"):
		handle_actions()
		if interacting_with != null:
			speed = 0.0
			change_state(State.PICKUP)
			return
		
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

func handle_movement_inputs():
	var movements = ["move_down", "move_up", "move_left", "move_right"]
	
	for evt in movements:
		if Input.is_action_just_pressed(evt):
			pressed_actions.erase(evt)
			pressed_actions.append(evt)
		if Input.is_action_just_released(evt):
			pressed_actions.erase(evt)

func handle_actions():
	var interactables = $ActionRange.get_overlapping_areas()
	if interactables.size() == 0:
		return
	if interacting_with == null:
		for area in interactables:
			var interactable = area.get_parent()
			if interactable.is_pickuppable($Inventory):
				interacting_with = interactables[0].get_parent()
				$ActionTimer.start(interacting_with.time)
				break

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
	
func _on_action_timeout():
	if interacting_with == null:
		return
	interacting_with.consume($Inventory)
	$Inventory.add(interacting_with.item, interacting_with.pickup())
	interacting_with = null
