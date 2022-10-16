extends Node

signal game_paused_change(paused)

var rng = RandomNumberGenerator.new()
var main_node = null

func _ready():
	rng.randomize()
	main_node = get_node_or_null("/root/Main")

func get_first_of_group(group_name):
	var members = get_tree().get_nodes_in_group(group_name)
	return members[0] if members.size() > 0 else null

func get_game_node():
	return get_first_of_group("game_root")

func get_camera():
	return get_first_of_group("camera")

func get_player():
	return get_first_of_group("playable")

func array_to_string(array):
	var ret = ""
	for el in array:
		ret += String(el) + ", "
	return ret
	
func writeln_console(line):
	var console = get_first_of_group("console")
	if console:
		if console.text != "":
			console.text += "\n"
		console.text += String(line)

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

func weighted_random(array):
	var result = rng.randf()
	var total = 0.0
	for weight in array:
		total += weight
	
	var min_weight = 0
	for i in range(array.size()):
		if result <= min_weight + array[i]/total:
			return i
		min_weight += array[i]/total
	return 0

func get_triangle_area(v1: Vector2, v2: Vector2, v3: Vector2):
	var side1 = v2-v1
	var side2 = v3-v1
	var angle = side1.angle_to(side2)
	var height = sin(angle)*side1.length()
	return height*side2.length()/2

# https://math.stackexchange.com/questions/18686/uniform-random-point-in-triangle-in-3d
# https://jsfiddle.net/jniac/fmx8bz9y/
func random_triangle_point(v1, v2, v3):
	var p = rng.randf()
	var q = rng.randf()
	if p+q > 1:
		p = 1-p
		q = 1-q
	return v1 + (v2-v1)*p + (v3-v1)*q

func draw_line(parent, p1, p2, color):
	var line = Line2D.new()
	line.add_point(p1)
	line.add_point(p2)
	line.set_default_color(color)
	parent.add_child(line)

func draw_point(parent, coords, color=Color.black):
	var point = Polygon2D.new()
	point.set_polygon(PoolVector2Array([coords + Vector2.LEFT*2,
		coords + Vector2.UP*2, coords + Vector2.RIGHT*2, coords + Vector2.DOWN*2]))
	point.set_color(color)
	parent.add_child(point)

func stepify_vec2(vec2, step):
	return Vector2(stepify(vec2.x, step), stepify(vec2.y, step))

func lerp_vec2(from, target, step):
	return Vector2(lerp(from.x, target.x, step), lerp(from.y, target.y, step))

func distance_from_polygon(point : Vector2, polygon : PoolVector2Array):
	if Geometry.is_point_in_polygon(point, polygon):
		return 0.0
	
	var distance = Geometry.get_closest_point_to_segment_2d(
		point, polygon[0], polygon[1]
	).distance_to(point)
	for i in range(1, polygon.size()):
		var segment_distance = Geometry.get_closest_point_to_segment_2d(
			point, polygon[i], polygon[(i+1)%polygon.size()]
		).distance_to(point)
		if distance > segment_distance:
			distance = segment_distance
	
	return distance

func remove_all_children(node):
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()

func pause_game(pause:bool):
	get_tree().set_pause(pause)
	emit_signal("game_paused_change", pause)

func change_scene_to(scene, free_last : bool = true):
	if main_node and main_node.has_method("change_scene_to") and \
			scene is Node:
		main_node.change_scene_to(scene, free_last)
	elif scene is PackedScene:
		get_tree().change_scene_to(scene)
