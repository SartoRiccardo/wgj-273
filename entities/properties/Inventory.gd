extends Node

var contents = {
	Enums.Item.LEAF: 0,
	Enums.Item.ROCK: 20,
	Enums.Item.STICK: 0,
	Enums.Item.FLOWER: 0,
	Enums.Item.HONEY: 20,
	Enums.Item.FISH: 0,
}

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

func _to_string():
	return "Leaf:%s;Rock:%s;Wood:%s;Flwr:%s;Hney:%s;Fish:%s" % [contents[Enums.Item.LEAF], contents[Enums.Item.ROCK], contents[Enums.Item.STICK], contents[Enums.Item.FLOWER], contents[Enums.Item.HONEY], contents[Enums.Item.FISH]]
