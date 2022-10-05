extends Resource
class_name BuildingInfo

export (PackedScene) var building_scene
export (Enums.Item) var item
export (Array, Resource) var materials
export (bool) var on_water = false
export (float) var season_duration = 1.0
export (String, MULTILINE) var description

func is_buildable(inventory):
	for material in materials:
		if inventory.get_amount(material.item) < material.amount:
			return false
	return true

func take_materials(inventory):
	for material in materials:
		inventory.remove(material.item, material.amount)
