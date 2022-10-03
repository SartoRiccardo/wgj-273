extends "res://entities/Hazard.gd"

var flee_direction = Vector2.ZERO
var friendly = false

func _ready():
	$AttackRange/CollisionShape2D.shape.set_radius(hazard_properties.attack_range)
	$AttackRange.connect("area_entered", self, "_on_attack_range_entered")
	$Hitbox.connect("area_entered", self, "_on_steal")
	$VisibilityNotifier2D.connect("screen_exited", self, "_on_screen_exited")

func check_sight():
	if friendly:
		return
	if $Sight.is_colliding():
		var collider = $Sight.get_collider()
		if collider.get_parent().is_in_group("playable"):
			following = collider.get_parent()
			$Sight.set_enabled(false)
			$AttackRange.set_monitoring(true)
			change_state(Enums.HazardState.ANGERED)

func update_sight(delta):
	if friendly:
		return
	.update_sight(delta)

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
	
	if following:
		global_position = global_position.move_toward(
			following.global_position, hazard_properties.speed_following*delta
		)

func _process_attacking(delta):  # TODO run in a direction that makes sense
	global_position = global_position.move_toward(
		following.global_position, hazard_properties.speed_angered*delta
	)

func _process_fleeing(delta):
	if flee_direction == Vector2.ZERO:
		var angle_from_player = global_position.angle_to(following.global_position)
		flee_direction = Vector2(cos(angle_from_player), sin(angle_from_player))
	global_position += flee_direction * delta * hazard_properties.speed_angered

func _process_stunned(_delta):
	pass

func _on_hit(item):
	match item:
		Enums.Item.ROCK:
			change_state(Enums.HazardState.FLEEING)
		Enums.Item.FISH:
			lose_sight_player()
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
			hazard_properties.min_inv_steal, hazard_properties.max_inv_steal
		)
		inventory.steal(steal_item, steal_amount)
	else:
		following.get_hurt()
	lose_sight_player()

func _on_screen_exited():
	if state == Enums.HazardState.FLEEING or friendly:
		queue_free()
