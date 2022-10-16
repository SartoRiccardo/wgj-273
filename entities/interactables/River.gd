extends "res://entities/Interactable.gd"

signal river_entered
signal river_exited

export (Resource) var interactable_summer
export (Resource) var interactable_half_season

var disabled = false
var player = null
var dams_near_player = 0
var player_is_in_river = false

func _ready():
	var game = Helpers.get_game_node()
	if game:
		game.connect("season_change", self, "_on_season_changed")
		_on_season_changed(game.get_current_season())
	
	var river_area = get_node_or_null("RiverArea")
	if river_area:
		remove_child(river_area)
		$ActionRange.add_child(river_area)
		$TooltipData/Range.add_child(river_area.duplicate())
	player = Helpers.get_player()
	$ActionRange.connect("area_entered", self, "_on_river_entered")
	$ActionRange.connect("area_exited", self, "_on_river_exited")

func _process(_d):
	if player == null:
		return
	
	if !is_instance_valid(player):
		player = null
		return
	
	if enable_tooltip:
		$TooltipData/Range.position = -player.global_position
		$TooltipData.global_position = player.global_position
	
func is_pickuppable(inventory):
	return not disabled and .is_pickuppable(inventory)

# Override
func set_interactable_data(data):
	.set_interactable_data(data)
	$Collect.wait_time /= collect_speed_multiplier

func _on_season_changed(season):
	disabled = false
	var new_data = interactable_half_season
	match season:
		Enums.Season.SUMMER:
			new_data = interactable_summer
		Enums.Season.WINTER:
			disabled = true
	
	set_interactable_data(new_data)
	if enable_tooltip:
		$TooltipData/Tooltip/TooltipContents.interactable_data = new_data
		$TooltipData/Tooltip/TooltipContents.refresh()
		$TooltipData/Range.set_monitoring(not disabled)

func _on_dam_entered(_a2d):
	dams_near_player += 1
	if dams_near_player == 1:
		collect_speed_multiplier *= 2
		set_rates_boosted(true)
		$TooltipData/Tooltip/TooltipContents.set_boosted(true)
		$Collect.set_wait_time(interactable_data.time / collect_speed_multiplier)

func _on_dam_exited(_a2d):
	dams_near_player -= 1
	if dams_near_player <= 0:
		dams_near_player = 0
		collect_speed_multiplier /= 2
		$Collect.set_wait_time(interactable_data.time * collect_speed_multiplier)
		set_rates_boosted(false)
		$TooltipData/Tooltip/TooltipContents.set_boosted(false)

func _on_river_entered(area2d):
	if area2d.get_parent() is Player:
		player_is_in_river = true
		emit_signal("river_entered")

func _on_river_exited(area2d):
	if area2d.get_parent() is Player:
		player_is_in_river = false
		emit_signal("river_exited")
