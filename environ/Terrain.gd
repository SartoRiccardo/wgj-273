extends Node2D

var tileset = load("res://assets/tiles/tileset.tres")
const BARRIER_TILE = 1
var tilemap_to_fade = null
onready var season_tilemaps = {
	Enums.Season.WINTER: $Tilesets/Winter,
	Enums.Season.AUTUMN: $Tilesets/Autumn,
	Enums.Season.SUMMER: $Tilesets/Summer,
	Enums.Season.SPRING: $Tilesets/Spring,
}

func _ready():
	hide_barriers()

func hide_barriers():
	tileset.tile_set_texture(BARRIER_TILE, ImageTexture.new())

func change_season(new_season: int):
	for season in season_tilemaps:
		var terrain = season_tilemaps[season]
		if season == new_season:
			$Tilesets.move_child(terrain, $Tilesets.get_child_count()-1)
	
	$AnimationPlayer.play(
		("transition_%s" % Enums.Season.keys()[new_season]).to_lower()
	)

func is_walkable(point: Vector2):
	for area in $WalkableLand.get_children():
		if !("Land" in area.name):
			continue
		if Geometry.is_point_in_polygon(point, area.navpoly.get_outline(0)):
			return true
	return false
