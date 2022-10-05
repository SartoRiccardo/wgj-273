tool
extends Node2D

var rng = RandomNumberGenerator.new()

export (Resource) var interactable_data
export (bool) var enable_tooltip = true

onready var tooltip = $TooltipData/Tooltip

func _ready():
	if Engine.is_editor_hint():
		return
	
	rng.randomize()
	if not enable_tooltip:
		remove_child($TooltipData)
	else:
		$TooltipData/Range.connect("area_entered", self, "_on_player_nearby")
		$TooltipData/Range.connect("area_exited", self, "_on_player_leave")
		
func _process(_d):
	if Engine.is_editor_hint():
		var tooltip_editor = $TooltipData/Tooltip
		tooltip_editor.rect_pivot_offset = tooltip_editor.rect_size/2
		tooltip_editor.rect_position = -tooltip_editor.rect_size/2
		return
	if enable_tooltip:
		$TooltipData/Tooltip.rect_size = Vector2.ZERO

func tooltip_popup():
	if not enable_tooltip:
		return
	tooltip.popup()

func tooltip_retract(force=false):
	if not enable_tooltip and not force:
		return
	tooltip.retract()

func pickup(inventory):
	inventory.remove(interactable_data.requirement, interactable_data.requirement_amount)
	var amount_picked = rng.randi_range(interactable_data.amount_min, interactable_data.amount_max)
	if interactable_data.die_on_pickup:
		despawn()
	return amount_picked

func despawn():
	queue_free()

func delete_tooltip():
	enable_tooltip = false
	$TooltipData/Range.queue_free()
	if Helpers.stepify_vec2($TooltipData/Tooltip.rect_scale, 0.001) != Vector2.ZERO:
		tooltip_retract(true)
		yield ($TooltipData/Tween, "tween_completed")
	remove_child($TooltipData)

func is_pickuppable(inventory):
	return inventory.get_amount(interactable_data.requirement) >= interactable_data.requirement_amount

func _on_player_nearby(_a2d):
	tooltip_popup()
	
func _on_player_leave(_a2d):
	tooltip_retract()
