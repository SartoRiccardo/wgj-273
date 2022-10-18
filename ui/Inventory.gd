extends MarginContainer

onready var item_sprite = $VBoxContainer/Equipped/SelectedItem/PanelContainer/ItemSprite
onready var item_count = $VBoxContainer/Equipped/SelectedItem/MarginContainer/Amount
onready var pages = $VBoxContainer/Pages

export (Array, Resource) var item_sprites
export (Texture) var bullet_focused
export (Texture) var bullet_normal

const ATLAS_SIZE = Vector2(16, 16)

var equipped = null
var inventory = null

func _ready():
	var player = Helpers.get_player()
	if player:
		inventory = player.get_inventory()
		init_ui(inventory)

func init_ui(starting_inv):
	starting_inv.connect("equip", self, "_on_item_equip")
	starting_inv.connect("amount_change", self, "_on_content_amount_change")
	equipped = starting_inv.equipped
	update_item(equipped, starting_inv.get_amount(equipped))
	
	var page_bullet = pages.get_children()[0]
	for __ in range(starting_inv.contents.size()-1):
		var new_bullet = page_bullet.duplicate()
		pages.add_child(new_bullet)
	update_pages(equipped)

func update_pages(equipped_item):
	var bullets = pages.get_children()
	for i in range(bullets.size()):
		if inventory.contents.keys()[i] == equipped_item:
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
	$Select.play()
	equipped = item
	update_item(item, amount)
	update_pages(item)

func _on_content_amount_change(item, _old_amount, new_amount):
	if item == equipped:
		update_item(item, new_amount)
