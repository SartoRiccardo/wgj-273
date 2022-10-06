# https://www.youtube.com/watch?v=kbDj9V2MZvw
extends CanvasLayer

var material_list = preload("res://util/material_list.tres")

func _ready():
	for mat in material_list.materials:
		var particle = Particles2D.new()
		particle.set_process_material(mat)
		particle.set_one_shot(true)
		particle.set_modulate(Color.transparent)
		particle.set_emitting(true)
		add_child(particle)

var frames = 0
func _process(_d):
	frames += 1
	if frames >= 3:
		Helpers.remove_all_children(self)
		get_parent().remove_child(self)
