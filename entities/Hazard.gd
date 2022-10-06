extends KinematicBody2D

signal angered
signal unangered

export (Array, Resource) var stuns
export (Resource) var hazard_properties

var game = null

var global_speed_multiplier = 1.0
var mov_speed_multiplier = 1.0
var state = Enums.HazardState.IDLE
var state_is_new = true
var following = null
var wander_target = Vector2.ZERO
var rng = RandomNumberGenerator.new()

var sight = null
var sight_base_angle = 0
var despawning = false

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
	$StunTimer.connect("timeout", self, "_on_stun_end")
	$IdleTimer.connect("timeout", self, "_on_idle_timeout")
	$Campfire.connect("area_entered", self, "_on_campfire_entered")
	$Campfire.connect("area_exited", self, "_on_campfire_exited")
	$Water.connect("area_entered", self, "_on_water_entered")
	$Water.connect("area_exited", self, "_on_water_exited")
	$ProjectileInfo/Tooltip/CounterList.init(stuns)
	
	sight = get_node_or_null("Sight")
	wander_target = global_position
	rng.randomize()

func _process(delta):
	update_sprite()
	
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

# Very sloppy, I'm out of time
func update_sprite():
	if !has_node("AnimatedSprite"):
		return
	var sprite = get_node("AnimatedSprite")
	var direction = Vector2.ZERO
	if following:
		direction = (following.global_position - global_position).normalized()
	elif wander_target and wander_target != global_position:
		direction = Helpers.stepify_vec2(wander_target - global_position, 0.001) \
			.normalized()
	if has_method("get_sprite_direction"):
		direction = call("get_sprite_direction", direction)
	
	var flip = direction.x > 0
	if flip != sprite.is_flipped_h() and direction.x != 0:
		sprite.set_flip_h(flip)
	
	if direction == Vector2.ZERO and sprite.is_playing():
		if sprite.frames.has_animation("idle"):
			sprite.play("idle")
		else:
			sprite.set_frame(1)
		sprite.stop()
	elif direction != Vector2.ZERO and !sprite.is_playing():
		sprite.play("walk_left")
		sprite.set_frame(0)

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
				following.global_position,
				hazard_properties.speed_angered * delta * mov_speed_multiplier * global_speed_multiplier
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
	if !is_in_group("angered"):
		$ProjectileInfo/Tooltip.popup()
	add_to_group("angered")
	emit_signal("angered")

func lose_sight_player():
	if is_in_group("angered"):
		remove_from_group("angered")
		$ProjectileInfo/Tooltip.retract()
	emit_signal("unangered")
	if following:
		following = null

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
			$IdleTimer.start(hazard_properties.idle_time * (1+variance) / global_speed_multiplier)
		return
	
	global_position = global_position.move_toward(
		wander_target,
		hazard_properties.speed_idle * delta * mov_speed_multiplier * global_speed_multiplier
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
	var attempts = 0
	var max_attempts = 10
	var success = false
	while not success and attempts < max_attempts:
		var angle = rng.randf_range(0, 2*PI)
		var distance = rng.randf_range(hazard_properties.wander_min_radius, hazard_properties.wander_max_radius)
		var path_to_target = Vector2(cos(angle) * distance, sin(angle) * distance)
		var new_wander_target = global_position + path_to_target
		success = game.is_walkable(new_wander_target)
		if success:  # Is in map
			wander_target = new_wander_target
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
		lose_sight_player()
		change_state(Enums.HazardState.IDLE)

func _on_season_change(season):
	if hazard_properties.exists_in_seasons.size() > 0 and \
			!(season in hazard_properties.exists_in_seasons) and \
			not despawning:
		despawning = true
		var despawn_delay = rng.randf_range(10, 15)
		yield (get_tree().create_timer(despawn_delay), "timeout")
		if $VisibilityNotifier2D.is_on_screen():
			yield($VisibilityNotifier2D, "screen_exited")
		queue_free()
