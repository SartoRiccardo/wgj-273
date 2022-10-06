extends Node

onready var play_btn = $CanvasLayer/MarginContainer/VBoxContainer2/VBoxContainer/Button
const GAME_SCENE_PATH = "res://Game.tscn"

func _ready():
	play_btn.connect("pressed", self, "_on_game_start")
	$BgChange.connect("timeout", $Terrain, "change_season")

func _on_game_start():
	get_tree().change_scene(GAME_SCENE_PATH)
