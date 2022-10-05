extends HBoxContainer

export (Resource) var item_icons

func init(stun_list):
	for stun in stun_list:
		var container = PanelContainer.new()
		var hbox = HBoxContainer.new()
		
		var sprite = TextureRect.new()
		sprite.set_texture(item_icons.texture_for(stun.trigger))
		hbox.add_child(sprite)
		
		var amount = Label.new()
		amount.set_text(str(stun.amount_needed))
		hbox.add_child(amount)
		
		container.add_child(hbox)
		add_child(container)
