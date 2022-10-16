extends CanvasLayer

const GAME_SCN = preload("res://Game.tscn")
const CREDITS_SCN = preload("res://ui/Credits.tscn")
const SETTINGS_SCN = preload("res://ui/Settings.tscn")

onready var play_btn = $MarginContainer/GridContainer/VBoxContainer/Play
onready var options_btn = $MarginContainer/GridContainer/VBoxContainer/Options
onready var credits_btn = $MarginContainer/GridContainer/VBoxContainer/Credits
onready var quit_btn = $MarginContainer/GridContainer/VBoxContainer/Quit

func _ready():
	play_btn.connect("pressed", self, "_on_play")
	options_btn.connect("pressed", self, "_on_options")
	credits_btn.connect("pressed", self, "_on_credits")
	quit_btn.connect("pressed", self, "_on_quit")

func _on_play():
	get_parent().change_scene_to(GAME_SCN.instance())

func _on_options():
	var settings = SETTINGS_SCN.instance()
	settings.back_to = self
	get_parent().change_scene_to(settings, false)

func _on_credits():
	get_parent().change_scene_to(CREDITS_SCN.instance())

func _on_quit():
	get_tree().quit()
