extends Node2D

var tilemap_to_fade = null
onready var season_tilemaps = {
	Enums.Season.WINTER: $Tilesets/Winter,
	Enums.Season.AUTUMN: $Tilesets/Autumn,
	Enums.Season.SUMMER: $Tilesets/Summer,
	Enums.Season.SPRING: $Tilesets/Spring,
}

func change_season(new_season=null):
	for season in season_tilemaps:
		var terrain = season_tilemaps[season]
		if season == new_season:
			$Tilesets.move_child(terrain, $Tilesets.get_child_count()-1)
		if terrain.has_node("River/Water"):
			var water = terrain.get_node("River/Water")
			water.set_monitorable(new_season == season)
	
	$AnimationPlayer.play(
		("transition_%s" % Enums.Season.keys()[new_season]).to_lower()
	)
	
func is_walkable(point: Vector2):
	for area in $WalkableLand.get_children():
		if Geometry.is_point_in_polygon(point, area.navpoly.get_outline(0)):
			return true
	return false
