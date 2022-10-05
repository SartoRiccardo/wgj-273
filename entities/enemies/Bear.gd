extends "res://entities/Hazard.gd"

export (int) var speed = 75
export (Resource) var behavior

func _ready():
	behavior.connect("docile_change", self, "_on_docile_change")

# Override
func update_sight(delta):
	if !behavior.docile:
		.update_sight(delta)

# Override
func change_state(new_state):
	if new_state == Enums.HazardState.ANGERED and \
			state != Enums.HazardState.IDLE and \
			behavior.docile:
		new_state = Enums.HazardState.IDLE
	.change_state(new_state)

func _on_docile_change(docile):
	if docile:
		if state == Enums.HazardState.ANGERED:
			change_state(Enums.HazardState.IDLE)
		lose_sight_player()
		$Hurtbox.set_monitorable(false)
		$Sight.set_enabled(false)
	else:
		$Hurtbox.set_monitorable(true)

func _on_hit(item):
	if item == Enums.Item.HONEY:
		behavior.set_docile(true)
