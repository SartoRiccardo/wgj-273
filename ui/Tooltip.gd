extends PanelContainer

export (Vector2) var grow_direction = Vector2.UP
export (float) var grow_amount = 30.0
export (Vector2) var anchor = Vector2.ZERO

var base_position = Vector2.ZERO

func _ready():
	reset_rect()
	base_position = rect_position
	rect_scale = Vector2.ZERO

func reset_rect(traslate=false):
	force_size_recalculate()
	var prev_rect_pivot = rect_pivot_offset
	rect_pivot_offset = rect_size/2
	if traslate:
		var movement = rect_pivot_offset-prev_rect_pivot
		rect_position += movement
	else:
		rect_position = -rect_size/2

var first_loop = true
func _process(_d):
	if first_loop:
		reset_rect()
		base_position = rect_position
		first_loop = false

func force_size_recalculate():
	set_visible(false)
	set_visible(true)

func is_open():
	return Helpers.stepify_vec2(rect_scale, 0.01) != Vector2.ZERO

func popup():
	$Tween.stop(self)
	$Tween.interpolate_property(self, "rect_position", rect_position,
		base_position + grow_direction*grow_amount, 0.3, Tween.TRANS_CUBIC,
		Tween.EASE_OUT
	)
	$Tween.start()
	$AnimationPlayer.play("tooltip_appear")

func retract(_force=false):
	$Tween.stop(self)
	$Tween.interpolate_property(self, "rect_position", rect_position,
		base_position, 0.3, Tween.TRANS_CUBIC, Tween.EASE_IN
	)
	$Tween.start()
	$AnimationPlayer.play_backwards("tooltip_appear")
