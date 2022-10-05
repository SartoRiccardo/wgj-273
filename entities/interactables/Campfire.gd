extends "res://entities/Interactable.gd"

export (float) var duration_seasons = 1.0
export (float) var duration_seasons_dead = 1.0

func _ready():
	var game = Helpers.get_game_node()
	$Lifespan.connect("timeout", self, "_on_lifespan_timeout")
	$LifespanDead.connect("timeout", self, "_on_lifespan_dead_timeout")
	$Lifespan.start(game.season_duration * duration_seasons)

func decay():
	$Effect.queue_free()
	$Sprite.set_modulate(Color(1, 1, 1, 0.5))
	$ActionRange.set_monitorable(false)
	delete_tooltip()

func _on_lifespan_timeout():
	decay()
	var game = Helpers.get_game_node()
	$LifespanDead.start(game.season_duration * duration_seasons_dead)

func _on_lifespan_dead_timeout():
	despawn()
