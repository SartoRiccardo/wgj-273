extends Node

var contents = {
	Enums.Item.LEAF: 10,
	Enums.Item.ROCK: 10,
	Enums.Item.STICK: 10,
	Enums.Item.FLOWER: 10,
	Enums.Item.HONEY: 10,
	Enums.Item.FISH: 10,
}
var equipped = Enums.Item.ROCK

func get_amount(item):
	if not (item in contents.keys()):
		return 0
	return contents[item]

func add(item, amount=1):
	if item in contents.keys():
		contents[item] += amount

func remove(item, amount=1):
	if item in contents.keys():
		contents[item] -= amount
		if contents[item] < 0:
			contents[item] = 0

func steal(item, amount=1):
	return remove(item, amount)

func _to_string():
	var ret = ""
	for item in contents.keys():
		ret += "%s:%s;" % [Enums.Item.keys()[item], contents[item]]
	return ret

func equip_relative(change=1):
	var item_keys = contents.keys()
	var equip_idx = item_keys.find(equipped)
	equip_idx = (equip_idx+change) % item_keys.size()
	equipped = item_keys[equip_idx]

func equip_next():
	equip_relative(1)

func equip_prev():
	equip_relative(-1)
