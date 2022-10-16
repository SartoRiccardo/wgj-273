extends Node

func change_scene_to(scene: Node, free_previous : bool = true):
	$AnimationPlayer.play("transition_hide")
	yield($AnimationPlayer, "animation_finished")
	
	var current_scene = $Stage.get_child(0)
	$Stage.remove_child(current_scene)
	if free_previous:
		current_scene.queue_free()
	$Stage.add_child(scene)
	
	$AnimationPlayer.play("transition_show")
