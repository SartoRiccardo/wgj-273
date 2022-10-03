extends HBoxContainer

var months = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN",
			  "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"]
var month_days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
var game = null

func _ready():
	game = Helpers.get_game_node()

func _process(_delta):
	if game == null:
		return
	update_day(game.get_season_timer(), game.get_current_season(), game.cycles)

func update_day(timer: Timer, season, cycles):
	var starting_days = 0
	var elapsed_season_days = 0
	match season:
		Enums.Season.WINTER:
			var season_passed_percent = (1-timer.time_left/timer.wait_time)
			elapsed_season_days = int(90 * season_passed_percent)
			if season_passed_percent <= 11.0/90:  # End of year
				starting_days = 79+92+92+91
			else:
				elapsed_season_days -= 11
				cycles += 1
		Enums.Season.SPRING:
			starting_days = 79
			elapsed_season_days = int(92 * (1-timer.time_left/timer.wait_time))
		Enums.Season.SUMMER:
			starting_days = 79+92
			elapsed_season_days = int(92 * (1-timer.time_left/timer.wait_time))
		Enums.Season.AUTUMN:
			starting_days = 79+92+92
			elapsed_season_days = int(91 * (1-timer.time_left/timer.wait_time))
	
	var elapsed_days = starting_days+elapsed_season_days
	var correct_days = get_correct_days(elapsed_days)
	$Label.set_text("%s %s %s" %
		[get_month(elapsed_days), correct_days, cycles+2001]
	)

func get_correct_days(day_count):
	var corrected_count = day_count
	for month_day_count in month_days:
		if corrected_count > month_day_count:
			corrected_count -= month_day_count
		else:
			break
	return corrected_count

func get_month(day_count):
	for i in range(month_days.size()):
		var month_day_count = month_days[i]
		if day_count > month_day_count:
			day_count -= month_day_count
		else:
			return months[i]
	return months[0]
