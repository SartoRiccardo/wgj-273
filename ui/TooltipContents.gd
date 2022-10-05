#tool
extends HBoxContainer

export (Texture) var reward_texture = null
export (Texture) var requirement_texture = null
export (Resource) var interactable_data = null

func _ready():
	set_interactable_data(reward_texture, interactable_data, requirement_texture)

func _process(_d):
	rect_size = Vector2.ZERO

func refresh():
	set_interactable_data(reward_texture, interactable_data, requirement_texture)

func set_interactable_data(texture, data, require_texture=null):
	$Reward.set_texture(texture)
	if data == null:
		return
	var text = str(data.amount_min)
	if data.amount_min != data.amount_max:
		text += "-%s" % data.amount_max
	$RewardAmount.set_text(text)
	
	var has_requirement = require_texture != null and interactable_data.requirement_amount > 0
	$Require.set_visible(has_requirement)
	$RequireAmount.set_visible(has_requirement)
	$Arrow.set_visible(has_requirement)
	if has_requirement:
		$Require.set_texture(require_texture)
		$RequireAmount.set_text(str(interactable_data.requirement_amount))
	
	force_size_recalculate()
	var parent = get_parent()
	if parent.has_method("reset_rect"):
		parent.call_deferred("reset_rect", true)

## feels wrong but works
func force_size_recalculate():
	set_visible(false)
	set_visible(true)
	
