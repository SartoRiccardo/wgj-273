tool
extends Control


func _ready():
	rescale()

func _process(_delta):
	if Engine.is_editor_hint():
		rescale()

func rescale():
	if get_child_count() > 0:
		var child = get_children()[0]
		rect_min_size = child.rect_size * child.rect_scale
