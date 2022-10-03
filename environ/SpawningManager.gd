extends Node

export (Resource) var spawns_spring
export (Resource) var spawns_summer
export (Resource) var spawns_autumn
export (Resource) var spawns_winter

var rng = RandomNumberGenerator.new()

func _ready():
	$Timer.connect("timeout", self, "_on_spawn_attempt")
	rng.randomize()

func _on_spawn_attempt():
	var season = Helpers.get_game_node().get_current_season()
	var spawn_data = spawns_spring
	match season:
		Enums.Season.SUMMER:
			spawn_data = spawns_summer
		Enums.Season.AUTUMN:
			spawn_data = spawns_autumn
		Enums.Season.WINTER:
			spawn_data = spawns_winter
	
	for entity in spawn_data.data:
		if false:  # Entity cap full
			continue
		
		for chances in entity.spawn_chances:
			var attempt = rng.randf()
			if attempt <= chances.chance:  # ATtempt successful
				var area = pick_random_biome_node(chances.biome)
				if !area:
					continue
				print(entity, " ", entity.scene, " ", entity.cap, " ", entity.spawn_chances)
				var instance = entity.scene.instance()
				instance.global_position = area.random_point()
				Helpers.get_first_of_group("collectible_root") \
					.add_child(instance)

func pick_random_biome_node(biome_type):
	var picked = null
	
	var biomes = []
	for node in get_children():
		if !(node is Polygon2D) or node.type != biome_type:
			continue
		biomes.append(node)
	
	var areas = []
	for node in biomes:
		areas.append(node.get_area())
	if areas.size() > 0:
		picked = biomes[Helpers.weighted_random(areas)]
		
	return picked
