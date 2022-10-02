extends Node

func get_first_of_group(group_name):
	var members = get_tree().get_nodes_in_group(group_name)
	return members[0] if members.size() > 0 else null

func array_to_string(array):
	var ret = ""
	for el in array:
		ret += String(el) + ", "
	return ret
	
func writeln_console(line):
	var console = get_first_of_group("console")
	if console:
		console.add_text(String(line) + "\n")

func _process(_delta):
	var console = get_first_of_group("console")
	if console:
		console.set_text("")

func get_closest_node_to(nodes, vec2):
	if nodes.size() == 0:
		return null
	var closest = nodes[0]
	for i in range(1, nodes.size()):
		if closest.global_position.distance_to(vec2) > nodes[i].global_position.distance_to(vec2):
			closest = nodes[i]
	return closest
