extends PanelContainer

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

func popup():
	$Tween.stop(self)
	$Tween.interpolate_property(self, "rect_position", rect_position,
		base_position + Vector2.UP*30, 0.3, Tween.TRANS_CUBIC, Tween.EASE_OUT
	)
	$Tween.start()
	$AnimationPlayer.play("tooltip_appear")

func retract(force=false):
	$Tween.stop(self)
	$Tween.interpolate_property(self, "rect_position", rect_position,
		base_position, 0.3, Tween.TRANS_CUBIC, Tween.EASE_IN
	)
	$Tween.start()
	$AnimationPlayer.play_backwards("tooltip_appear")
