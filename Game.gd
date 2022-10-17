extends Node

signal season_change(season)
signal speed_increase(multiplier)
signal speed_decrease(multiplier)

export (int) var season_duration = 90

const SPEED_UP_MULTIPLIER = 5.0
const DEATH_SCREEN_SCN = preload("res://ui/DeathScreen.tscn")

var current_season = 0
var cycles = 0
var season_cycle = [Enums.Season.SPRING, Enums.Season.SUMMER, Enums.Season.AUTUMN, Enums.Season.WINTER]
var is_sped_up = false

func _ready():
	$SeasonTimer.connect("timeout", self, "_on_season_timeout")
	$SeasonTimer.start(season_duration)
	$Player.connect("died", self, "_on_player_die")

func get_current_season():
	return season_cycle[current_season]

func get_season_timer():
	return $SeasonTimer

func is_walkable(point):
	return $Terrain/SeasonTerrain.is_walkable(point)

func speed_up():
	if is_sped_up:
		return
	is_sped_up = true
	emit_signal("speed_increase", SPEED_UP_MULTIPLIER)
	$SeasonTimer.start($SeasonTimer.time_left/SPEED_UP_MULTIPLIER)

func slow_down():
	if not is_sped_up:
		return
	is_sped_up = false
	emit_signal("speed_decrease", SPEED_UP_MULTIPLIER)
	$SeasonTimer.start($SeasonTimer.time_left*SPEED_UP_MULTIPLIER)

func get_season_duration():
	var ret = season_duration
	if is_sped_up:
		return ret / SPEED_UP_MULTIPLIER
	return ret

func get_season_progression():
	return 1 - $SeasonTimer.time_left / get_season_duration()

func _on_season_timeout():
	current_season = (current_season+1) % season_cycle.size()
	if get_current_season() == Enums.Season.SPRING:
		cycles += 1
	emit_signal("season_change", get_current_season())
	$Terrain/SeasonTerrain.change_season(current_season)
	var current_season_duration = season_duration
	if is_sped_up:
		current_season_duration /= SPEED_UP_MULTIPLIER
	$SeasonTimer.start(current_season_duration)

func _on_player_die():
	$SeasonTimer.set_paused(true)
	yield(get_tree().create_timer(1.5), "timeout")
	var death_screen = DEATH_SCREEN_SCN.instance()
	var cur_month = current_season*3 + int(get_season_progression()*3)
	death_screen.set_time_survived(cycles, cur_month)
	$GameUI.add_child(death_screen)
