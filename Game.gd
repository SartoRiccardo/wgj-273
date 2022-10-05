extends Node

signal season_change(new_season)

export (int) var season_duration = 30

const SPEED_UP_MULTIPLIER = 2.0

var current_season = 0
var cycles = 0
var season_cycle = [Enums.Season.SPRING, Enums.Season.SUMMER, Enums.Season.AUTUMN, Enums.Season.WINTER]
var is_sped_up = false

func _ready():
	$SeasonTimer.connect("timeout", self, "_on_season_timeout")
	$SeasonTimer.start(season_duration)

func get_current_season():
	return season_cycle[current_season]

func get_season_timer():
	return $SeasonTimer

func speed_up():
	if is_sped_up:
		return
	is_sped_up = true
	$SeasonTimer.start($SeasonTimer.time_left/SPEED_UP_MULTIPLIER)

func slow_down():
	if not is_sped_up:
		return
	is_sped_up = false
	$SeasonTimer.start($SeasonTimer.time_left/SPEED_UP_MULTIPLIER)

func _on_season_timeout():
	current_season = (current_season+1) % season_cycle.size()
	if get_current_season() == Enums.Season.SPRING:
		cycles += 1
	emit_signal("season_change", get_current_season())
	$Terrain/SeasonTerrain.change_season()
	$SeasonTimer.start(season_duration)
