extends "res://entities/Interactable.gd"

signal decay

export (float) var duration_seasons = 1.0
export (float) var duration_seasons_dead = 1.0

# https://godotengine.org/qa/24585/how-to-loop-a-tween-solved
var glow_values_init = [0.0, 0.6]
var glow_values = [0.0, 0.6]

func _ready():
	var game = Helpers.get_game_node()
	$Lifespan.connect("timeout", self, "_on_lifespan_timeout")
	$LifespanDead.connect("timeout", self, "_on_lifespan_dead_timeout")
	game.connect("speed_increase", self, "_on_game_speed_increase")
	game.connect("speed_decrease", self, "_on_game_speed_decrease")
	$Lifespan.start(game.season_duration * duration_seasons)
	$Glow.connect("tween_completed", self, "_on_tween_completed")

func set_glow(glow: bool):
	if glow:
		$Glow.interpolate_property(
			material, "shader_param/override_amount",
			glow_values[0], glow_values[1], 1.0,
			Tween.TRANS_CUBIC, Tween.EASE_IN_OUT
		)
		$Glow.start()
	else:
		$Glow.remove(material, "shader_param/override_amount")
		glow_values[0] = glow_values_init[0]
		glow_values[1] = glow_values_init[1]
		material.set_shader_param("override_amount", glow_values[0])

func decay():
	$ActionRange.set_monitorable(false)
	if has_method("_decay"):
		call("_decay")
	emit_signal("decay")

func _on_lifespan_timeout():
	decay()
	var game = Helpers.get_game_node()
	$LifespanDead.start(game.season_duration * duration_seasons_dead)

func _on_lifespan_dead_timeout():
	despawn()

func _on_game_speed_increase(multiplier):
	if !$Lifespan.is_stopped():
		$Lifespan.start($Lifespan.time_left/multiplier)
	if !$LifespanDead.is_stopped():
		$LifespanDead.start($LifespanDead.time_left/multiplier)

func _on_game_speed_decrease(multiplier):
	if !$Lifespan.is_stopped():
		$Lifespan.start($Lifespan.time_left*multiplier)
	if !$LifespanDead.is_stopped():
		$LifespanDead.start($LifespanDead.time_left*multiplier)

func _on_tween_completed(_obj, _key):
	glow_values.invert()
	set_glow(true)
