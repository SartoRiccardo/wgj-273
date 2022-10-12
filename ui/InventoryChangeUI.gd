extends HBoxContainer

export (Resource) var item_icons

func _ready():
	rect_position.x = -rect_size.x/2 * 0.75
	rect_position.y = 0
	start_fade()
	
func generate_from(changes):
	var items = changes.keys()
	for i in items.size():
		var item = items[i]
		if changes[item] == 0:
			if items.size() == 1:
				var label = Label.new()
				label.text = "Nothing!"
				add_child(label)
			continue
		
		var label = Label.new()
		label.text = "%s%s" % ["+" if sign(changes[item]) == 1 else "", changes[item]]
		add_child(label)
		
		var sprite = TextureRect.new()
		sprite.texture = item_icons.texture_for(item)
		add_child(sprite)
		
		if i != items.size()-1:
			var separator = VSeparator.new()
			separator.add_constant_override("separation", 6)
			add_child(separator)

func start_fade():
	$Tween.interpolate_property(self, "rect_position", rect_position,
		rect_position + Vector2.UP*30, 1.0, Tween.TRANS_CUBIC
	)
	$Tween.start()
	$AnimationPlayer.play("default")
	yield($AnimationPlayer, "animation_finished")
	call_deferred("queue_free")
