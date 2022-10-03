extends KinematicBody2D

signal angered
signal unangered

export (Array, Resource) var stuns
export (Resource) var hazard_properties

var state = Enums.HazardState.IDLE
var state_is_new = true
var following = null
var wander_target = Vector2.ZERO
var rng = RandomNumberGenerator.new()

var sight = null
var sight_base_angle = 0

func _ready():
	var player = Helpers.get_first_of_group("playable")
	if player:
		self.connect("angered", player, "_on_hazard_angered")
		self.connect("unangered", player, "_on_hazard_unangered")
	$StunTimer.connect("timeout", self, "_on_stun_end")
	$IdleTimer.connect("timeout", self, "_on_idle_timeout")
	
	sight = get_node_or_null("Sight")
	wander_target = global_position
	rng.randomize()

func _process(delta):
	var cur_state = state
	match state:
		Enums.HazardState.IDLE:
			process_idle(delta)
		Enums.HazardState.ANGERED:
			process_angered(delta)
		Enums.HazardState.STUNNED:
			process_stunned(delta)
		Enums.HazardState.ATTACKING:
			process_attacking(delta)
		Enums.HazardState.FLEEING:
			process_fleeing(delta)
	
	if cur_state == state:
		state_is_new = false

func process_idle(delta):
	if self.has_method("_process_idle"):
		call("_process_idle", delta)
	
	wander(delta)
	update_sight(delta)
	check_sight()

func process_angered(delta):
	if self.has_method("_process_angered"):
		call("_process_angered", delta)
	else:
		if following:
			global_position = global_position.move_toward(
				following.global_position, hazard_properties.speed_angered*delta
			)
	
	if following == null:
		change_state(Enums.HazardState.IDLE)
		lose_sight_player()
		return
	
	if check_player_distance():
		return

func process_stunned(delta):
	if self.has_method("_process_stunned"):
		call("_process_stunned", delta)
		
	check_player_distance()

func process_attacking(delta):
	if self.has_method("_process_attacking"):
		call("_process_attacking", delta)

func process_fleeing(delta):
	if self.has_method("_process_fleeing"):
		call("_process_fleeing", delta)
	
func change_state(new_state):
	state = new_state
	state_is_new = true

func lock_on_player():
	add_to_group("angered")
	emit_signal("angered")

func lose_sight_player():
	if is_in_group("angered"):
		remove_from_group("angered")
	emit_signal("unangered")

func check_player_distance():
	if following and global_position.distance_to(following.global_position) > hazard_properties.outrun_distance:
		following = null
		if sight:
			sight.set_enabled(true)
		lose_sight_player()
		if state != Enums.HazardState.STUNNED:
			change_state(Enums.HazardState.IDLE)
		return true
	return false

func get_hit(projectile):
	var item = projectile.type
	for stun in stuns:
		if stun.trigger == item:
			change_state(Enums.HazardState.STUNNED)
			var sprite : AnimatedSprite = get_node_or_null("AnimatedSprite")
			var anim_name = ("stun_%s" % Enums.Item.keys()[item]).to_lower()
			if sprite and sprite.frames.has_animation(anim_name):
				sprite.play(anim_name)
				yield (sprite, "animation_finished")
			$StunTimer.start(stun.stun_seconds)
			
			if self.has_method("_on_hit"):
				call_deferred("_on_hit", item)

func wander(delta):
	if state_is_new:
		wander_target = global_position
	
	if global_position == wander_target:
		if $IdleTimer.time_left == 0:
			var variance = rng.randf_range(-hazard_properties.idle_rand, hazard_properties.idle_rand)
			$IdleTimer.start(hazard_properties.idle_time * (1+variance))
		return
	
	global_position = global_position.move_toward(
		wander_target, hazard_properties.speed_idle*delta
	)

func update_sight(delta):
	if !sight:
		return
	
	if !sight.is_enabled():
		sight.set_enabled(true)
	sight.rotation_degrees += hazard_properties.sight_rotate_speed * delta
	if sight.rotation_degrees > sight_base_angle + hazard_properties.max_sight_angle:
		sight.rotation_degrees -= (hazard_properties.max_sight_angle-hazard_properties.min_sight_angle)

func check_sight():
	if !sight:
		return
	if sight.is_colliding():
		var collider = sight.get_collider()
		if collider.get_parent().is_in_group("playable"):
			following = collider.get_parent()
			sight.set_enabled(false)
			lock_on_player()
			change_state(Enums.HazardState.ANGERED)

func get_throwable_objects(inventory):
	var throwable = []
	for item in inventory.contents.keys():
		for stun in stuns:
			if stun.trigger == item and \
					stun.amount_needed <= inventory.get_amount(item):
				throwable.append(item)
	return throwable

func can_be_hit_by(item, amount):
	var stun = get_stun_for(item)
	return stun != null and stun.amount_needed <= amount

func get_stun_for(item):
	for stun in stuns:
		if stun.trigger == item:
			return stun
	return null

func _on_stun_end():
	if state == Enums.HazardState.STUNNED:
		change_state(Enums.HazardState.ANGERED)

func _on_idle_timeout():
	var angle = rng.randf_range(0, 2*PI)
	var distance = rng.randf_range(hazard_properties.wander_min_radius, hazard_properties.wander_max_radius)
	var path_to_target = Vector2(cos(angle) * distance, sin(angle) * distance)
	wander_target = global_position + path_to_target
	
	var direction = path_to_target.normalized()
	if abs(direction.x) > abs(direction.y):
		sight_base_angle = 180 if direction.x >= 0 else 0
	else:
		sight_base_angle = 270 if direction.y >= 0 else 90
