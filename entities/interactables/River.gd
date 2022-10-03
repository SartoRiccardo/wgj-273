extends "res://entities/Interactable.gd"

export (Resource) var interactable_summer
export (Resource) var interactable_half_season
var disabled = false

func _ready():
	var game = Helpers.get_game_node()
	game.connect("season_change", self, "_on_season_changed")
	_on_season_changed(game.get_current_season())
	
	var river_area = get_node_or_null("RiverArea")
	if river_area:
		remove_child(river_area)
		$ActionRange.add_child(river_area)

func is_pickuppable(inventory):
	return not disabled and .is_pickuppable(inventory)

func _on_season_changed(season):
	disabled = false
	interactable_data = interactable_half_season
	match season:
		Enums.Season.SUMMER:
			interactable_data = interactable_summer
		Enums.Season.WINTER:
			disabled = true

