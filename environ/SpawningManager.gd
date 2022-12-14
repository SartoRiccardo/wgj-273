extends Node

export (bool) var enabled = true
export (Resource) var spawns_spring
export (Resource) var spawns_summer
export (Resource) var spawns_autumn
export (Resource) var spawns_winter

var rng = RandomNumberGenerator.new()

var entity_count = {}

func _ready():
	if enabled:
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
		if entity.scene in entity_count and entity_count[entity.scene] >= entity.cap:
			continue
		
		for chances in entity.spawn_chances:
			var attempt = rng.randf()
			if attempt > chances.chance:
				continue
			
			var area = pick_random_biome_node(chances.biome)
			if !area:
				continue
			
			var spawn_point = area.random_point()
			var distance_from_player = spawn_point.distance_to(Helpers.get_player().global_position)
			if distance_from_player < entity.min_distance_from_player:
				continue
			
			if !(entity.scene in entity_count):
				entity_count[entity.scene] = 0
			entity_count[entity.scene] += 1
			
			var instance = entity.scene.instance()
			instance.connect("tree_exited", self, "_on_entity_despawn", [entity.scene])
			instance.global_position = spawn_point
			Helpers.get_first_of_group("%s_root" % entity.node_type) \
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

func _on_entity_despawn(entity):
	if entity_count[entity] >= 1:
		entity_count[entity] -= 1
