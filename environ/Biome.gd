extends Polygon2D

export (Enums.Biome) var type
var rng = RandomNumberGenerator.new()

func _ready():
	rng.randomize()

func is_in_biome(point : Vector2):
	if Geometry.is_point_in_polygon(point, polygon):
		return true
	return false

func get_area():
	var triangulated = Geometry.triangulate_polygon(polygon)
	var total_area = 0
	for i in range(0, triangulated.size()/3):
		var v1 = triangulated[i*3]
		var v2 = triangulated[i*3+1]
		var v3 = triangulated[i*3+2]
		var tri_area = Helpers.get_triangle_area(
			polygon[v1], polygon[v2], polygon[v3]
		)
		total_area += tri_area
	return total_area

func random_point():
	var triangulated = Geometry.triangulate_polygon(polygon)
	var total_area = 0
	var tri_areas = []
	for i in range(0, triangulated.size()/3):
		var v1 = triangulated[i*3]
		var v2 = triangulated[i*3+1]
		var v3 = triangulated[i*3+2]
		var tri_area = Helpers.get_triangle_area(
			polygon[v1], polygon[v2], polygon[v3]
		)
		total_area += tri_area
		tri_areas.append(tri_area)
	
	var tri_idx = Helpers.weighted_random(tri_areas)
	return Helpers.random_triangle_point(
		polygon[triangulated[tri_idx*3]],
		polygon[triangulated[tri_idx*3+1]],
		polygon[triangulated[tri_idx*3+2]]
	) + position
