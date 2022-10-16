extends CanvasLayer

var MAIN_MENU_SCN = load("res://ui/MainMenu.tscn")

func _ready():
	$MarginContainer/VBoxContainer/Button.connect("pressed", self, "_on_back")

func _unhandled_input(event):
	if event.is_action("ui_cancel") and Input.is_action_just_pressed("ui_cancel"):
		go_back()

func go_back():
	Helpers.change_scene_to(MAIN_MENU_SCN.instance())

func _on_back():
	go_back()
