extends "res://entities/interactables/Building.gd"

var in_river = false
var in_dam = false

func _ready():
	var rivers = get_tree().get_nodes_in_group("river")
	for river in rivers:
		$ActionRange.connect("area_entered", self, "_on_dam_entered")
		$ActionRange.connect("area_exited", self, "_on_dam_exited")
		river.connect("river_entered", self, "_on_river_entered")
		river.connect("river_exited", self, "_on_river_exited")
		$ActionRange.connect("area_entered", river, "_on_dam_entered")
		$ActionRange.connect("area_exited", river, "_on_dam_exited")
		in_river = in_river or river.player_is_in_river

func _on_dam_entered(_a2d):
	in_dam = true
	if in_river:
		set_glow(true)
	
func _on_dam_exited(_a2d):
	in_dam = false
	set_glow(false)
	
func _on_river_entered():
	in_river = true
	if in_dam:
		set_glow(true)

func _on_river_exited():
	in_river = false
	set_glow(false)

# Override
func _on_season_change(season):
	if season == Enums.Season.WINTER:
		decay()
	._on_season_change(season)
