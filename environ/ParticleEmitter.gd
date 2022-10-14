extends Node2D

export (float) var despawn_after = 1.2
var particle = null

func _ready():
	if get_child_count() > 0:
		particle = get_child(0)
		remove_child(particle)

func spawn():
	var particle_dup = particle.duplicate()
	particle_dup.set_emitting(true)
	particle_dup.restart()
	add_child(particle_dup)
	yield(get_tree().create_timer(despawn_after), "timeout")
	particle_dup.queue_free()
