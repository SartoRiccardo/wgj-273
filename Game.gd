extends Node

signal season_change(new_season)

var current_season = 0
var season_cycle = [Enums.Season.SPRING, Enums.Season.SUMMER, Enums.Season.AUTUMN, Enums.Season.WINTER]

func _ready():
	$SeasonTimer.connect("timeout", self, "_on_season_timeout")
	$SeasonTimer.start()

func _process(_d):
	Helpers.writeln_console("Time left: " + String(round($SeasonTimer.time_left)))

func get_current_season():
	return season_cycle[current_season]

func _on_season_timeout():
	current_season = (current_season+1) % season_cycle.size()
	$Terrain.change_season()
