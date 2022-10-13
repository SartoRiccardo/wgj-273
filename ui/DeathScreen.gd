extends PanelContainer

func set_time_survived(years, months):
	var survive_stats = $Control/PanelContainer/MarginContainer/VBoxContainer/SurviveTime
	if years > 0:
		survive_stats.text += "%s years" % years
	if years > 0 and months > 0:
		survive_stats.text += "and"
	if years == 0 or months > 0:
		survive_stats.text += "%s months" % months
