extends "res://entities/Interactable.gd"

export (Resource) var interactable_summer
export (Resource) var interactable_half_season
var disabled = false
var player = null

func _ready():
	var game = Helpers.get_game_node()
	game.connect("season_change", self, "_on_season_changed")
	_on_season_changed(game.get_current_season())
	
	var river_area = get_node_or_null("RiverArea")
	if river_area:
		remove_child(river_area)
		$ActionRange.add_child(river_area)
		$TooltipRange.add_child(river_area.duplicate())
		$TooltipRange.connect("area_entered", self, "_on_player_nearby")
		$TooltipRange.connect("area_exited", self, "_on_player_leave")
	player = Helpers.get_player()

func _process(_d):
	if player == null:
		return
	
	if !is_instance_valid(player):
		player = null
		return
	
	if enable_tooltip:
		$TooltipData.global_position = player.global_position
	
func is_pickuppable(inventory):
	return not disabled and .is_pickuppable(inventory)

func _on_season_changed(season):
	disabled = false
	var new_data = interactable_half_season
	match season:
		Enums.Season.SUMMER:
			interactable_data = interactable_summer
		Enums.Season.WINTER:
			disabled = true
	
	set_interactable_data(new_data)
	if enable_tooltip:
		$TooltipData/Tooltip/TooltipContents.interactable_data = interactable_data
		$TooltipData/Tooltip/TooltipContents.refresh()
		$TooltipRange.set_monitoring(not disabled)

