extends VBoxContainer

export (Resource) var item_icons
var selected = null
var player_in_water = false
var building_list = []

func init_from(init_building_list, inventory):
	building_list = init_building_list
	if building_list.size() == 0:
		return
	
	if selected == null:
		selected = 0
	for i in building_list.size():
		var building = building_list[i]
		var building_icon = TextureRect.new()
		building_icon.texture = item_icons.texture_for(building.item)
		$PanelContainer/BuildableList.add_child(building_icon)
	select(building_list[selected], selected, inventory, false)

func select(building, building_idx, inventory, play_sfx : bool = true):
	selected = building_idx
	for i in $PanelContainer/BuildableList.get_child_count():
		var build_icon = $PanelContainer/BuildableList.get_child(i)
		build_icon.self_modulate = Color(1, 1, 1, 1.0 if i == selected else 0.5)

	var material_root = $BuildingDesc/VBoxContainer/MaterialList
	Helpers.remove_all_children(material_root)
	for i in building.materials.size():
		var material = building.materials[i]
		var mat_sprite = TextureRect.new()
		mat_sprite.texture = item_icons.texture_for(material.item)
		if inventory.get_amount(material.item) < material.amount:
			mat_sprite.self_modulate = Color(1, 1, 1, 0.5)
		material_root.add_child(mat_sprite)
		
		var mat_amount = Label.new()
		mat_amount.set_text(str(material.amount))
		material_root.add_child(mat_amount)
		
		if i != building.materials.size()-1:
			var separator = VSeparator.new()
			separator.add_constant_override("separation", 6)
			material_root.add_child(separator)
	
	var desc_node = $BuildingDesc/VBoxContainer/Description
	desc_node.set_text(building.description)
	if building.season_duration == 1:
		desc_node.text += "\nLasts 1 season."
	else:
		desc_node.text += "\nLasts %s seasons." % building.season_duration
	
	var placement_node = $BuildingDesc/VBoxContainer/Placement
	placement_node.set_visible(player_in_water != building.on_water)
	placement_node.set_text("Requires %s." % ("water" if building.on_water else "land"))
	
	if play_sfx:
		$Select.play()

func set_in_water(in_water):
	if building_list.size() <= selected:
		return
	player_in_water = in_water
	var placement_node = $BuildingDesc/VBoxContainer/Placement
	placement_node.set_visible(player_in_water != building_list[selected].on_water)
