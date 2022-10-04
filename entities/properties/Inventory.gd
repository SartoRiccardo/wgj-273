extends Node

signal equip(item, amount)
signal stolen(item, amount)
signal amount_change(item, old_amount, new_amount)

var contents = {
	Enums.Item.LEAF: 2,
	Enums.Item.ROCK: 0,
	Enums.Item.STICK: 5,
	Enums.Item.FLOWER: 3,
	Enums.Item.HONEY: 0,
	Enums.Item.FISH: 99,
}
var equipped = Enums.Item.ROCK

func get_amount(item):
	if not (item in contents.keys()):
		return 0
	return contents[item]

func _change_amount(item, amount, is_theft=false):
	if item in contents.keys():
		var prev_amount = contents[item]
		contents[item] += amount
		if contents[item] < 0:
			contents[item] = 0
		
		if contents[item] != prev_amount:
			if is_theft and prev_amount > contents[item]:
				emit_signal("stolen", item, prev_amount - contents[item])
			emit_signal("amount_change", item, prev_amount, contents[item])

func add(item, amount=1):
	if amount <= 0:
		return
	_change_amount(item, amount)

func remove(item, amount=1):
	if amount <= 0:
		return
	_change_amount(item, -amount)

func steal(item, amount=1):
	return _change_amount(item, -amount, true)

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
	emit_signal("equip", equipped, contents[equipped])

func equip_next():
	equip_relative(1)

func equip_prev():
	equip_relative(-1)
