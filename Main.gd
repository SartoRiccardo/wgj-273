extends Node

func change_scene_to(scene: Node, free_previous : bool = true):
	var current_scene = get_child(get_child_count()-1)
	remove_child(current_scene)
	if free_previous:
		current_scene.queue_free()
	add_child(scene)
