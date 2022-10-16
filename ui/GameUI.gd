extends CanvasLayer

export (AtlasTexture) var pause_normal_texture
export (AtlasTexture) var pause_hover_texture

onready var pause_btn = $MarginContainer/Button
onready var pause_menu_container = $ColorRect/MarginContainer/Control/PanelContainer/VBoxContainer

var MENU_SCN = load("res://ui/MainMenu.tscn")
var SETTINGS_SCN = load("res://ui/Settings.tscn")

func _ready():
	pause_btn.connect("mouse_entered", self, "_on_pause_btn_hover")
	pause_btn.connect("mouse_exited", self, "_on_pause_btn_exited")
	pause_btn.connect("pressed", self, "_on_pause")
	pause_menu_container.get_node("Resume").connect("pressed", self, "_on_resume")
	pause_menu_container.get_node("Settings").connect("pressed", self, "_on_settings")
	pause_menu_container.get_node("Quit").connect("pressed", self, "_on_quit")

func _unhandled_input(event):
	if event.is_action("ui_cancel") and Input.is_action_just_pressed("ui_cancel"):
		if get_tree().is_paused():
			resume()
		else:
			pause()

func pause():
	Helpers.pause_game(true)
	$AnimationPlayer.play("pause_appear")

func resume():
	$AnimationPlayer.play("pause_retract")
	yield($AnimationPlayer, "animation_finished")
	Helpers.pause_game(false)

func _on_pause_btn_hover():
	pause_btn.icon = pause_hover_texture

func _on_pause_btn_exited():
	pause_btn.icon = pause_normal_texture

func _on_pause():
	pause()

func _on_resume():
	resume()

func _on_settings():
	var settings = SETTINGS_SCN.instance()
	settings.back_to = Helpers.get_game_node()
	Helpers.change_scene_to(settings, false)

func _on_quit():
	var main_node = get_node_or_null("/root/Main")
	Helpers.change_scene_to(MENU_SCN.instance())
	if main_node:
		yield(main_node, "scene_changed")
	Helpers.pause_game(false)
