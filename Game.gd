extends Node

signal season_change(new_season)

var current_season = 0
var cycles = 0
var season_cycle = [Enums.Season.SPRING, Enums.Season.SUMMER, Enums.Season.AUTUMN, Enums.Season.WINTER]

func _ready():
	$SeasonTimer.connect("timeout", self, "_on_season_timeout")
	$SeasonTimer.start()

func get_current_season():
	return season_cycle[current_season]

func get_season_timer():
	return $SeasonTimer

func _on_season_timeout():
	current_season = (current_season+1) % season_cycle.size()
	if get_current_season() == Enums.Season.SPRING:
		cycles += 1
	emit_signal("season_change", get_current_season())
	$Terrain/SeasonTerrain.change_season()
