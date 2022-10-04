extends MarginContainer

onready var item_sprite = $VBoxContainer/Equipped/SelectedItem/PanelContainer/ItemSprite
onready var item_count = $VBoxContainer/Equipped/SelectedItem/MarginContainer/Amount
onready var pages = $VBoxContainer/Pages

export (Array, Resource) var item_sprites
export (Texture) var bullet_focused
export (Texture) var bullet_normal

const ATLAS_SIZE = Vector2(16, 16)

var equipped = null

func _ready():
	var player = Helpers.get_player()
	if player:
		var inventory = player.get_inventory()
		init_ui(inventory)

func init_ui(inventory):
	inventory.connect("equip", self, "_on_item_equip")
	inventory.connect("amount_change", self, "_on_content_amount_change")
	equipped = inventory.equipped
	update_item(equipped, inventory.get_amount(equipped))
	
	var page_bullet = pages.get_children()[0]
	for __ in range(inventory.contents.size()-1):
		var new_bullet = page_bullet.duplicate()
		pages.add_child(new_bullet)
	update_pages(equipped)

func update_pages(equipped):
	var bullets = pages.get_children()
	for i in range(bullets.size()):
		if i == equipped:
			bullets[i].texture = bullet_focused
		else:
			bullets[i].texture = bullet_normal

func update_item(item, amount):
	var grid_placement = null
	for sprites in item_sprites:
		if sprites.item == item:
			grid_placement = sprites.grid_placement
	if grid_placement == null:
		return
	
	item_sprite.texture.region.position = grid_placement*ATLAS_SIZE
	if amount == 0:
		item_sprite.set_modulate(Color(1, 1, 1, 0.5))
	else:
		item_sprite.set_modulate(Color.white)
	item_count.set_text(str(amount))

func _on_item_equip(item, amount):
	equipped = item
	update_item(item, amount)
	update_pages(item)

func _on_content_amount_change(item, _old_amount, new_amount):
	print("EQUIPPED: %s, ITEM: %s" % [equipped, item])
	if item == equipped:
		update_item(item, new_amount)
