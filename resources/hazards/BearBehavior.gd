extends "res://resources/hazards/HazardResource.gd"
class_name BearBehavior

signal docile_change(status)

export (bool) var docile = false

var _seasons_passed = 0

func init(game):
	game.connect("season_change", self, "_on_season_change")

func set_docile(new_docile):
	docile = new_docile
	emit_signal("docile_change", docile)

func _on_season_change(_s):
	if docile:
		_seasons_passed += 1
		if _seasons_passed >= 2:
			_seasons_passed = 0
			set_docile(false)
	else:
		_seasons_passed = 0
