extends KinematicBody2D

export (int) var MAX_SPEED = 200
export (int) var ACCELERATION = 500
export (int) var DECELERATION = 750
export (int) var SHOOT_RANGE = 250

const PROJECTILE_SCENE = preload("res://entities/Projectile.tscn")
var PROJECTILE_RES = {
	Enums.Item.ROCK: load("res://resources/projectiles/projectile_rock.tres"),
	Enums.Item.HONEY: load("res://resources/projectiles/projectile_honey.tres"),
	Enums.Item.FISH: load("res://resources/projectiles/projectile_fish.tres")
}

enum State { NORMAL, PICKUP, FLEEING }

var state = State.NORMAL
var pressed_actions = []
var mov_vector = Vector2.ZERO
var velocity = mov_vector
var speed = 0.0
var interacting_with = null
var lives = 5
var in_water = false

func _ready():
	$ActionTimer.connect("timeout", self, "_on_action_timeout")
	$WaterDetect.add_child($WorldShape.duplicate())
	$WaterDetect.connect("area_entered", self, "_on_water_enter")
	$WaterDetect.connect("area_exited", self, "_on_water_exited")

func _process(delta):
	handle_movement_inputs()
	handle_inventory_inputs()
	Helpers.writeln_console(State.keys()[state])
	Helpers.writeln_console(str($Inventory))
	Helpers.writeln_console("Equipped: %s - %s" % [Enums.Item.keys()[$Inventory.equipped], $Inventory.get_amount($Inventory.equipped)])
	Helpers.writeln_console("Lives: %s - Invuln: %s" % [lives, $Invulnerability.time_left])
	
	match state:
		State.FLEEING:
			process_fleeing(delta)
		State.NORMAL:
			process_normal(delta)
		State.PICKUP:
			process_pickup(delta)
	
	if $HurtBox.get_overlapping_areas().size() > 0:
		get_hurt()

func change_state(new_state):
	state = new_state

func process_pickup(_delta):
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
			velocity = Vector2.ZERO
			change_state(State.PICKUP)
			return
	
	handle_movement(delta)
	update_sprite()

func process_fleeing(delta):
	handle_movement(delta)
	update_sprite()
	
	Helpers.writeln_console("Targets: %s" % String(get_valid_shoot_targets()))
	if Input.is_action_just_pressed("do_action"):
		var targets = get_valid_shoot_targets()
		if targets.size() > 0:
			var projectile_root = Helpers.get_first_of_group("projectile_root")
			if projectile_root and $Inventory.equipped in PROJECTILE_RES.keys():
				var target = Helpers.get_closest_node_to(targets, global_position)
				var projectile = PROJECTILE_SCENE.instance()
				projectile.set_target(target)
				projectile.projectile_data = PROJECTILE_RES[$Inventory.equipped]
				projectile.global_position = global_position
				var stun_data = target.get_stun_for($Inventory.equipped)
				if stun_data:
					$Inventory.remove($Inventory.equipped, stun_data.amount_needed)
				projectile_root.add_child(projectile)

func handle_movement(delta):
	mov_vector = Vector2.ZERO
	for i in range(pressed_actions.size()-1, -1, -1):
		var evt = pressed_actions[i]
		if (evt == "move_down" or evt == "move_up") and mov_vector.y == 0:
			mov_vector.y = Vector2.UP.y if evt == "move_up" else Vector2.DOWN.y
		if (evt == "move_left" or evt == "move_right") and mov_vector.x == 0:
			mov_vector.x = Vector2.LEFT.x if evt == "move_left" else Vector2.RIGHT.x
	mov_vector = mov_vector.normalized()
	
	if mov_vector != Vector2.ZERO:
		speed = clamp(speed + ACCELERATION * delta, 0, MAX_SPEED)
	else:
		speed = lerp(0, speed, pow(2, -5*delta))
	velocity = velocity.linear_interpolate(mov_vector*speed, 1/3.0)
	if in_water:
		velocity *= 0.2
	
	velocity = move_and_slide(velocity)

func handle_movement_inputs():
	var movements = ["move_down", "move_up", "move_left", "move_right"]
	
	for evt in movements:
		if Input.is_action_just_pressed(evt):
			pressed_actions.erase(evt)
			pressed_actions.append(evt)
		if Input.is_action_just_released(evt):
			pressed_actions.erase(evt)

func handle_inventory_inputs():
	if Input.is_action_just_pressed("next_inv_item") and \
			not Input.is_key_pressed(KEY_SHIFT):
		$Inventory.equip_next()
	if Input.is_action_just_pressed("prev_inv_item"):
		$Inventory.equip_prev()

func handle_actions():
	var interactables = $ActionRange.get_overlapping_areas()
	if interactables.size() == 0:
		return
	if interacting_with == null:
		for area in interactables:
			var interactable = area.get_parent()
			if interactable.is_pickuppable($Inventory):
				interacting_with = interactables[0].get_parent()
				$ActionTimer.start(interacting_with.interactable_data.time)
				break

func update_sprite():
	if pressed_actions.size() == 0:
		$AnimatedSprite.stop()
		$AnimatedSprite.set_frame(1)
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
		$AnimatedSprite.set_frame(1)
	else:
		if !$AnimatedSprite.is_playing():
			$AnimatedSprite.set_frame(0)
		$AnimatedSprite.play()

# TODO optimize, don't do every frame, update only when necessary
func get_valid_shoot_targets():
	var hazards = get_tree().get_nodes_in_group("angered")
	var valid = []
	for hzr in hazards:
		if hzr.global_position.distance_to(global_position) <= SHOOT_RANGE and \
				!hzr.is_in_group("targeted") and \
				hzr.can_be_hit_by($Inventory.equipped, $Inventory.get_amount($Inventory.equipped)):
			valid.append(hzr)
	return valid

func get_inventory():
	return $Inventory

func get_hurt():
	if $Invulnerability.time_left == 0:
		lives -= 1
		$Invulnerability.start()

func _on_action_timeout():
	if interacting_with == null:
		return
	interacting_with.consume($Inventory)
	$Inventory.add(interacting_with.interactable_data.item, interacting_with.pickup())
	interacting_with = null

func _on_hazard_angered():
	change_state(State.FLEEING)

func _on_hazard_unangered():
	if get_tree().get_nodes_in_group("angered").size() == 0:
		change_state(State.NORMAL)

func _on_water_enter(_a2d):
	in_water = true

func _on_water_exited(_a2d):
	in_water = false
