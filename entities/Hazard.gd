extends KinematicBody2D
class_name Hazard

signal angered
signal unangered

export (Array, Resource) var stuns
export (Resource) var properties

var game = null

var global_speed_multiplier = 1.0
var mov_speed_multiplier = 1.0
var state = Enums.HazardState.IDLE
var state_is_new = true
var wander_finished = true
var following = null
var rng = RandomNumberGenerator.new()
var velocity = Vector2.ZERO

var sight = null
var sight_base_angle = 0
var despawning = false
var spawn_area = null

func _ready():
	var player = Helpers.get_player()
	if player:
		self.connect("angered", player, "_on_hazard_angered")
		self.connect("unangered", player, "_on_hazard_unangered")
		player.connect("enter_hut", self, "_on_player_enter_hut")
	var camera = Helpers.get_camera()
	if camera:
		self.connect("angered", camera, "_on_hazard_angered")
		self.connect("unangered", camera, "_on_hazard_unangered")
	game = Helpers.get_game_node()
	if game:
		game.connect("season_change", self, "_on_season_change")
		game.connect("speed_increase", self, "_on_game_speed_increase")
		game.connect("speed_decrease", self, "_on_game_speed_decrease")
		$NavigationAgent2D.set_navigation(Helpers.get_first_of_group("navigation"))
	$StunTimer.connect("timeout", self, "_on_stun_end")
	$IdleTimer.connect("timeout", self, "_on_idle_timeout")
	$Campfire.connect("area_entered", self, "_on_campfire_entered")
	$Campfire.connect("area_exited", self, "_on_campfire_exited")
	$Water.connect("area_entered", self, "_on_water_entered")
	$Water.connect("area_exited", self, "_on_water_exited")
	$RecalcPath.connect("timeout", self, "_on_retarget")
	$RecalcPath.set_paused(true)
	$ProjectileInfo/Tooltip/CounterList.init(stuns)
	
	sight = get_node_or_null("Sight")
	rng.randomize()

func _process(delta):
	if following and !is_instance_valid(following):
		following = null
	
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
	
	velocity = move_and_slide(velocity)
	
	if cur_state == state:
		state_is_new = false

func process_idle(delta):
	if state_is_new:
		$RecalcPath.set_paused(true)
	
	if self.has_method("_process_idle"):
		call("_process_idle", delta)
	
	wander(delta)
	update_sight(delta)
	check_sight()

func process_angered(delta):
	if state_is_new:
		$RecalcPath.set_paused(false)
		
	if self.has_method("_process_angered"):
		call("_process_angered", delta)
	else:
		if following:
			var direction = global_position.direction_to($NavigationAgent2D.get_next_location())
			var desired_velocity = direction * properties.speed_angered * speed_multiplier()
			velocity += (desired_velocity - velocity) * delta * 4.0
		
	if following == null:
		change_state(Enums.HazardState.IDLE)
		lose_sight_player()
		return
	
	if check_player_distance():
		return

func process_stunned(delta):
	if self.has_method("_process_stunned"):
		call("_process_stunned", delta)
	
	velocity = Helpers.lerp_vec2(Vector2.ZERO, velocity, pow(2, -10*delta))
	check_player_distance()

func process_attacking(delta):
	if state_is_new:
		$RecalcPath.set_paused(false)
		
	if self.has_method("_process_attacking"):
		call("_process_attacking", delta)

func process_fleeing(delta):
	if state_is_new:
		$RecalcPath.set_paused(true)
		
	if self.has_method("_process_fleeing"):
		call("_process_fleeing", delta)
	
func change_state(new_state):
	state = new_state
	state_is_new = true

func lock_on_player():
	if !is_in_group("angered"):
		$ProjectileInfo/Tooltip.popup()
	add_to_group("angered")
	emit_signal("angered")

func lose_sight_player():
	if is_in_group("angered"):
		remove_from_group("angered")
		$ProjectileInfo/Tooltip.retract()
	emit_signal("unangered")

func check_player_distance():
	if following and global_position.distance_to(following.global_position) > properties.outrun_distance:
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
		$NavigationAgent2D.set_target_location(global_position)
	
	if $NavigationAgent2D.is_navigation_finished() or wander_finished:
		wander_finished = true
		if $IdleTimer.time_left == 0:
			var variance = rng.randf_range(-properties.idle_rand, properties.idle_rand)
			$IdleTimer.start(properties.idle_time * (1+variance) / global_speed_multiplier)
		velocity = Helpers.lerp_vec2(Vector2.ZERO, velocity, pow(2, -7*delta))
		return
	
	var direction = global_position.direction_to($NavigationAgent2D.get_next_location())
	var desired_velocity = direction * properties.speed_idle * speed_multiplier()
	velocity += (desired_velocity - velocity) * delta * 4.0

func update_sight(delta):
	if !sight:
		return
	
	if !sight.is_enabled():
		sight.set_enabled(true)
	sight.rotation_degrees += properties.sight_rotate_speed * delta
	if sight.rotation_degrees > sight_base_angle + properties.max_sight_angle:
		sight.rotation_degrees -= (properties.max_sight_angle-properties.min_sight_angle)

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

func speed_multiplier():
	return mov_speed_multiplier * global_speed_multiplier

func _on_stun_end():
	if state == Enums.HazardState.STUNNED:
		change_state(Enums.HazardState.ANGERED)

func _on_idle_timeout():
	if spawn_area and spawn_area.distance_from(global_position) > properties.max_wander_outside_biome:
		var area_point = spawn_area.random_point()
		wander_finished = false
		$NavigationAgent2D.set_target_location(area_point)
		return
	
	var attempts = 0
	var max_attempts = 10
	var success = false
	while not success and attempts < max_attempts:
		var angle = rng.randf_range(0, 2*PI)
		var distance = rng.randf_range(properties.wander_min_radius, properties.wander_max_radius)
		var path_to_target = Vector2(cos(angle) * distance, sin(angle) * distance)
		var wander_target = global_position + path_to_target
		success = game.is_walkable(wander_target)
		if success:  # Is in map
			wander_finished = false
			$NavigationAgent2D.set_target_location(wander_target)
			var direction = path_to_target.normalized()
			if abs(direction.x) > abs(direction.y):
				sight_base_angle = 180 if direction.x >= 0 else 0
			else:
				sight_base_angle = 270 if direction.y >= 0 else 90
		
		attempts += 1

func _on_campfire_entered(_a2d):
	mov_speed_multiplier /= 2.0

func _on_campfire_exited(_a2d):
	mov_speed_multiplier *= 2.0
	
func _on_water_entered(_a2d):
	mov_speed_multiplier *= 0.3

func _on_water_exited(_a2d):
	mov_speed_multiplier /= 0.3

func _on_game_speed_increase(multiplier):
	global_speed_multiplier *= multiplier
	$IdleTimer.start($IdleTimer.time_left/multiplier)

func _on_game_speed_decrease(multiplier):
	global_speed_multiplier /= multiplier
	$IdleTimer.start($IdleTimer.time_left*multiplier)

func _on_player_enter_hut():
	if state in [Enums.HazardState.ATTACKING, Enums.HazardState.ANGERED]:
		change_state(Enums.HazardState.IDLE)

func _on_season_change(season):
	if properties.exists_in_seasons.size() > 0 and \
			!(season in properties.exists_in_seasons) and \
			not despawning:
		despawning = true
		var despawn_delay = rng.randf_range(10, 15)
		yield (get_tree().create_timer(despawn_delay), "timeout")
		if $VisibilityNotifier2D.is_on_screen():
			yield($VisibilityNotifier2D, "screen_exited")
		queue_free()

func _on_retarget():
	if following and is_instance_valid(following):
		$NavigationAgent2D.set_target_location(following.global_position)
