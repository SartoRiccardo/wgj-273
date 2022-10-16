extends Node

signal scene_changed

func change_scene_to(scene: Node, free_previous : bool = true):
	$AnimationPlayer.play("transition_hide")
	yield($AnimationPlayer, "animation_finished")
	
	var current_scene = $Stage.get_child(0)
	$Stage.remove_child(current_scene)
	$Stage.add_child(scene)
	
	$AnimationPlayer.play("transition_show")
	yield($AnimationPlayer, "animation_finished")
	emit_signal("scene_changed")
	if free_previous:
		current_scene.queue_free()
