extends PanelContainer

func reset_rect(traslate=false):
	force_size_recalculate()
	var prev_rect_pivot = rect_pivot_offset
	rect_pivot_offset = rect_size/2
	if traslate:
		var movement = rect_pivot_offset-prev_rect_pivot
		rect_position -= movement
	else:
		rect_position = -rect_size/2

func force_size_recalculate():
	set_visible(false)
	set_visible(true)
