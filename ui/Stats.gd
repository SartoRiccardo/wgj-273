extends VBoxContainer

onready var lives_root = $Lives/PanelContainer/MarginContainer/HBoxContainer/LifeRoot
onready var hunger_root = $Hunger/PanelContainer/MarginContainer/HBoxContainer/HungerRoot

func _ready():
	var player = Helpers.get_player()
	if player:
		player.connect("hurt", self, "_on_player_hurt")
		player.connect("hunger", self, "_on_player_hunger")
		init_stats(player)

func init_stats(player):
	var life_point = lives_root.get_child(0)
	for __ in range(player.lives-1):
		lives_root.add_child(life_point.duplicate())
	
	var hunger_point = hunger_root.get_child(0)
	for __ in range(player.prev_hunger-1):
		hunger_root.add_child(hunger_point.duplicate())

func update_lives(amount):
	_update_counter(lives_root, amount)

func update_hunger(amount):
	_update_counter(hunger_root, amount)

func _update_counter(counter_root, amount):
	for i in range(counter_root.get_child_count()):
		var point = counter_root.get_child(i)
		point.set_modulate(
			Color.white if i < amount else Color.transparent
		)

func _on_player_hurt(lives):
	update_lives(lives)

func _on_player_hunger(hunger):
	update_hunger(hunger)
