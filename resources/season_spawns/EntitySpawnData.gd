extends Resource
class_name EntitySpawnData

export (PackedScene) var scene
export (String, "collectible", "animal") var node_type = "collectible"
export (int) var cap = 10
export (float) var min_distance_from_player = 0.0
export (Array, Resource) var spawn_chances = []
