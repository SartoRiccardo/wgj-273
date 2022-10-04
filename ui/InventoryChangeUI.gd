extends HBoxContainer

export (Texture) var inv_texture
export (Vector2) var inv_atlas_size = Vector2(16, 16)
export (Array, Resource) var item_sprites

func _ready():
	rect_position.x = -rect_size.x/2 * rect_scale.x
	rect_position.y = 0
	start_fade()

func generate_from(changes):
	var items = changes.keys()
	for i in items.size():
		var item = items[i]
		if changes[item] == 0:
			continue
		
		var label = Label.new()
		label.text = "%s%s" % ["+" if sign(changes[item]) == 1 else "", changes[item]]
		add_child(label)
		
		var sprite = TextureRect.new()
		sprite.texture = get_texture_for(item)
		add_child(sprite)
		
		if i != items.size()-1:
			var separator = VSeparator.new()
			separator.add_constant_override("separation", 6)
			add_child(separator)

func get_texture_for(item):
	for offsets in item_sprites:
		if offsets.item == item:
			var offset = offsets.grid_placement * inv_atlas_size
			var texture = AtlasTexture.new()
			texture.atlas = inv_texture
			texture.region = Rect2(offset, inv_atlas_size)
			return texture
	return null

func start_fade():
	$Tween.interpolate_property(self, "rect_position", rect_position,
		rect_position + Vector2.UP*30, 1.0, Tween.TRANS_CUBIC
	)
	$Tween.start()
	$AnimationPlayer.play("default")
