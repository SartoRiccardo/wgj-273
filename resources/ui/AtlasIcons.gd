extends Resource
class_name AtlasIcons

export (Texture) var full_texture
export (Vector2) var atlas_size = Vector2(16, 16)
export (Array, Resource) var offsets

func texture_for(item):
	for item_data in offsets:
		if item_data.item == item:
			var offset = item_data.grid_placement * atlas_size
			var texture = AtlasTexture.new()
			texture.atlas = full_texture
			texture.region = Rect2(offset, atlas_size)
			return texture
	return null
