extends Resource
class_name InteractableResource

export (Enums.Item) var item = Enums.Item.LEAF
export (int) var amount_min = 1
export (int) var amount_max = 1
export (float) var time = 1.0
export (bool) var die_on_pickup = true
export (Array, Resource) var requirements = []

