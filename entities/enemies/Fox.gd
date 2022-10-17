extends "res://entities/Hazard.gd"

var flee_direction = Vector2.ZERO
var friendly = false

func _ready():
	$AttackRange/CollisionShape2D.shape.set_radius(properties.attack_range)
	$AttackRange.connect("area_entered", self, "_on_attack_range_entered")
	$Hitbox.connect("area_entered", self, "_on_steal")
	$VisibilityNotifier2D.connect("screen_exited", self, "_on_screen_exited")

# Override
func _on_sight_collide(collider_parent):
	if friendly:
		return
	if collider_parent is Player:
		following = collider_parent
		$Sight.set_enabled(false)
		$AttackRange.set_monitoring(true)
		change_state(Enums.HazardState.ANGERED)

func _process_idle(_delta):
	if state_is_new:
		$Sight.set_enabled(true and not friendly)
		$AttackRange.set_monitoring(false)
	if friendly and $Sight.is_enabled():
		$Sight.set_enabled(false)

func _process_angered(delta):
	if state_is_new:
		$Sight.set_enabled(false)
		$AttackRange.set_monitoring(true)
	
	if following and is_instance_valid(following):
		var direction = global_position.direction_to($NavigationAgent2D.get_next_location())
		var current_speed = properties.speed_following * mov_speed_multiplier * global_speed_multiplier
		var desired_velocity = direction * current_speed
		velocity += (desired_velocity - velocity) * delta * 4.0

func _process_attacking(delta):
	var direction = global_position.direction_to($NavigationAgent2D.get_next_location())
	var current_speed = properties.speed_angered * speed_multiplier()
	var desired_velocity = direction * current_speed
	velocity += (desired_velocity - velocity) * delta * 4.0

# TODO use NavigationAgent2D
func _process_fleeing(delta):
	if flee_direction == Vector2.ZERO:
		flee_direction = -global_position.direction_to(following.global_position)
	var current_speed = properties.speed_angered * speed_multiplier()
	var desired_velocity = flee_direction * current_speed
	velocity += (desired_velocity - velocity) * delta * 4.0

func _process_stunned(_delta):
	pass

func _on_hit(item):
	match item:
		Enums.Item.ROCK:
			lose_sight_player()
			change_state(Enums.HazardState.FLEEING)
		Enums.Item.FISH:
			lose_sight_player()
			$Hitbox.set_monitoring(false)
			$Hitbox.set_monitorable(false)
			friendly = true

func _on_stun_end():
	if friendly:
		change_state(Enums.HazardState.IDLE)

func _on_attack_range_entered(_a2d):
	$AttackRange.call_deferred("set_monitoring", false)
	$Hitbox.set_monitoring(true)
	change_state(Enums.HazardState.ATTACKING)
	lock_on_player()

func _on_steal(_a2d):
	change_state(Enums.HazardState.FLEEING)
	var inventory = following.get_inventory()
	
	var valid_steal_items = []
	for item in inventory.contents.keys():
		if inventory.contents[item] > 0:
			valid_steal_items.append(item)
	
	if valid_steal_items.size() > 0:
		var steal_item = valid_steal_items[rng.randi_range(0, valid_steal_items.size()-1)]
		var steal_amount = rng.randi_range(
			properties.min_inv_steal, properties.max_inv_steal
		)
		inventory.steal(steal_item, steal_amount)
	else:
		following.get_hurt()
	lose_sight_player()

func _on_screen_exited():
	if state == Enums.HazardState.FLEEING or friendly:
		queue_free()
