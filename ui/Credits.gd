extends CanvasLayer

var MAIN_MENU_SCN = load("res://ui/MainMenu.tscn")

func _ready():
	$MarginContainer/VBoxContainer/Button.connect("pressed", self, "_on_back")

func _on_back():
	Helpers.change_scene_to(MAIN_MENU_SCN.instance())
