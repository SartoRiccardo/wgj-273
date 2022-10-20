extends PanelContainer

onready var menu_btn = $Control/PanelContainer/MarginContainer/VBoxContainer/Button
var menu_scene = load("res://ui/MainMenu.tscn")

func _ready():
	menu_btn.connect("pressed", self, "_on_menu")

func set_time_survived(years, months):
	var survive_stats = $Control/PanelContainer/MarginContainer/VBoxContainer/SurviveTime
	if years > 0:
		survive_stats.text += "%s years" % years
	if years > 0 and months > 0:
		survive_stats.text += "and"
	if years == 0 or months > 0:
		survive_stats.text += "%s months" % months

func _on_menu():
	Helpers.change_scene_to(menu_scene.instance())
