extends Node2D

var rng = RandomNumberGenerator.new()

export (Resource) var interactable_data
export (bool) var enable_tooltip = true
export (bool) var decorative = false
export (NodePath) var collect_sfx_nodepath = "CollectSFX"

onready var progress_bar = $TooltipData/Tooltip/CollectProgress/ColorRect
onready var tooltip = $TooltipData/Tooltip

var rates_are_boosted = false
var despawning = false
var collect_speed_multiplier = 1.0
var collect_sfx_node = null

func _ready():
	rng.randomize()
	var game = Helpers.get_game_node()
	var player = Helpers.get_player()
	if game:
		game.connect("season_change", self, "_on_season_change")
	if not enable_tooltip:
		remove_child($TooltipData)
	elif player:
		player.connect("state_change", self, "_on_player_state_change")
		progress_bar.rect_size = Vector2.ZERO
		$TooltipData/Range.connect("area_entered", self, "_on_player_nearby")
		$TooltipData/Range.connect("area_exited", self, "_on_player_leave")
	if has_node("Sprite"):
		get_node("Sprite").set_use_parent_material(true)
	if interactable_data:
		$Collect.set_wait_time(interactable_data.time)
	if decorative:
		$AnimationPlayer.advance(1.0)
	if has_node(collect_sfx_nodepath):
		collect_sfx_node = get_node(collect_sfx_nodepath)

func _process(_d):
	if enable_tooltip:
		if !$Collect.is_stopped():
			progress_bar.rect_size = Vector2(
				tooltip.rect_size.x * (1 - $Collect.time_left/$Collect.wait_time),
				tooltip.rect_size.y
			)
		else:
			progress_bar.rect_size = Vector2.ZERO
		tooltip.rect_size = Vector2.ZERO

func set_interactable_data(data):
	interactable_data = data
	$Collect.set_wait_time(interactable_data.time / collect_speed_multiplier)

func tooltip_popup():
	if not enable_tooltip:
		return
	tooltip.popup()

func tooltip_retract(force=false):
	if not enable_tooltip and not force:
		return
	tooltip.retract()

func timer():
	return $Collect

func start_collect():
	$Collect.start()
	if collect_sfx_node:
		collect_sfx_node.play()

func stop_collect():
	$Collect.stop()
	$Collect.set_wait_time(interactable_data.time / collect_speed_multiplier)
	if collect_sfx_node:
		collect_sfx_node.stop()

func pickup(inventory):
	if interactable_data.requirement_amount > 0:
		inventory.remove(interactable_data.requirement, interactable_data.requirement_amount)
	var amount_picked
	if interactable_data.fail_chance < rng.randf():
		amount_picked = rng.randi_range(interactable_data.amount_min, interactable_data.amount_max)
	else:
		amount_picked = 0
	if interactable_data.die_on_pickup:
		despawn()
	return amount_picked

func despawn():
	if collect_sfx_node:
		collect_sfx_node.stop()
	$ActionRange.set_monitorable(false)
	$ActionRange.set_monitoring(false)
	delete_tooltip()
	$Tween.interpolate_property(
		self, "position:y", position.y, position.y + Vector2.UP.y*30, 1.0
	)
	$Tween.start()
	$AnimationPlayer.play("despawn")
	yield($AnimationPlayer, "animation_finished")
	queue_free()

func delete_tooltip():
	if enable_tooltip:
		enable_tooltip = false
		$TooltipData/Range.queue_free()
		if Helpers.stepify_vec2($TooltipData/Tooltip.rect_scale, 0.001) != Vector2.ZERO:
			tooltip_retract(true)
			yield ($TooltipData/Tween, "tween_completed")
		remove_child($TooltipData)

func is_pickuppable(inventory):
	return inventory.get_amount(interactable_data.requirement) >= interactable_data.requirement_amount

func set_rates_boosted(boosted: bool):
	rates_are_boosted = boosted
	var contents = get_node_or_null("TooltipData/Tooltip/TooltipContents")
	if !contents:
		return
	elif contents.has_method("set_boosted"):
		contents.set_boosted(boosted)

func _on_player_nearby(_a2d):
	tooltip_popup()

func _on_player_leave(_a2d):
	tooltip_retract()

func _on_season_change(season):
	if interactable_data and \
			interactable_data.exist_in_seasons.size() > 0 and \
			!(season in interactable_data.exist_in_seasons) and \
			not despawning:
		despawning = true
		var despawn_delay = rng.randf_range(10, 15)
		yield (get_tree().create_timer(despawn_delay), "timeout")
		if $VisibilityNotifier2D.is_on_screen():
			yield($VisibilityNotifier2D, "screen_exited")
		queue_free()

const STATE_FLEEING = 2
func _on_player_state_change(state):
	if enable_tooltip:
		$TooltipData/Range.set_monitoring(state != STATE_FLEEING)
