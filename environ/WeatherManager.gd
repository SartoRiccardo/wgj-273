extends Node2D

signal weather_change(weather)

export (Enums.Weather) var starting_weather = Enums.Weather.CLEAR
export (Vector3) var box_extents = Vector3(320, 180, 1)
export (float) var weather_chance = 1/60.0
export (float) var storm_chance = 1/4.0

var rng = RandomNumberGenerator.new()
var weather = null
var clear_weather_time = true
var game = null
var cur_weather_chance = weather_chance

func _ready():
	var player = Helpers.get_player()
	if player:
		self.connect("weather_change", player, "_on_weather_change")
	game = Helpers.get_game_node()
	if game:
		game.connect("season_change", self, "_on_season_change")
		game.connect("speed_increase", self, "_on_game_speed_increase")
		game.connect("speed_decrease", self, "_on_game_speed_decrease")
	change_weather(starting_weather)
	$SummonWeather.connect("timeout", self, "_on_weather_summon_attempt")
	$WeatherDuration.connect("timeout", self, "_on_weather_timeout")
	$WeatherDuration.set_paused(true)
	rng.randomize()

func change_weather(new_weather):
	if weather == new_weather:
		return
	
	for particles in get_children():
		if particles.has_method("set_emitting"):
			particles.set_emitting(false)
	
	match new_weather:
		Enums.Weather.BLIZZARD:
			$Blizzard.set_emitting(true)
		Enums.Weather.SNOW:
			$Snow.set_emitting(true)
		Enums.Weather.RAIN:
			$Rain.set_emitting(true)
		
	weather = new_weather
	emit_signal("weather_change", weather)

func _on_season_change(season):
	match season:
		Enums.Season.WINTER:
			if weather == Enums.Weather.RAIN:
				change_weather(Enums.Weather.SNOW)
		Enums.Season.SPRING, Enums.Season.AUTUMN:
			if weather in [Enums.Weather.SNOW, Enums.Weather.BLIZZARD]:
				change_weather(Enums.Weather.RAIN)
		Enums.Season.SUMMER:
			if weather != Enums.Weather.CLEAR:
				change_weather(Enums.Weather.CLEAR)

func _on_weather_summon_attempt():
	var attempt = rng.randf()
	if attempt > cur_weather_chance or !game:
		cur_weather_chance *= 1.03
		return
	
	var season = game.get_current_season()
	if season == Enums.Season.SPRING and game.get_season_progression() > 0.5 or \
			season == Enums.Season.SUMMER:
		return
	
	match season:
		Enums.Season.WINTER:
			change_weather(
				Enums.Weather.SNOW if rng.randf() > storm_chance else Enums.Weather.BLIZZARD
			)
		Enums.Season.SPRING, Enums.Season.AUTUMN:
			change_weather(Enums.Weather.RAIN)
	$SummonWeather.set_paused(true)
	$WeatherDuration.set_paused(false)

func _on_weather_timeout():
	change_weather(Enums.Weather.CLEAR)
	$SummonWeather.set_paused(clear_weather_time)
	$WeatherDuration.set_paused(!clear_weather_time)
	clear_weather_time = !clear_weather_time
	cur_weather_chance = weather_chance

func _on_game_speed_increase(multiplier):
	$SummonWeather.start($SummonWeather.time_left/multiplier)
	$WeatherDuration.start($WeatherDuration.time_left/multiplier)
	cur_weather_chance *= multiplier

func _on_game_speed_decrease(multiplier):
	$SummonWeather.start($SummonWeather.time_left*multiplier)
	$WeatherDuration.start($WeatherDuration.time_left*multiplier)
	cur_weather_chance /= multiplier
