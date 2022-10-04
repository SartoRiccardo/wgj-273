tool
extends Node2D

var rng = RandomNumberGenerator.new()

export (Resource) var interactable_data
export (bool) var enable_tooltip = true

onready var tooltip = $TooltipData/Tooltip

var tooltip_base_position = Vector2.ZERO

func _ready():
	rng.randomize()
	if not enable_tooltip:
		remove_child($TooltipData)
	else:
		tooltip.reset_rect()
		tooltip_base_position = tooltip.rect_position
		tooltip.rect_scale = Vector2.ZERO
		$TooltipData/Range.connect("area_entered", self, "_on_player_nearby")
		$TooltipData/Range.connect("area_exited", self, "_on_player_leave")

func _process(_d):
	if Engine.is_editor_hint():
		var tooltip_editor = $TooltipData/Tooltip
		tooltip_editor.rect_pivot_offset = tooltip_editor.rect_size/2
		tooltip_editor.rect_position = -tooltip_editor.rect_size/2
		return
	$TooltipData/Tooltip.rect_size = Vector2.ZERO

func tooltip_popup():
	if not enable_tooltip:
		return
	
	$TooltipData/Tween.stop(tooltip)
	$TooltipData/Tween.interpolate_property(tooltip, "rect_position", tooltip.rect_position,
		tooltip_base_position + Vector2.UP*30, 0.3, Tween.TRANS_CUBIC, Tween.EASE_OUT
	)
	$TooltipData/AnimationPlayer.play("tooltip_appear")
	$TooltipData/Tween.start()

func tooltip_retract():
	if not enable_tooltip:
		return
	
	$TooltipData/Tween.stop(tooltip)
	$TooltipData/Tween.interpolate_property(tooltip, "rect_position", tooltip.rect_position,
		tooltip_base_position, 0.3, Tween.TRANS_CUBIC, Tween.EASE_IN
	)
	$TooltipData/AnimationPlayer.play_backwards("tooltip_appear")
	$TooltipData/Tween.start()

func pickup():
	var amount_picked = rng.randi_range(interactable_data.amount_min, interactable_data.amount_max)
	if interactable_data.die_on_pickup:
		queue_free()
	return amount_picked

func is_pickuppable(inventory):
	return inventory.get_amount(interactable_data.requirement) >= interactable_data.requirement_amount

func consume(inventory):
	inventory.remove(interactable_data.requirement, interactable_data.requirement_amount)

func _on_player_nearby(_a2d):
	tooltip_popup()
	
func _on_player_leave(_a2d):
	tooltip_retract()
