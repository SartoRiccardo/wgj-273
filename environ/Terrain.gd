extends Node2D

var tilemap_to_fade = null
onready var season_tilemaps = {
	Enums.Season.WINTER: $Tilesets/Winter,
	Enums.Season.AUTUMN: $Tilesets/Autumn,
	Enums.Season.SUMMER: $Tilesets/Summer,
	Enums.Season.SPRING: $Tilesets/Spring,
}

func change_season(new_season=null):
	if tilemap_to_fade:
		return
	
	var tilemaps = $Tilesets.get_children()
	if tilemaps.size() < 2 or \
			new_season and season_tilemaps[new_season] == tilemaps[tilemaps.size()-1]:
		return
	
	var tilemap_new_season = null
	if new_season:
		tilemap_new_season = season_tilemaps[new_season]
	else:
		tilemap_new_season = tilemaps[tilemaps.size()-2]
	
	$Tilesets.move_child(tilemap_new_season, tilemaps.size()-2)
	tilemap_new_season.set_visible(true)
	tilemap_new_season.set_modulate(Color(1, 1, 1, 1))
	
	tilemap_to_fade = tilemaps[tilemaps.size()-1]

func _process(delta):
	if tilemap_to_fade:
		var modulate = tilemap_to_fade.get_modulate()
		modulate.a = lerp(0, modulate.a, pow(2, -3*delta))
		tilemap_to_fade.set_modulate(modulate)
		
		if stepify(modulate.a, 0.001) == 0:
			$Tilesets.move_child(tilemap_to_fade, 0)
			tilemap_to_fade.set_visible(false)
			tilemap_to_fade = null

func is_walkable(point: Vector2):
	for area in $WalkableLand.get_children():
		if Geometry.is_point_in_polygon(point, area.navpoly.get_outline(0)):
			return true
	return false
