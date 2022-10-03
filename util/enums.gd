extends Node

enum Season { SPRING, SUMMER, AUTUMN, WINTER }
enum Item { LEAF, ROCK, STICK, FLOWER, HONEY, FISH }
enum HazardState { IDLE, ANGERED, STUNNED, FRIENDLY }
enum Entity {
	# Hazards
	BEAR, WOLF, FOX, WASPS,
	# Collectibles
	LEAF_PILE, ROCKS, STICKS, FLOWERS, BEES
}
enum Biome { PLAINS, FOREST, RIVER, MOUNTAIN }
