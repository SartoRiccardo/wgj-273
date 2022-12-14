extends KinematicBody2D

signal hurt(lives)
signal hunger(hunger)
signal state_change(state)
signal enter_hut
signal exit_hut

export (int) var MAX_SPEED = 200
export (int) var ACCELERATION = 500
export (int) var DECELERATION = 750
export (int) var SHOOT_RANGE = 250
export (Array, Resource) var edible_items
export (Array, Resource) var buildable_items
export (bool) var dev_detectable = true

const INVENTORY_CHANGE_SCENE = preload("res://ui/InventoryChangeUI.tscn")
const PROJECTILE_SCENE = preload("res://entities/Projectile.tscn")
var PROJECTILE_RES = {
	Enums.Item.ROCK: load("res://resources/projectiles/projectile_rock.tres"),
	Enums.Item.HONEY: load("res://resources/projectiles/projectile_honey.tres"),
	Enums.Item.FISH: load("res://resources/projectiles/projectile_fish.tres")
}
const HUNGER_STAGES = 6

enum State { NORMAL, PICKUP, FLEEING, HUT }

onready var label_full_anim = $InventoryChangeRoot/LabelFull/AnimationPlayer

var state = State.NORMAL
var pressed_actions = []
var mov_vector = Vector2.ZERO
var velocity = mov_vector
var speed = 0.0
var interacting_with = null
var in_water = false
var inv_changes = {}
var inside_hut = null
var buildable_items_idx = 0

var lives = 5.0
var near_campfire = 0
var weather = null
var weather_damage = 0.0
onready var hunger_timeout = $Hunger.wait_time
onready var prev_hunger = HUNGER_STAGES-1

func _ready():
	$ActionTimer.connect("timeout", self, "_on_action_timeout")
	$WaterDetect.add_child($WorldShape.duplicate())
	$WaterDetect.connect("area_entered", self, "_on_water_enter")
	$WaterDetect.connect("area_exited", self, "_on_water_exited")
	$Inventory.connect("amount_change", self, "_on_inventory_change")
	$CampfireDetection.connect("area_entered", self, "_on_campfire_enter")
	$CampfireDetection.connect("area_exited", self, "_on_campfire_exited")
	$BuildingMenu/Tooltip/BuildingMenu.init_from(buildable_items, $Inventory)
	
	if not dev_detectable:
		$DetectionRange.get_child(0).set_disabled(true)

func _process(delta):
	handle_movement_inputs()
	handle_inventory_inputs()
	handle_ui()
	handle_hunger()
	if state != State.HUT:
		handle_weather(delta)
	
	match state:
		State.FLEEING:
			process_fleeing(delta)
		State.NORMAL:
			process_normal(delta)
		State.PICKUP:
			process_pickup(delta)
		State.HUT:
			process_hut(delta)
	
	if $HurtBox.is_monitoring() and $HurtBox.get_overlapping_areas().size() > 0:
		get_hurt()

func change_state(new_state):
	if state != new_state:
		state = new_state
		emit_signal("state_change", state)

func process_pickup(_delta):
	if Input.is_action_just_released("do_action") or interacting_with == null:
		interacting_with = null
		$ActionTimer.stop()
		change_state(State.NORMAL)
		return

func process_normal(delta):
	if Input.is_action_pressed("do_action"):
		handle_actions(Input.is_action_just_pressed("do_action"))
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
	
	if Input.is_action_just_pressed("do_action"):
		handle_actions(Input.is_action_just_pressed("do_action"))

func process_hut(_delta):
	if Input.is_action_just_pressed("do_action"):
		exit_hut()

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
	elif weather in [Enums.Weather.RAIN, Enums.Weather.BLIZZARD]:
		velocity *= 0.8
	
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
		if $BuildingMenu/Tooltip.is_open():
			buildable_items_idx = (buildable_items_idx+1) % buildable_items.size()
			$BuildingMenu/Tooltip/BuildingMenu.select(
				buildable_items[buildable_items_idx], buildable_items_idx, $Inventory
			)
		else:
			$Inventory.equip_next()
	if Input.is_action_just_pressed("prev_inv_item"):
		if $BuildingMenu/Tooltip.is_open():
			buildable_items_idx -= 1
			while buildable_items_idx < 0:
				buildable_items_idx += buildable_items.size()
			$BuildingMenu/Tooltip/BuildingMenu.select(
				buildable_items[buildable_items_idx], buildable_items_idx, $Inventory
			)
		else:
			$Inventory.equip_prev()

func handle_actions(is_just_pressed=false):
	var interactables = $ActionRange.get_overlapping_areas()
	var targets = get_valid_shoot_targets()
	if interacting_with == null:
		var interact_priority = {}
		for i in 4:
			interact_priority[i] = null
		
		# [1] Shoot angered enemies
		var projectile_root = Helpers.get_first_of_group("projectile_root")
		if state == State.FLEEING and targets.size() > 0 and interact_priority[1] == null and \
				projectile_root != null and ($Inventory.equipped in PROJECTILE_RES.keys()):
			var target = Helpers.get_closest_node_to(targets, global_position)
			interact_priority[1] = target
		
		# [3] Build
		if $BuildingMenu/Tooltip.is_open() and is_just_pressed and \
				buildable_items[buildable_items_idx].is_buildable($Inventory) and \
				in_water == buildable_items[buildable_items_idx].on_water:
			interact_priority[3] = buildable_items[buildable_items_idx]
		
		for area in interactables:
			var interactable = area.get_parent()
			
			# [0] Collectibles
			if !interactable.is_in_group("non_collectible") and interactable.is_pickuppable($Inventory) and \
					interact_priority[0] == null and state != State.FLEEING:
				interact_priority[0] = interactable
			
			# [2] Enter the hut
			if interactable.is_in_group("hut") and is_just_pressed and interact_priority[2] == null:
				interact_priority[2] = interactable
		
		if interact_priority[3]:
			var build = interact_priority[3]
			var parent = Helpers.get_first_of_group("collectible_root")
			if parent:
				var build_node = build.building_scene.instance()
				build_node.global_position = global_position
				build.take_materials($Inventory)
				$BuildingMenu/Tooltip.retract()
				parent.add_child(build_node)
		elif interact_priority[2]:
			enter_hut(interact_priority[2])
		elif interact_priority[1]:
			var target = interact_priority[1]
			var projectile = PROJECTILE_SCENE.instance()
			projectile.set_target(target)
			projectile.projectile_data = PROJECTILE_RES[$Inventory.equipped]
			projectile.global_position = global_position
			var stun_data = target.get_stun_for($Inventory.equipped)
			if stun_data:
				$Inventory.remove($Inventory.equipped, stun_data.amount_needed)
			projectile_root.add_child(projectile)
		elif interact_priority[0]:
			interacting_with = interact_priority[0]
			$ActionTimer.start(interacting_with.interactable_data.time)
		elif is_just_pressed:
			eat()

func handle_hunger():
	var time_left = $Hunger.time_left
	var seconds_per_hunger = hunger_timeout/HUNGER_STAGES
	var hunger_points = clamp(
		floor(time_left/seconds_per_hunger), 0, HUNGER_STAGES-1
	)
	if prev_hunger != hunger_points:
		emit_signal("hunger", hunger_points)
		prev_hunger = hunger_points

func handle_weather(delta):
	if weather == Enums.Weather.BLIZZARD and near_campfire <= 0:
		weather_damage += delta * 1/30.0
		if weather_damage >= 1:
			get_hurt()
			weather_damage = 0

func handle_ui():
	if inv_changes.size() > 0:
		var inv_changes_ui = INVENTORY_CHANGE_SCENE.instance()
		inv_changes_ui.generate_from(inv_changes)
		$InventoryChangeRoot.add_child(inv_changes_ui)
		inv_changes = {}
	
	if Input.is_action_just_pressed("build_menu"):
		if $BuildingMenu/Tooltip.is_open():
			$BuildingMenu/Tooltip.retract()
		else:
			$BuildingMenu/Tooltip.popup()

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

func eat():
	var equipped = $Inventory.equipped
	for item in edible_items:
		if item.item == equipped and $Inventory.get_amount(equipped) > 0:
			var hunger_gained = hunger_timeout/HUNGER_STAGES * item.points_filled
			if hunger_gained+$Hunger.time_left > hunger_timeout:
				label_full_anim.stop(true)
				label_full_anim.play("popup")
				return
			$Inventory.remove(item.item, 1)
			$Hunger.start($Hunger.time_left + hunger_gained)

# TODO optimize, don't do every frame, update only when necessary
func get_valid_shoot_targets():
	var hazards = get_tree().get_nodes_in_group("angered")
	var valid = []
	for hzr in hazards:
		if hzr.global_position.distance_to(global_position) <= SHOOT_RANGE and \
				!hzr.is_in_group("targeted") and \
				hzr.state != Enums.HazardState.STUNNED and \
				hzr.can_be_hit_by($Inventory.equipped, $Inventory.get_amount($Inventory.equipped)):
			valid.append(hzr)
	return valid

func get_inventory():
	return $Inventory

func get_hurt():
	if $Invulnerability.time_left == 0 and lives > 0:
		lives -= 1.0
		emit_signal("hurt", lives)
		$Invulnerability.start()

func enter_hut(hut):
	inside_hut = hut
	var to_disable = [$ActionRange, $HurtBox]
	for area in to_disable:
		area.set_monitoring(false)
		area.set_monitorable(false)
	$DetectionRange.collision_layer = 0
	$AnimatedSprite.set_visible(false)
	global_position = inside_hut.global_position
	speed = 0.0
	velocity = Vector2.ZERO
	change_state(State.HUT)
	inside_hut.connect("decay", self, "exit_hut")
	var game = Helpers.get_game_node()
	if game:
		game.speed_up()
	emit_signal("enter_hut")

func exit_hut():
	if inside_hut == null:
		return
	inside_hut.disconnect("decay", self, "exit_hut")
	var to_enable = [$ActionRange, $HurtBox]
	for area in to_enable:
		area.set_monitoring(true)
		area.set_monitorable(true)
	$DetectionRange.collision_layer = 0b1000000
	$AnimatedSprite.set_visible(true)
	$AnimatedSprite.set_animation("walk_down")
	global_position += Vector2.DOWN*20
	change_state(State.NORMAL)
	var game = Helpers.get_game_node()
	if game:
		game.slow_down()
	emit_signal("exit_hut")

func _on_action_timeout():
	if interacting_with == null:
		return
	$Inventory.add(
		interacting_with.interactable_data.item, interacting_with.pickup($Inventory)
	)
	interacting_with = null

func _on_hazard_angered():
	if state != State.FLEEING and $BuildingMenu/Tooltip.is_open():
		$BuildingMenu/Tooltip.retract()
		
	change_state(State.FLEEING)

func _on_hazard_unangered():
	if get_tree().get_nodes_in_group("angered").size() == 0:
		change_state(State.NORMAL)

func _on_water_enter(_a2d):
	in_water = true

func _on_water_exited(_a2d):
	in_water = false

func _on_inventory_change(item, old_amount, new_amount):
	if item in inv_changes:
		inv_changes[item] += new_amount-old_amount
	else:
		inv_changes[item] = new_amount-old_amount

func _on_weather_change(new_weather):
	weather = new_weather

func _on_campfire_enter(_a2d):
	near_campfire += 1

func _on_campfire_exited(_a2d):
	near_campfire -= 1
