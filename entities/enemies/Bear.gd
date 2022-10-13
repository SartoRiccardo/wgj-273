extends "res://entities/Hazard.gd"

export (int) var speed = 75

func _ready():
	collision_layer = 1
	properties.connect("docile_change", self, "_on_docile_change")
	if !properties.initialized:
		properties.init(Helpers.get_game_node())

# Override
func change_state(new_state):
	if properties.docile and new_state in [Enums.HazardState.ANGERED, Enums.HazardState.ATTACKING]:
		new_state = Enums.HazardState.IDLE
	.change_state(new_state)

# Override
func check_sight():
	if properties.docile:
		return
	.check_sight()

# Override
func set_tooltip_open(open_tooltip: bool):
	if open_tooltip and properties.docile:
		return
	.set_tooltip_open(open_tooltip)

func _on_docile_change(docile):
	if docile:
		if state == Enums.HazardState.ANGERED:
			change_state(Enums.HazardState.IDLE)
		lose_sight_player()
		$Hitbox.set_monitorable(false)
		$Sight.set_enabled(false)
	else:
		$Hitbox.set_monitorable(true)

func _on_hit(item):
	if item == Enums.Item.HONEY:
		properties.set_docile(true)
